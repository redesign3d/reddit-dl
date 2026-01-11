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
    if (dashUrl == null || dashUrl.isEmpty) {
      return _httpDownloader.download(
        asset: asset,
        targetFile: targetFile,
        policy: policy,
        cancelToken: cancelToken,
        onHeaders: onHeaders,
        onProgress: onProgress,
      );
    }

    final resolvedTarget = _ensureMp4Extension(targetFile);
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

    try {
      return await _downloadFromDash(
        dashUrl: dashUrl,
        targetFile: resolvedTarget,
        cancelToken: cancelToken,
        onProgress: onProgress,
        log: log,
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
}

class DownloadClientException implements Exception {
  DownloadClientException(this.message);

  final String message;

  @override
  String toString() => 'DownloadClientException: $message';
}
