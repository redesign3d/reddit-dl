import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../data/app_database.dart';
import '../../data/settings_repository.dart';
import '../tools/external_tool_runner.dart';
import '../tools/tool_detector.dart';
import 'http_media_downloader.dart';

typedef DownloadLog = Future<void> Function(String level, String message);

class ExternalMediaDownloader {
  ExternalMediaDownloader({
    required ToolDetector toolDetector,
    required ExternalToolRunner toolRunner,
  }) : _toolDetector = toolDetector,
       _toolRunner = toolRunner;

  final ToolDetector _toolDetector;
  final ExternalToolRunner _toolRunner;

  Future<MediaDownloadResult> download({
    required MediaAsset asset,
    required File targetFile,
    required AppSettings settings,
    required OverwritePolicy policy,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
    DownloadLog? log,
    void Function(String phase)? onPhase,
  }) async {
    final outputDir = targetFile.parent;
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    if (await _shouldSkip(outputDir, policy, log)) {
      return MediaDownloadResult.skipped(
        policy == OverwritePolicy.skipIfExists
            ? 'Output exists.'
            : 'Unable to determine newer output.',
        outputDir.path,
      );
    }

    final toolChoice = _selectTool(asset);
    if (toolChoice == null) {
      return MediaDownloadResult.failed(
        'No external tool matched this URL.',
        outputDir.path,
      );
    }

    final toolInfo = await _toolDetector.detect(
      toolChoice.command,
      overridePath:
          toolChoice.command == 'gallery-dl'
              ? settings.galleryDlPathOverride
              : settings.ytDlpPathOverride,
    );
    if (!toolInfo.isAvailable) {
      return MediaDownloadResult.failed(
        '${toolChoice.command} not available. Configure in Settings.',
        outputDir.path,
      );
    }

    final args = _buildArgs(toolChoice, asset, targetFile, outputDir);
    final before = await _snapshotFiles(outputDir);
    await log?.call(
      'info',
      'Running ${toolChoice.command} for ${asset.sourceUrl}.',
    );
    onPhase?.call('running_tool');
    onProgress(0.1);
    final result = await _toolRunner.run(
      tool: toolInfo,
      args: args,
      workingDirectory: outputDir.path,
      cancelToken: cancelToken,
    );
    if (!result.isSuccess) {
      await log?.call(
        'error',
        '${toolChoice.command} failed with exit code ${result.exitCode}.',
      );
      return MediaDownloadResult.failed(
        '${toolChoice.command} failed (${result.exitCode}).',
        outputDir.path,
      );
    }
    onProgress(1);

    final after = await _snapshotFiles(outputDir);
    final newFiles = after.difference(before).toList()..sort();
    if (newFiles.isNotEmpty) {
      await log?.call('info', 'Downloaded ${newFiles.length} file(s).');
    }

    return MediaDownloadResult.completed(outputDir.path);
  }

  Future<bool> _shouldSkip(
    Directory outputDir,
    OverwritePolicy policy,
    DownloadLog? log,
  ) async {
    final hasFiles = await _hasFiles(outputDir);
    if (!hasFiles) {
      return false;
    }
    if (policy == OverwritePolicy.skipIfExists) {
      await log?.call('info', 'Output exists; skipping external tool.');
      return true;
    }
    await log?.call(
      'info',
      'Unable to determine newer output for external tool.',
    );
    return true;
  }

  Future<bool> _hasFiles(Directory outputDir) async {
    if (!await outputDir.exists()) {
      return false;
    }
    await for (final entity in outputDir.list(recursive: true)) {
      if (entity is File) {
        return true;
      }
    }
    return false;
  }

  Future<Set<String>> _snapshotFiles(Directory outputDir) async {
    final results = <String>{};
    if (!await outputDir.exists()) {
      return results;
    }
    await for (final entity in outputDir.list(recursive: true)) {
      if (entity is File) {
        results.add(entity.path);
      }
    }
    return results;
  }

  _ToolChoice? _selectTool(MediaAsset asset) {
    final hint = asset.toolHint.toLowerCase();
    if (hint.contains('gallery')) {
      return const _ToolChoice.gallery();
    }
    if (hint.contains('ytdlp') || hint.contains('yt-dlp')) {
      return const _ToolChoice.ytdlp();
    }

    final url =
        asset.normalizedUrl.isNotEmpty ? asset.normalizedUrl : asset.sourceUrl;
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (_videoDomains.any((domain) => host.contains(domain))) {
      return const _ToolChoice.ytdlp();
    }
    if (asset.type == 'external') {
      return const _ToolChoice.gallery();
    }
    return null;
  }

  List<String> _buildArgs(
    _ToolChoice tool,
    MediaAsset asset,
    File targetFile,
    Directory outputDir,
  ) {
    final url =
        asset.normalizedUrl.isNotEmpty ? asset.normalizedUrl : asset.sourceUrl;
    if (tool.command == 'yt-dlp') {
      final baseName = p.basenameWithoutExtension(targetFile.path);
      final safeBase = baseName.isEmpty ? 'media' : baseName;
      final template = p.join(outputDir.path, '$safeBase.%(ext)s');
      return ['-o', template, url];
    }
    return ['--directory', outputDir.path, url];
  }
}

class _ToolChoice {
  const _ToolChoice._(this.command);

  final String command;

  const _ToolChoice.gallery() : this._('gallery-dl');

  const _ToolChoice.ytdlp() : this._('yt-dlp');
}

const _videoDomains = [
  'youtube.com',
  'youtu.be',
  'vimeo.com',
  'tiktok.com',
  'twitch.tv',
  'streamable.com',
];
