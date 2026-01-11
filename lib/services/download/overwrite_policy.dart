import 'dart:io';

import 'package:dio/dio.dart';

import '../../data/settings_repository.dart';

class OverwritePolicyEvaluator {
  OverwritePolicyEvaluator(this._dio);

  final Dio _dio;

  Future<OverwriteDecision> evaluate(
    File target,
    Uri url,
    OverwritePolicy policy,
  ) async {
    final exists = await target.exists();
    if (!exists) {
      return const OverwriteDecision.download();
    }

    if (policy == OverwritePolicy.skipIfExists) {
      return const OverwriteDecision.skip('File exists.');
    }

    final response = await _dio.head<String>(
      url.toString(),
      options: Options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status == 429) {
      final retryAfter = _retryAfter(response.headers);
      throw DownloadRateLimitException(retryAfterSeconds: retryAfter);
    }
    if (status >= 400) {
      return const OverwriteDecision.skip('Unable to determine freshness.');
    }

    final fileStat = await target.stat();
    final remoteModified = _parseLastModified(response.headers);
    if (remoteModified != null) {
      if (remoteModified.isAfter(fileStat.modified)) {
        return const OverwriteDecision.download();
      }
      return const OverwriteDecision.skip('Remote file not newer.');
    }

    final remoteLength = _parseContentLength(response.headers);
    if (remoteLength != null) {
      if (remoteLength != fileStat.size) {
        return const OverwriteDecision.download();
      }
      return const OverwriteDecision.skip('Remote size matches local.');
    }

    return const OverwriteDecision.skip('Unable to determine freshness.');
  }

  int? _retryAfter(Headers headers) {
    final value = headers.value(HttpHeaders.retryAfterHeader);
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }

  DateTime? _parseLastModified(Headers headers) {
    final value = headers.value(HttpHeaders.lastModifiedHeader);
    if (value == null) {
      return null;
    }
    try {
      return HttpDate.parse(value);
    } catch (_) {
      return null;
    }
  }

  int? _parseContentLength(Headers headers) {
    final value = headers.value(HttpHeaders.contentLengthHeader);
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }
}

class OverwriteDecision {
  const OverwriteDecision._({
    required this.shouldDownload,
    required this.reason,
  });

  const OverwriteDecision.download()
      : this._(shouldDownload: true, reason: '');

  const OverwriteDecision.skip(String reason)
      : this._(shouldDownload: false, reason: reason);

  final bool shouldDownload;
  final String reason;
}

class DownloadRateLimitException implements Exception {
  DownloadRateLimitException({this.retryAfterSeconds});

  final int? retryAfterSeconds;

  @override
  String toString() =>
      'DownloadRateLimitException(retryAfterSeconds: $retryAfterSeconds)';
}
