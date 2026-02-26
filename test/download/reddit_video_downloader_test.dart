import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:path/path.dart' as p;

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/download_resume_state.dart';
import 'package:reddit_dl/data/settings_repository.dart';
import 'package:reddit_dl/services/download/ffmpeg_executor.dart';
import 'package:reddit_dl/services/download/http_media_downloader.dart';
import 'package:reddit_dl/services/download/overwrite_policy.dart';
import 'package:reddit_dl/services/download/reddit_video_downloader.dart';
import 'package:reddit_dl/services/ffmpeg_runtime_manager.dart';

void main() {
  test('extracts DASH base path from DASH mp4 path', () {
    expect(
      RedditVideoDownloader.extractDashBasePath('/video/DASH_720.mp4'),
      '/video',
    );
    expect(
      RedditVideoDownloader.extractDashBasePath('/video/sub/DASH_1080.mp4'),
      '/video/sub',
    );
  });

  test('generates DASH audio candidate URLs from fallback URL', () {
    final candidates = RedditVideoDownloader.buildDashAudioCandidates(
      'https://v.redd.it/video/sub/DASH_1080.mp4?source=fallback',
    );

    expect(candidates.map((candidate) => candidate.toString()).toList(), [
      'https://v.redd.it/video/sub/DASH_audio.mp4',
      'https://v.redd.it/video/sub/DASH_AUDIO_128.mp4',
    ]);
  });

  test('produces at least one audio candidate for valid DASH fallback URL', () {
    final candidates = RedditVideoDownloader.buildDashAudioCandidates(
      'https://v.redd.it/video/DASH_720.mp4',
    );

    expect(candidates, isNotEmpty);
  });

  test('builds ffmpeg args for dash and merge', () {
    final downloader = RedditVideoDownloader(
      dio: Dio(),
      policyEvaluator: OverwritePolicyEvaluator(Dio()),
      httpDownloader: FakeHttpMediaDownloader(),
      ffmpegRuntime: FakeFfmpegRuntimeManager(),
      ffmpegExecutor: FakeFfmpegExecutor(),
    );

    expect(
      downloader.buildDashArgs(
        dashUrl: 'https://v.redd.it/video/DASHPlaylist.mpd',
        outputPath: '/tmp/output.mp4',
      ),
      [
        '-y',
        '-i',
        'https://v.redd.it/video/DASHPlaylist.mpd',
        '-c',
        'copy',
        '/tmp/output.mp4',
      ],
    );

    expect(
      downloader.buildMergeArgs(
        videoPath: '/tmp/video.mp4',
        audioPath: '/tmp/audio.m4a',
        outputPath: '/tmp/out.mp4',
      ),
      [
        '-y',
        '-i',
        '/tmp/video.mp4',
        '-i',
        '/tmp/audio.m4a',
        '-c',
        'copy',
        '/tmp/out.mp4',
      ],
    );
  });

  test('uses ffmpeg for dash urls', () async {
    final ffmpegExecutor = FakeFfmpegExecutor();
    final downloader = RedditVideoDownloader(
      dio: Dio(),
      policyEvaluator: OverwritePolicyEvaluator(Dio()),
      httpDownloader: FakeHttpMediaDownloader(),
      ffmpegRuntime: FakeFfmpegRuntimeManager(),
      ffmpegExecutor: ffmpegExecutor,
    );

    final tempDir = await Directory.systemTemp.createTemp('video-download');
    addTearDown(() async => tempDir.delete(recursive: true));

    final asset = _videoAsset(
      metadata: {
        'dash_url': 'https://v.redd.it/video/DASHPlaylist.mpd',
        'fallback_url': 'https://v.redd.it/video/DASH_720.mp4',
      },
    );

    final targetFile = File('${tempDir.path}/video');
    final result = await downloader.download(
      asset: asset,
      targetFile: targetFile,
      policy: OverwritePolicy.skipIfExists,
      onProgress: (_) {},
    );

    expect(result.isCompleted, isTrue);
    expect(ffmpegExecutor.lastArgs, isNotNull);
    expect(ffmpegExecutor.lastArgs!.first, '-y');
    expect(await File(result.outputPath).exists(), isTrue);
  });

  test('falls back to http downloader without dash url', () async {
    final httpDownloader = FakeHttpMediaDownloader();
    final downloader = RedditVideoDownloader(
      dio: Dio(),
      policyEvaluator: OverwritePolicyEvaluator(Dio()),
      httpDownloader: httpDownloader,
      ffmpegRuntime: FakeFfmpegRuntimeManager(),
      ffmpegExecutor: FakeFfmpegExecutor(),
    );

    final tempDir = await Directory.systemTemp.createTemp('video-download');
    addTearDown(() async => tempDir.delete(recursive: true));

    final asset = _videoAsset(metadata: const {});
    final targetFile = File('${tempDir.path}/video.mp4');
    final result = await downloader.download(
      asset: asset,
      targetFile: targetFile,
      policy: OverwritePolicy.skipIfExists,
      onProgress: (_) {},
    );

    expect(httpDownloader.called, isTrue);
    expect(result.isCompleted, isTrue);
  });

  test('discovers DASH audio candidate and merges fallback streams', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;

    final httpDownloader = FakeHttpMediaDownloader();
    final ffmpegExecutor = FakeFfmpegExecutor();
    final downloader = RedditVideoDownloader(
      dio: dio,
      policyEvaluator: OverwritePolicyEvaluator(Dio()),
      httpDownloader: httpDownloader,
      ffmpegRuntime: FakeFfmpegRuntimeManager(),
      ffmpegExecutor: ffmpegExecutor,
    );

    final tempDir = await Directory.systemTemp.createTemp('video-download');
    addTearDown(() async => tempDir.delete(recursive: true));

    const fallbackUrl = 'https://v.redd.it/video/DASH_720.mp4';
    const audioCandidate = 'https://v.redd.it/video/DASH_audio.mp4';
    adapter.onHead(audioCandidate, (server) => server.reply(200, ''));
    adapter.onGet(fallbackUrl, (server) => server.reply(200, 'video-stream'));
    adapter.onGet(
      audioCandidate,
      (server) => server.reply(200, 'audio-stream'),
    );

    final asset = _videoAsset(metadata: const {});
    final targetFile = File('${tempDir.path}/video.mp4');

    final result = await downloader.download(
      asset: asset,
      targetFile: targetFile,
      policy: OverwritePolicy.skipIfExists,
      onProgress: (_) {},
    );

    expect(httpDownloader.called, isFalse);
    expect(ffmpegExecutor.lastArgs, isNotNull);
    expect(
      ffmpegExecutor.lastArgs,
      contains(p.join(tempDir.path, 'video_audio.m4a')),
    );
    expect(result.isCompleted, isTrue);
  });
}

