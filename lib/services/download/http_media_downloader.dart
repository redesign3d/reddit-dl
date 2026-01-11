import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../data/app_database.dart';
import '../../data/settings_repository.dart';
import 'overwrite_policy.dart';

class HttpMediaDownloader {
  HttpMediaDownloader(this._dio, this._policyEvaluator);

  final Dio _dio;
  final OverwritePolicyEvaluator _policyEvaluator;

  Future<MediaDownloadResult> download({
    required MediaAsset asset,
    required File targetFile,
    required OverwritePolicy policy,
    required void Function(double progress) onProgress,
    void Function(Headers headers)? onHeaders,
    CancelToken? cancelToken,
  }) async {
    final url = Uri.parse(asset.normalizedUrl.isNotEmpty
        ? asset.normalizedUrl
        : asset.sourceUrl);

    final decision = await _policyEvaluator.evaluate(targetFile, url, policy);
    if (!decision.shouldDownload) {
      return MediaDownloadResult.skipped(
        decision.reason.isEmpty ? 'Skipped by policy.' : decision.reason,
        targetFile.path,
      );
    }

    final parentDir = targetFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final response = await _dio.get<ResponseBody>(
      url.toString(),
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
      cancelToken: cancelToken,
    );

    final status = response.statusCode ?? 0;
    if (status == 429) {
      final retryAfter =
          response.headers.value(HttpHeaders.retryAfterHeader);
      throw DownloadRateLimitException(
        retryAfterSeconds: int.tryParse(retryAfter ?? ''),
      );
    }
    if (status >= 400) {
      return MediaDownloadResult.failed(
        'HTTP $status while downloading.',
        targetFile.path,
      );
    }

    onHeaders?.call(response.headers);

    var resolvedTarget = targetFile;
    final extension = _extensionFromHeaders(response.headers);
    if (extension != null && p.extension(resolvedTarget.path).isEmpty) {
      resolvedTarget = File('${resolvedTarget.path}$extension');
    }

    final tempPath = '${resolvedTarget.path}.part';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final body = response.data;
    if (body == null) {
      return MediaDownloadResult.failed('Empty response body.', targetFile.path);
    }

    final total = body.contentLength ?? -1;
    var received = 0;
    var lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);

    final sink = tempFile.openWrite();
    try {
      await for (final chunk in body.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final now = DateTime.now();
          if (now.difference(lastUpdate).inMilliseconds > 250) {
            onProgress(received / total);
            lastUpdate = now;
          }
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    if (total > 0) {
      onProgress(1);
    }

    if (await resolvedTarget.exists()) {
      await resolvedTarget.delete();
    }

    await tempFile.rename(resolvedTarget.path);

    return MediaDownloadResult.completed(resolvedTarget.path);
  }

  String? _extensionFromHeaders(Headers headers) {
    final contentType = headers.value(HttpHeaders.contentTypeHeader);
    if (contentType == null) {
      return null;
    }
    if (contentType.contains('image/jpeg')) {
      return '.jpg';
    }
    if (contentType.contains('image/png')) {
      return '.png';
    }
    if (contentType.contains('image/gif')) {
      return '.gif';
    }
    if (contentType.contains('video/mp4')) {
      return '.mp4';
    }
    if (contentType.contains('video/webm')) {
      return '.webm';
    }
    return null;
  }
}

class MediaDownloadResult {
  const MediaDownloadResult._({
    required this.status,
    required this.outputPath,
    this.message,
  });

  final MediaDownloadStatus status;
  final String outputPath;
  final String? message;

  bool get isCompleted => status == MediaDownloadStatus.completed;
  bool get isSkipped => status == MediaDownloadStatus.skipped;
  bool get isFailed => status == MediaDownloadStatus.failed;

  factory MediaDownloadResult.completed(String path) {
    return MediaDownloadResult._(
      status: MediaDownloadStatus.completed,
      outputPath: path,
    );
  }

  factory MediaDownloadResult.skipped(String reason, String path) {
    return MediaDownloadResult._(
      status: MediaDownloadStatus.skipped,
      outputPath: path,
      message: reason,
    );
  }

  factory MediaDownloadResult.failed(String reason, String path) {
    return MediaDownloadResult._(
      status: MediaDownloadStatus.failed,
      outputPath: path,
      message: reason,
    );
  }
}

enum MediaDownloadStatus { completed, skipped, failed }
