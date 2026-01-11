import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/logs_repository.dart';
import 'package:reddit_dl/data/settings_repository.dart';
import 'package:reddit_dl/services/download/external_media_downloader.dart';
import 'package:reddit_dl/services/tools/external_tool_runner.dart';
import 'package:reddit_dl/services/tools/tool_detector.dart';

void main() {
  test('builds yt-dlp args and runs in output directory', () async {
    final toolRunner = FakeToolRunner();
    addTearDown(() async => toolRunner.dispose());
    final downloader = ExternalMediaDownloader(
      toolDetector: FakeToolDetector(),
      toolRunner: toolRunner,
    );

    final tempDir = await Directory.systemTemp.createTemp('external-download');
    addTearDown(() async => tempDir.delete(recursive: true));

    final asset = _externalAsset(toolHint: 'ytdlp');
    final targetFile = File('${tempDir.path}/post/video');
    final settings = AppSettings.defaults();

    final result = await downloader.download(
      asset: asset,
      targetFile: targetFile,
      settings: settings,
      policy: OverwritePolicy.skipIfExists,
      onProgress: (_) {},
    );

    expect(result.isCompleted, isTrue);
    expect(toolRunner.lastArgs, isNotNull);
    expect(toolRunner.lastWorkingDirectory, targetFile.parent.path);
    expect(toolRunner.lastArgs!.first, '-o');
    expect(toolRunner.lastArgs!.last, asset.sourceUrl);
  });

  test('maps non-zero exit to failed', () async {
    final toolRunner = FakeToolRunner(exitCode: 2);
    addTearDown(() async => toolRunner.dispose());
    final downloader = ExternalMediaDownloader(
      toolDetector: FakeToolDetector(),
      toolRunner: toolRunner,
    );

    final tempDir = await Directory.systemTemp.createTemp('external-download');
    addTearDown(() async => tempDir.delete(recursive: true));

    final asset = _externalAsset(toolHint: 'gallerydl');
    final targetFile = File('${tempDir.path}/post/gallery');
    final settings = AppSettings.defaults();

    final result = await downloader.download(
      asset: asset,
      targetFile: targetFile,
      settings: settings,
      policy: OverwritePolicy.skipIfExists,
      onProgress: (_) {},
    );

    expect(result.isFailed, isTrue);
  });
}

MediaAsset _externalAsset({required String toolHint}) {
  return MediaAsset(
    id: 2,
    savedItemId: 2,
    type: 'external',
    sourceUrl: 'https://example.com/gallery',
    normalizedUrl: 'https://example.com/gallery',
    toolHint: toolHint,
    filenameSuggested: null,
    metadataJson: null,
  );
}

class FakeToolDetector extends ToolDetector {
  @override
  Future<ToolInfo> detect(String name, {String? overridePath}) async {
    return ToolInfo(
      name: name,
      path: '/usr/bin/$name',
      version: '1.0',
      isAvailable: true,
      isOverride: overridePath?.isNotEmpty == true,
    );
  }
}

class FakeToolRunner extends ExternalToolRunner {
  FakeToolRunner({this.exitCode = 0})
    : _db = AppDatabase.inMemory(),
      super(LogsRepository(_db));

  final int exitCode;
  List<String>? lastArgs;
  String? lastWorkingDirectory;
  final AppDatabase _db;

  Future<void> dispose() async {
    await _db.close();
  }

  @override
  Future<ExternalToolResult> run({
    required ToolInfo tool,
    required List<String> args,
    String? workingDirectory,
    CancelToken? cancelToken,
  }) async {
    lastArgs = args;
    lastWorkingDirectory = workingDirectory;
    return ExternalToolResult(
      exitCode: exitCode,
      stdout: const [],
      stderr: const [],
    );
  }
}
