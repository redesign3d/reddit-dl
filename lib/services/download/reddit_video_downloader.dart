import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../data/app_database.dart';
import '../../data/settings_repository.dart';
import '../ffmpeg_runtime_manager.dart';
import 'ffmpeg_executor.dart';
import 'http_media_downloader.dart';
import 'overwrite_policy.dart';

typedef DownloadLog = Future<void> Function(String level, String message);

class RedditVideoDownloader {
  RedditVideoDownloader({
    required Dio dio,
    required OverwritePolicyEvaluator policyEvaluator,
    required HttpMediaDownloader httpDownloader,
    required FfmpegRuntimeManager ffmpegRuntime,
    required FfmpegExecutor ffmpegExecutor,
  })  : _dio = dio,
        _policyEvaluator = policyEvaluator,
        _httpDownloader = httpDownloader,
        _ffmpegRuntime = ffmpegRuntime,
        _ffmpegExecutor = ffmpegExecutor;

  final Dio _dio;
  final OverwritePolicyEvaluator _policyEvaluator;
  final HttpMediaDownloader _httpDownloader;
  final FfmpegRuntimeManager _ffmpegRuntime;
  final FfmpegExecutor _ffmpegExecutor;

  Future<MediaDownloadResult> download({
    required MediaAsset asset,
    required File targetFile,
    required OverwritePolicy policy,
    required void Function(double progress) onProgress,
    void Function(Headers headers)? onHeaders,
    CancelToken? cancelToken,
    DownloadLog? log,
  }) async {
    final metadata = _decodeMetadata(asset.metadataJson);
    final fallbackUrl = _fallbackUrl(asset, metadata);
    if (fallbackUrl == null) {
      return MediaDownloadResult.failed('Missing video URL.', targetFile.path);
    }

    final dashUrl = _stringValue(metadata['dash_url']);
    final resolvedTarget = _ensureMp4Extension(targetFile);
    try {
      if (dashUrl != null && dashUrl.isNotEmpty) {
        final decision = await _policyEvaluator.evaluate(
          resolvedTarget,
          Uri.parse(dashUrl),
          policy,
        );
        if (!decision.shouldDownload) {
          return MediaDownloadResult.skipped(
            decision.reason.isEmpty ? 'Skipped by policy.' : decision.reason,
            resolvedTarget.path,
          );
        }
        return await _downloadFromDash(
          dashUrl: dashUrl,
          targetFile: resolvedTarget,
          cancelToken: cancelToken,
          onProgress: onProgress,
          log: log,
        );
      }

      final audioUrl = await _resolveAudioUrl(
        fallbackUrl,
        cancelToken: cancelToken,
      );
      if (audioUrl != null) {
        final decision = await _policyEvaluator.evaluate(
          resolvedTarget,
          Uri.parse(fallbackUrl),
          policy,
        );
        if (!decision.shouldDownload) {
          return MediaDownloadResult.skipped(
            decision.reason.isEmpty ? 'Skipped by policy.' : decision.reason,
            resolvedTarget.path,
          );
        }
        return await _downloadAndMerge(
          videoUrl: Uri.parse(fallbackUrl),
          audioUrl: audioUrl,
          targetFile: resolvedTarget,
          cancelToken: cancelToken,
          onHeaders: onHeaders,
          onProgress: onProgress,
          log: log,
        );
      }

      return _httpDownloader.download(
        asset: asset,
        targetFile: resolvedTarget,
        policy: policy,
        cancelToken: cancelToken,
        onHeaders: onHeaders,
        onProgress: onProgress,
      );
    } on DownloadClientException catch (error) {
      return MediaDownloadResult.failed(error.message, resolvedTarget.path);
    }
  }

