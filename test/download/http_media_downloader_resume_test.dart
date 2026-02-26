import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/download_resume_state.dart';
import 'package:reddit_dl/services/download/http_media_downloader.dart';
import 'package:reddit_dl/services/download/overwrite_policy.dart';
import 'package:reddit_dl/data/settings_repository.dart';

void main() {
  test('resumes partial file when range and validators match', () async {
    final bytes = Uint8List.fromList(
      List<int>.generate(1024 * 1024, (index) => index % 251),
    );
    final server = await _startTestServer(
      bytes: bytes,
      supportsRange: true,
      etag: '"resume-v1"',
      lastModified: HttpDate.format(DateTime.utc(2025, 1, 1)),
      delayPerChunk: const Duration(milliseconds: 4),
    );
    addTearDown(server.close);

    final tempDir = await Directory.systemTemp.createTemp('resume-http');
    addTearDown(() async => tempDir.delete(recursive: true));

    final store = _InMemoryResumeStateStore();
    final url = server.url('/file.bin');
    final targetFile = File('${tempDir.path}/file.bin');

    final firstDio = Dio();
    addTearDown(firstDio.close);
    final firstDownloader = HttpMediaDownloader(
      firstDio,
      OverwritePolicyEvaluator(firstDio),
    );
    final cancelToken = CancelToken();

    try {
      await firstDownloader.download(
        asset: _asset(url),
        targetFile: targetFile,
        policy: OverwritePolicy.skipIfExists,
        onProgress: (progress) {
          if (progress > 0.25 && !cancelToken.isCancelled) {
            cancelToken.cancel('interrupt after partial write');
          }
        },
        resumeStateStore: store,
        relatedJobId: 11,
        relatedMediaAssetId: 101,
        cancelToken: cancelToken,
      );
      fail('Expected cancelled first attempt.');
    } on DioException catch (error) {
      expect(CancelToken.isCancel(error), isTrue);
    }

    final partFile = File('${targetFile.path}.part');
    expect(await partFile.exists(), isTrue);
    final partialSize = await partFile.length();
    expect(partialSize, greaterThan(0));
    expect(partialSize, lessThan(bytes.length));

    final persisted = await store.fetchResumeState(
      jobId: 11,
      mediaAssetId: 101,
    );
    expect(persisted, isNotNull);
    expect(persisted!.etag, '"resume-v1"');
    expect(persisted.downloadedBytes, equals(partialSize));

    final secondDio = Dio();
    addTearDown(secondDio.close);
    final secondDownloader = HttpMediaDownloader(
      secondDio,
      OverwritePolicyEvaluator(secondDio),
    );
    final result = await secondDownloader.download(
      asset: _asset(url),
      targetFile: targetFile,
      policy: OverwritePolicy.skipIfExists,
      onProgress: (_) {},
      resumeStateStore: store,
      relatedJobId: 11,
      relatedMediaAssetId: 101,
    );
    expect(result.isCompleted, isTrue);
    expect(result.outputPath, targetFile.path);
    expect(await targetFile.readAsBytes(), bytes);
    expect(await store.fetchResumeState(jobId: 11, mediaAssetId: 101), isNull);
  });

  test('restarts cleanly when server does not support ranges', () async {
    final bytes = Uint8List.fromList(
      List<int>.generate(256 * 1024, (index) => (index * 7) % 253),
    );
    final server = await _startTestServer(
      bytes: bytes,
      supportsRange: false,
      etag: '"no-range-v1"',
      lastModified: HttpDate.format(DateTime.utc(2025, 1, 1)),
      delayPerChunk: const Duration(milliseconds: 1),
    );
    addTearDown(server.close);

    final tempDir = await Directory.systemTemp.createTemp('resume-http');
    addTearDown(() async => tempDir.delete(recursive: true));

    final targetFile = File('${tempDir.path}/file.bin');
    final partFile = File('${targetFile.path}.part');
    final partial = bytes.sublist(0, 4096);
    await partFile.writeAsBytes(partial);

    final store = _InMemoryResumeStateStore();
    final url = server.url('/file.bin');
    await store.upsertResumeState(
      DownloadResumeState(
        jobId: 22,
        mediaAssetId: 202,
        url: url,
        localTempPath: partFile.path,
        expectedFinalPath: targetFile.path,
        etag: '"no-range-v1"',
        lastModified: HttpDate.format(DateTime.utc(2025, 1, 1)),
        totalBytes: bytes.length,
        downloadedBytes: partial.length,
      ),
    );

    final dio = Dio();
    addTearDown(dio.close);
    final downloader = HttpMediaDownloader(dio, OverwritePolicyEvaluator(dio));
    final result = await downloader.download(
      asset: _asset(url, id: 202),
      targetFile: targetFile,
      policy: OverwritePolicy.skipIfExists,
      onProgress: (_) {},
      resumeStateStore: store,
      relatedJobId: 22,
      relatedMediaAssetId: 202,
    );

    expect(result.isCompleted, isTrue);
    expect(await targetFile.readAsBytes(), bytes);
    expect(await partFile.exists(), isFalse);
    expect(await store.fetchResumeState(jobId: 22, mediaAssetId: 202), isNull);
    expect(server.rangeHeaders.contains('bytes=${partial.length}-'), isFalse);
  });
}

