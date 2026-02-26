import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../data/app_database.dart';
import '../../data/download_resume_state.dart';
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
    DownloadResumeStateStore? resumeStateStore,
    int? relatedJobId,
    int? relatedMediaAssetId,
    void Function(String level, String message)? log,
    CancelToken? cancelToken,
  }) async {
    final url = Uri.parse(
      asset.normalizedUrl.isNotEmpty ? asset.normalizedUrl : asset.sourceUrl,
    );

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

    final persistedState = await _loadResumeState(
      resumeStateStore: resumeStateStore,
      relatedJobId: relatedJobId,
      relatedMediaAssetId: relatedMediaAssetId,
    );
    final metadata = await _probeMetadata(url, cancelToken);

    final targetPathFromState = persistedState?.expectedFinalPath.trim() ?? '';
    var resolvedTarget = File(
      targetPathFromState.isNotEmpty ? targetPathFromState : targetFile.path,
    );
    final extension = _extensionFromContentType(metadata?.contentType);
    if (extension != null && p.extension(resolvedTarget.path).isEmpty) {
      resolvedTarget = File('${resolvedTarget.path}$extension');
    }

    final persistedTempPath = persistedState?.localTempPath.trim() ?? '';
    final tempPath = persistedTempPath.isNotEmpty
        ? persistedTempPath
        : '${resolvedTarget.path}.part';
    final tempFile = File(tempPath);

    var downloadedBytes = 0;
    if (await tempFile.exists()) {
      downloadedBytes = await tempFile.length();
    }

    var canResume = downloadedBytes > 0;
    if (canResume && metadata != null && !metadata.supportsRangeRequests) {
      final supportsRangeByProbe = await _probeRangeSupport(url, cancelToken);
      if (supportsRangeByProbe) {
        metadata.supportsRangeRequests = true;
      }
    }
    if (canResume && metadata != null && !metadata.supportsRangeRequests) {
      canResume = false;
      log?.call(
        'info',
        'Server does not support Range; restarting ${resolvedTarget.path}.',
      );
    }
    if (canResume &&
        !_validatorsMatch(persistedState: persistedState, metadata: metadata)) {
      canResume = false;
      log?.call(
        'info',
        'Validator mismatch; restarting ${resolvedTarget.path}.',
      );
    }
    if (!canResume && downloadedBytes > 0) {
      await tempFile.delete();
      downloadedBytes = 0;
    }

    var etag = metadata?.etag ?? persistedState?.etag;
    var lastModified = metadata?.lastModified ?? persistedState?.lastModified;
    var totalBytes = metadata?.totalBytes ?? persistedState?.totalBytes;

    await _saveResumeState(
      resumeStateStore: resumeStateStore,
      relatedJobId: relatedJobId,
      relatedMediaAssetId: relatedMediaAssetId,
      url: url.toString(),
      localTempPath: tempFile.path,
      expectedFinalPath: resolvedTarget.path,
      etag: etag,
      lastModified: lastModified,
      totalBytes: totalBytes,
      downloadedBytes: downloadedBytes,
    );

    var response = await _requestStream(
      url: url,
      rangeStart: downloadedBytes > 0 ? downloadedBytes : null,
      cancelToken: cancelToken,
    );
    var status = response.statusCode ?? 0;
    var writingOffset = downloadedBytes > 0 ? downloadedBytes : 0;

    if (writingOffset > 0 && status == HttpStatus.ok) {
      log?.call(
        'info',
        'Server ignored Range response; restarting ${resolvedTarget.path}.',
      );
      await tempFile.writeAsBytes(<int>[]);
      writingOffset = 0;
      downloadedBytes = 0;
    } else if (writingOffset > 0 &&
        status == HttpStatus.requestedRangeNotSatisfiable) {
      log?.call(
        'info',
        'Range no longer satisfiable; restarting ${resolvedTarget.path}.',
      );
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      writingOffset = 0;
      downloadedBytes = 0;
      response = await _requestStream(url: url, cancelToken: cancelToken);
      status = response.statusCode ?? 0;
    }

    if (status == 429) {
      final retryAfter = response.headers.value(HttpHeaders.retryAfterHeader);
      throw DownloadRateLimitException(
        retryAfterSeconds: retryAfter == null ? null : int.tryParse(retryAfter),
      );
    }
    if (status >= 500) {
      throw DownloadHttpException(statusCode: status);
    }
    if (status >= 400) {
      return MediaDownloadResult.failed(
        'HTTP $status while downloading.',
        targetFile.path,
      );
    }

    onHeaders?.call(response.headers);

    final body = response.data;
    if (body == null) {
      return MediaDownloadResult.failed(
        'Empty response body.',
        targetFile.path,
      );
    }

    final contentLength = body.contentLength;
    final responseTotal =
        _totalBytesFromContentRange(
          response.headers.value(HttpHeaders.contentRangeHeader),
        ) ??
        (contentLength > 0 ? contentLength + writingOffset : null);
    totalBytes = responseTotal ?? totalBytes;
    etag = response.headers.value(HttpHeaders.etagHeader) ?? etag;
    lastModified =
        response.headers.value(HttpHeaders.lastModifiedHeader) ?? lastModified;

    var received = writingOffset;
    var lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);
    var lastPersistAt = DateTime.fromMillisecondsSinceEpoch(0);

    final sink = tempFile.openWrite(
      mode: writingOffset > 0 ? FileMode.append : FileMode.write,
    );
    try {
      await for (final chunk in body.stream) {
        sink.add(chunk);
        received += chunk.length;
        final now = DateTime.now();
        final knownTotalBytes = totalBytes;
        if (knownTotalBytes != null && knownTotalBytes > 0) {
          if (now.difference(lastProgressAt).inMilliseconds > 250) {
            onProgress((received / knownTotalBytes).clamp(0, 1));
            lastProgressAt = now;
          }
        }
        if (now.difference(lastPersistAt).inMilliseconds > 250) {
          await _saveResumeState(
            resumeStateStore: resumeStateStore,
            relatedJobId: relatedJobId,
            relatedMediaAssetId: relatedMediaAssetId,
            url: url.toString(),
            localTempPath: tempFile.path,
            expectedFinalPath: resolvedTarget.path,
            etag: etag,
            lastModified: lastModified,
            totalBytes: totalBytes,
            downloadedBytes: received,
          );
          lastPersistAt = now;
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
      await _saveResumeState(
        resumeStateStore: resumeStateStore,
        relatedJobId: relatedJobId,
        relatedMediaAssetId: relatedMediaAssetId,
        url: url.toString(),
        localTempPath: tempFile.path,
        expectedFinalPath: resolvedTarget.path,
        etag: etag,
        lastModified: lastModified,
        totalBytes: totalBytes,
        downloadedBytes: received,
      );
    }

    final knownTotalBytes = totalBytes;
    if (knownTotalBytes != null && knownTotalBytes > 0) {
      onProgress(1);
    }

    if (await resolvedTarget.exists()) {
      await resolvedTarget.delete();
    }

    await tempFile.rename(resolvedTarget.path);
    await _clearResumeState(
      resumeStateStore: resumeStateStore,
      relatedJobId: relatedJobId,
      relatedMediaAssetId: relatedMediaAssetId,
    );

    return MediaDownloadResult.completed(resolvedTarget.path);
  }

  Future<Response<ResponseBody>> _requestStream({
    required Uri url,
    int? rangeStart,
    CancelToken? cancelToken,
  }) {
    final headers = <String, String>{};
    if (rangeStart != null && rangeStart > 0) {
      headers[HttpHeaders.rangeHeader] = 'bytes=$rangeStart-';
    }
    return _dio.get<ResponseBody>(
      url.toString(),
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        headers: headers.isEmpty ? null : headers,
        validateStatus: (status) => status != null && status < 500,
      ),
      cancelToken: cancelToken,
    );
  }

  Future<_RemoteMetadata?> _probeMetadata(
    Uri url,
    CancelToken? cancelToken,
  ) async {
    try {
      final response = await _dio.head<void>(
        url.toString(),
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
        cancelToken: cancelToken,
      );
      final status = response.statusCode ?? 0;
      if (status == 429) {
        final retryAfter = response.headers.value(HttpHeaders.retryAfterHeader);
        throw DownloadRateLimitException(
          retryAfterSeconds: retryAfter == null
              ? null
              : int.tryParse(retryAfter),
        );
      }
      if (status >= 500) {
        throw DownloadHttpException(statusCode: status);
      }
      if (status >= 400) {
        return null;
      }
      final acceptsRanges =
          response.headers.value(HttpHeaders.acceptRangesHeader) == 'bytes';
      final totalBytesHeader = response.headers.value(
        HttpHeaders.contentLengthHeader,
      );
      return _RemoteMetadata(
        etag: response.headers.value(HttpHeaders.etagHeader),
        lastModified: response.headers.value(HttpHeaders.lastModifiedHeader),
        totalBytes: totalBytesHeader == null
            ? null
            : int.tryParse(totalBytesHeader),
        supportsRangeRequests: acceptsRanges,
        contentType: response.headers.value(HttpHeaders.contentTypeHeader),
      );
    } on DioException {
      return null;
    }
  }

  Future<bool> _probeRangeSupport(Uri url, CancelToken? cancelToken) async {
    try {
      final response = await _dio.get<ResponseBody>(
        url.toString(),
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          headers: const {HttpHeaders.rangeHeader: 'bytes=0-0'},
          validateStatus: (status) => status != null && status < 500,
        ),
        cancelToken: cancelToken,
      );
      final status = response.statusCode ?? 0;
      if (status == HttpStatus.partialContent) {
        return true;
      }
      return response.headers.value(HttpHeaders.acceptRangesHeader) == 'bytes';
    } on DioException {
      return false;
    }
  }

  bool _validatorsMatch({
    required DownloadResumeState? persistedState,
    required _RemoteMetadata? metadata,
  }) {
    if (persistedState == null || metadata == null) {
      return true;
    }
    final storedEtag = persistedState.etag;
    final remoteEtag = metadata.etag;
    if (storedEtag != null && storedEtag.isNotEmpty) {
      if (remoteEtag == null || remoteEtag.isEmpty) {
        return false;
      }
      if (storedEtag != remoteEtag) {
        return false;
      }
    }
    final storedLastModified = persistedState.lastModified;
    final remoteLastModified = metadata.lastModified;
    if (storedLastModified != null && storedLastModified.isNotEmpty) {
      if (remoteLastModified == null || remoteLastModified.isEmpty) {
        return false;
      }
      if (storedLastModified != remoteLastModified) {
        return false;
      }
    }
    return true;
  }

  int? _totalBytesFromContentRange(String? contentRange) {
    if (contentRange == null || contentRange.isEmpty) {
      return null;
    }
    final slash = contentRange.indexOf('/');
    if (slash == -1 || slash + 1 >= contentRange.length) {
      return null;
    }
    final total = contentRange.substring(slash + 1).trim();
    if (total == '*') {
      return null;
    }
    return int.tryParse(total);
  }

  Future<DownloadResumeState?> _loadResumeState({
    required DownloadResumeStateStore? resumeStateStore,
    required int? relatedJobId,
    required int? relatedMediaAssetId,
  }) {
    if (resumeStateStore == null ||
        relatedJobId == null ||
        relatedMediaAssetId == null) {
      return Future.value(null);
    }
    return resumeStateStore.fetchResumeState(
      jobId: relatedJobId,
      mediaAssetId: relatedMediaAssetId,
    );
  }

  Future<void> _saveResumeState({
    required DownloadResumeStateStore? resumeStateStore,
    required int? relatedJobId,
    required int? relatedMediaAssetId,
    required String url,
    required String localTempPath,
    required String expectedFinalPath,
    required String? etag,
    required String? lastModified,
    required int? totalBytes,
    required int downloadedBytes,
  }) async {
    if (resumeStateStore == null ||
        relatedJobId == null ||
        relatedMediaAssetId == null) {
      return;
    }
    await resumeStateStore.upsertResumeState(
      DownloadResumeState(
        jobId: relatedJobId,
        mediaAssetId: relatedMediaAssetId,
        url: url,
        localTempPath: localTempPath,
        expectedFinalPath: expectedFinalPath,
        etag: etag,
        lastModified: lastModified,
        totalBytes: totalBytes,
        downloadedBytes: downloadedBytes,
      ),
    );
  }

  Future<void> _clearResumeState({
    required DownloadResumeStateStore? resumeStateStore,
    required int? relatedJobId,
    required int? relatedMediaAssetId,
  }) async {
    if (resumeStateStore == null ||
        relatedJobId == null ||
        relatedMediaAssetId == null) {
      return;
    }
    await resumeStateStore.clearResumeState(
      jobId: relatedJobId,
      mediaAssetId: relatedMediaAssetId,
    );
  }

  String? _extensionFromContentType(String? contentType) {
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

class _RemoteMetadata {
  _RemoteMetadata({
    required this.etag,
    required this.lastModified,
    required this.totalBytes,
    required this.supportsRangeRequests,
    required this.contentType,
  });

  final String? etag;
  final String? lastModified;
  final int? totalBytes;
  bool supportsRangeRequests;
  final String? contentType;
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

class DownloadHttpException implements Exception {
  DownloadHttpException({required this.statusCode});

  final int statusCode;

  @override
  String toString() => 'DownloadHttpException(statusCode: $statusCode)';
}