  Future<MediaDownloadResult> _downloadFromDash({
    required String dashUrl,
    required File targetFile,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
    DownloadLog? log,
  }) async {
    await _ensureParent(targetFile);

    final ffmpegPath = await _ensureFfmpeg(log);
    final tempPath = '${targetFile.path}.part';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    await log?.call('info', 'Merging DASH streams with ffmpeg.');
    final args = buildDashArgs(dashUrl: dashUrl, outputPath: tempFile.path);
    final result = await _ffmpegExecutor.run(
      ffmpegPath: ffmpegPath,
      args: args,
      cancelToken: cancelToken,
      onStdout: (line) => log?.call('info', line),
      onStderr: (line) => log?.call('warn', line),
    );
    if (!result.isSuccess) {
      return MediaDownloadResult.failed(
        'ffmpeg failed with exit code ${result.exitCode}.',
        targetFile.path,
      );
    }

    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetFile.path);
    onProgress(1);
    return MediaDownloadResult.completed(targetFile.path);
  }

  Future<MediaDownloadResult> _downloadAndMerge({
    required Uri videoUrl,
    required Uri audioUrl,
    required File targetFile,
    required void Function(double progress) onProgress,
    void Function(Headers headers)? onHeaders,
    CancelToken? cancelToken,
    DownloadLog? log,
  }) async {
    await _ensureParent(targetFile);

    final baseName = p.basenameWithoutExtension(targetFile.path);
    final videoFile = File(
      p.join(targetFile.parent.path, '${baseName}_video.mp4'),
    );
    final audioFile = File(
      p.join(targetFile.parent.path, '${baseName}_audio.m4a'),
    );

    await log?.call('info', 'Downloading video stream.');
    await _downloadStream(
      url: videoUrl,
      targetFile: videoFile,
      cancelToken: cancelToken,
      onHeaders: onHeaders,
      onProgress: (progress) => onProgress(progress * 0.5),
    );

    await log?.call('info', 'Downloading audio stream.');
    await _downloadStream(
      url: audioUrl,
      targetFile: audioFile,
      cancelToken: cancelToken,
      onProgress: (progress) => onProgress(0.5 + progress * 0.5),
    );

    final ffmpegPath = await _ensureFfmpeg(log);
    final tempPath = '${targetFile.path}.part';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    await log?.call('info', 'Merging video and audio.');
    final args = buildMergeArgs(
      videoPath: videoFile.path,
      audioPath: audioFile.path,
      outputPath: tempFile.path,
    );
    final result = await _ffmpegExecutor.run(
      ffmpegPath: ffmpegPath,
      args: args,
      cancelToken: cancelToken,
      onStdout: (line) => log?.call('info', line),
      onStderr: (line) => log?.call('warn', line),
    );
    if (!result.isSuccess) {
      return MediaDownloadResult.failed(
        'ffmpeg failed with exit code ${result.exitCode}.',
        targetFile.path,
      );
    }

    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetFile.path);
    onProgress(1);

    await _cleanupTemp(videoFile);
    await _cleanupTemp(audioFile);
    return MediaDownloadResult.completed(targetFile.path);
  }

  Future<void> _downloadStream({
    required Uri url,
    required File targetFile,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
    void Function(Headers headers)? onHeaders,
  }) async {
    await _ensureParent(targetFile);

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
        retryAfterSeconds:
            retryAfter == null ? null : int.tryParse(retryAfter),
      );
    }
    if (status >= 500) {
      throw DownloadHttpException(statusCode: status);
    }
    if (status >= 400) {
      throw DownloadClientException('HTTP $status while downloading.');
    }

    onHeaders?.call(response.headers);

    final tempPath = '${targetFile.path}.part';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    final body = response.data;
    if (body == null) {
      throw DownloadClientException('Empty response body.');
    }

    final total = body.contentLength;
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

    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await tempFile.rename(targetFile.path);
  }

  Future<String> _ensureFfmpeg(DownloadLog? log) async {
    final status = await _ffmpegRuntime.status();
    if (status.isInstalled && status.ffmpegPath != null) {
      return status.ffmpegPath!;
    }
    await log?.call('info', 'ffmpeg runtime missing. Installing.');
    final installed = await _ffmpegRuntime.install();
    if (!installed.isInstalled || installed.ffmpegPath == null) {
      throw DownloadClientException('Failed to install ffmpeg runtime.');
    }
    await log?.call('info', 'ffmpeg runtime installed.');
    return installed.ffmpegPath!;
  }

  Map<String, dynamic> _decodeMetadata(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return const {};
    }
    return const {};
  }

  String? _fallbackUrl(MediaAsset asset, Map<String, dynamic> metadata) {
    final fallback = _stringValue(metadata['fallback_url']);
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }
    if (asset.normalizedUrl.isNotEmpty) {
      return asset.normalizedUrl;
    }
    if (asset.sourceUrl.isNotEmpty) {
      return asset.sourceUrl;
    }
    return null;
  }

  String? _stringValue(dynamic value) {
    if (value is String) {
      return value;
    }
    return null;
  }

  File _ensureMp4Extension(File targetFile) {
    final extension = p.extension(targetFile.path);
    if (extension.isEmpty) {
      return File('${targetFile.path}.mp4');
    }
    return targetFile;
  }

  Future<void> _ensureParent(File file) async {
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }
  }

  Future<void> _cleanupTemp(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
    final part = File('${file.path}.part');
    if (await part.exists()) {
      await part.delete();
    }
  }

  Future<Uri?> _resolveAudioUrl(
    String fallbackUrl, {
    CancelToken? cancelToken,
  }) async {
    final candidates = _audioCandidates(fallbackUrl);
    if (candidates.isEmpty) {
      return null;
    }

    for (final candidate in candidates) {
      if (await _probeUrl(candidate, cancelToken: cancelToken)) {
        return candidate;
      }
    }
    return null;
  }

  List<Uri> _audioCandidates(String fallbackUrl) {
    final uri = Uri.tryParse(fallbackUrl);
    if (uri == null) {
      return const [];
    }
    final match = RegExp(r'(.*)/DASH_[^/]+\\.mp4').firstMatch(uri.path);
    if (match == null) {
      return const [];
    }
    final base = match.group(1)!;
    return [
      uri.replace(path: '$base/DASH_audio.mp4', query: ''),
      uri.replace(path: '$base/DASH_AUDIO_128.mp4', query: ''),
    ];
  }

  Future<bool> _probeUrl(
    Uri url, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.head<String>(
      url.toString(),
      options: Options(
        validateStatus: (status) => status != null && status < 500,
      ),
      cancelToken: cancelToken,
    );
    final status = response.statusCode ?? 0;
    if (status == 429) {
      final retryAfter =
          response.headers.value(HttpHeaders.retryAfterHeader);
      throw DownloadRateLimitException(
        retryAfterSeconds:
            retryAfter == null ? null : int.tryParse(retryAfter),
      );
    }
    if (status >= 400) {
      return false;
    }
    return true;
  }

  List<String> buildDashArgs({
    required String dashUrl,
    required String outputPath,
  }) {
    return [
      '-y',
      '-i',
      dashUrl,
      '-c',
      'copy',
      outputPath,
    ];
  }

  List<String> buildMergeArgs({
    required String videoPath,
    required String audioPath,
    required String outputPath,
  }) {
    return [
      '-y',
      '-i',
      videoPath,
      '-i',
      audioPath,
      '-c',
      'copy',
      outputPath,
    ];
  }
}

class DownloadClientException implements Exception {
  DownloadClientException(this.message);

  final String message;

  @override
  String toString() => 'DownloadClientException: $message';
}