MediaAsset _asset(String url, {int id = 101}) {
  return MediaAsset(
    id: id,
    savedItemId: 1,
    type: 'image',
    sourceUrl: url,
    normalizedUrl: url,
    toolHint: 'none',
    filenameSuggested: null,
    metadataJson: null,
  );
}

class _InMemoryResumeStateStore implements DownloadResumeStateStore {
  final Map<String, DownloadResumeState> _states = {};

  @override
  Future<void> clearResumeState({
    required int jobId,
    required int mediaAssetId,
  }) async {
    _states.remove(_key(jobId, mediaAssetId));
  }

  @override
  Future<DownloadResumeState?> fetchResumeState({
    required int jobId,
    required int mediaAssetId,
  }) async {
    return _states[_key(jobId, mediaAssetId)];
  }

  @override
  Future<void> upsertResumeState(DownloadResumeState state) async {
    _states[_key(state.jobId, state.mediaAssetId)] = state;
  }

  String _key(int jobId, int mediaAssetId) => '$jobId:$mediaAssetId';
}

class _TestServer {
  _TestServer(this._server);

  final HttpServer _server;
  final List<String?> rangeHeaders = [];

  String url(String path) => 'http://127.0.0.1:${_server.port}$path';

  Future<void> close() => _server.close(force: true);
}

Future<_TestServer> _startTestServer({
  required Uint8List bytes,
  required bool supportsRange,
  required String etag,
  required String lastModified,
  required Duration delayPerChunk,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final wrapper = _TestServer(server);
  server.listen((request) async {
    if (request.uri.path != '/file.bin') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final response = request.response;
    response.headers.set(HttpHeaders.etagHeader, etag);
    response.headers.set(HttpHeaders.lastModifiedHeader, lastModified);
    response.headers.contentType = ContentType.binary;
    if (supportsRange) {
      response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    }

    if (request.method == 'HEAD') {
      response.headers.contentLength = bytes.length;
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }

    if (request.method != 'GET') {
      response.statusCode = HttpStatus.methodNotAllowed;
      await response.close();
      return;
    }

    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    wrapper.rangeHeaders.add(rangeHeader);
    if (supportsRange && rangeHeader != null) {
      final match = RegExp(r'^bytes=(\d+)-(\d*)$').firstMatch(rangeHeader);
      if (match == null) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes */${bytes.length}',
        );
        await response.close();
        return;
      }
      final start = int.parse(match.group(1)!);
      final requestedEnd = match.group(2);
      final end = requestedEnd == null || requestedEnd.isEmpty
          ? bytes.length - 1
          : int.parse(requestedEnd);
      if (start >= bytes.length || end < start) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes */${bytes.length}',
        );
        await response.close();
        return;
      }
      final normalizedEnd = end >= bytes.length ? bytes.length - 1 : end;
      final chunk = bytes.sublist(start, normalizedEnd + 1);
      response.statusCode = HttpStatus.partialContent;
      response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $start-$normalizedEnd/${bytes.length}',
      );
      response.headers.contentLength = chunk.length;
      await _writeChunked(response, chunk, delayPerChunk);
      return;
    }

    response.statusCode = HttpStatus.ok;
    response.headers.contentLength = bytes.length;
    await _writeChunked(response, bytes, delayPerChunk);
  });
  return wrapper;
}

Future<void> _writeChunked(
  HttpResponse response,
  List<int> bytes,
  Duration delayPerChunk,
) async {
  const chunkSize = 8192;
  for (var offset = 0; offset < bytes.length; offset += chunkSize) {
    final end = (offset + chunkSize > bytes.length)
        ? bytes.length
        : offset + chunkSize;
    response.add(bytes.sublist(offset, end));
    await response.flush();
    if (delayPerChunk > Duration.zero) {
      await Future.delayed(delayPerChunk);
    }
  }
  await response.close();
}