MediaAsset _videoAsset({required Map<String, dynamic> metadata}) {
  return MediaAsset(
    id: 1,
    savedItemId: 1,
    type: 'video',
    sourceUrl: 'https://v.redd.it/video/DASH_720.mp4',
    normalizedUrl: 'https://v.redd.it/video/DASH_720.mp4',
    toolHint: 'none',
    filenameSuggested: null,
    metadataJson: jsonEncode(metadata),
  );
}

class FakeFfmpegRuntimeManager extends FfmpegRuntimeManager {
  @override
  Future<FfmpegRuntimeInfo> status() async {
    return const FfmpegRuntimeInfo(
      isInstalled: true,
      ffmpegPath: '/tmp/ffmpeg',
      ffprobePath: '/tmp/ffprobe',
    );
  }

  @override
  Future<FfmpegRuntimeInfo> install({
    void Function(double progress)? onProgress,
  }) async {
    return status();
  }
}

class FakeFfmpegExecutor implements FfmpegExecutor {
  List<String>? lastArgs;

  @override
  Future<FfmpegRunResult> run({
    required String ffmpegPath,
    required List<String> args,
    String? workingDirectory,
    CancelToken? cancelToken,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  }) async {
    lastArgs = args;
    final outputPath = args.last;
    final outFile = File(outputPath);
    if (!await outFile.parent.exists()) {
      await outFile.parent.create(recursive: true);
    }
    await outFile.writeAsString('ffmpeg');
    return const FfmpegRunResult(exitCode: 0, stdout: [], stderr: []);
  }
}

class FakeHttpMediaDownloader extends HttpMediaDownloader {
  FakeHttpMediaDownloader() : super(Dio(), OverwritePolicyEvaluator(Dio()));

  bool called = false;

  @override
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
    called = true;
    if (!await targetFile.parent.exists()) {
      await targetFile.parent.create(recursive: true);
    }
    await targetFile.writeAsString('data');
    onProgress(1);
    return MediaDownloadResult.completed(targetFile.path);
  }
}
