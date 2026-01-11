import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/logs_repository.dart';
import 'package:reddit_dl/data/queue_repository.dart';
import 'package:reddit_dl/data/session_repository.dart';
import 'package:reddit_dl/data/settings_repository.dart';
import 'package:reddit_dl/services/download/download_scheduler.dart';
import 'package:reddit_dl/services/download/download_telemetry.dart';
import 'package:reddit_dl/services/download/http_media_downloader.dart';
import 'package:reddit_dl/services/download/overwrite_policy.dart';

void main() {
  test('scheduler completes download and writes file', () async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final queueRepository = QueueRepository(db);
    final settingsRepository = SettingsRepository(db);
    final logsRepository = LogsRepository(db);
    final sessionRepository = SessionRepository();
    final telemetry = DownloadTelemetry();

    final tempDir = await Directory.systemTemp.createTemp('downloads');
    addTearDown(() async => tempDir.delete(recursive: true));
    await settingsRepository.save(
      AppSettings.defaults().copyWith(
        downloadRoot: tempDir.path,
      ),
    );

    final itemId = await db.into(db.savedItems).insert(
          SavedItemsCompanion.insert(
            permalink: 'https://www.reddit.com/r/test/comments/abc/title',
            kind: 'post',
            subreddit: 'test',
            author: 'alice',
            createdUtc: 1700000000,
            title: 'Sample',
            bodyMarkdown: const Value.absent(),
            source: 'sync',
            resolutionStatus: 'ok',
          ),
        );
    await db.into(db.mediaAssets).insert(
          MediaAssetsCompanion.insert(
            savedItemId: itemId,
            type: 'image',
            sourceUrl: 'https://example.com/image.jpg',
            normalizedUrl: 'https://example.com/image.jpg',
            toolHint: 'none',
          ),
        );

    final jobResult = await queueRepository.enqueueForItem(
      (await (db.select(db.savedItems)
            ..where((tbl) => tbl.id.equals(itemId)))
          .getSingle()),
      policySnapshot: 'skip_if_exists',
    );

    final fakeDownloader = FakeDownloader(shouldComplete: true);
    final scheduler = DownloadScheduler(
      queueRepository: queueRepository,
      settingsRepository: settingsRepository,
      logsRepository: logsRepository,
      sessionRepository: sessionRepository,
      telemetry: telemetry,
      downloader: fakeDownloader,
    );
    scheduler.start();
    addTearDown(() async => scheduler.dispose());

    final job = await _waitForStatus(
      db,
      jobResult.job.id,
      'completed',
    );
    expect(job.outputPath, isNotEmpty);
    final files = tempDir.listSync(recursive: true).whereType<File>().toList();
    expect(files, isNotEmpty);
  });

  test('scheduler skips nsfw when disabled', () async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final queueRepository = QueueRepository(db);
    final settingsRepository = SettingsRepository(db);
    final logsRepository = LogsRepository(db);
    final sessionRepository = SessionRepository();
    final telemetry = DownloadTelemetry();

    await settingsRepository.save(AppSettings.defaults());

    final itemId = await db.into(db.savedItems).insert(
          SavedItemsCompanion.insert(
            permalink: 'https://www.reddit.com/r/test/comments/abc/title',
            kind: 'post',
            subreddit: 'test',
            author: 'alice',
            createdUtc: 1700000000,
            title: 'Sample',
            bodyMarkdown: const Value.absent(),
            source: 'sync',
            resolutionStatus: 'ok',
            over18: true,
          ),
        );
    await db.into(db.mediaAssets).insert(
          MediaAssetsCompanion.insert(
            savedItemId: itemId,
            type: 'image',
            sourceUrl: 'https://example.com/image.jpg',
            normalizedUrl: 'https://example.com/image.jpg',
            toolHint: 'none',
          ),
        );

    final jobResult = await queueRepository.enqueueForItem(
      (await (db.select(db.savedItems)
            ..where((tbl) => tbl.id.equals(itemId)))
          .getSingle()),
      policySnapshot: 'skip_if_exists',
    );

    final fakeDownloader = FakeDownloader(shouldComplete: true);
    final scheduler = DownloadScheduler(
      queueRepository: queueRepository,
      settingsRepository: settingsRepository,
      logsRepository: logsRepository,
      sessionRepository: sessionRepository,
      telemetry: telemetry,
      downloader: fakeDownloader,
    );
    scheduler.start();
    addTearDown(() async => scheduler.dispose());

    final job = await _waitForStatus(db, jobResult.job.id, 'skipped');
    expect(job.lastError, contains('NSFW'));
  });

  test('pause and resume stops scheduling', () async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final queueRepository = QueueRepository(db);
    final settingsRepository = SettingsRepository(db);
    final logsRepository = LogsRepository(db);
    final sessionRepository = SessionRepository();
    final telemetry = DownloadTelemetry();

    final tempDir = await Directory.systemTemp.createTemp('downloads');
    addTearDown(() async => tempDir.delete(recursive: true));
    await settingsRepository.save(
      AppSettings.defaults().copyWith(downloadRoot: tempDir.path),
    );

    final itemId = await db.into(db.savedItems).insert(
          SavedItemsCompanion.insert(
            permalink: 'https://www.reddit.com/r/test/comments/abc/title',
            kind: 'post',
            subreddit: 'test',
            author: 'alice',
            createdUtc: 1700000000,
            title: 'Sample',
            bodyMarkdown: const Value.absent(),
            source: 'sync',
            resolutionStatus: 'ok',
          ),
        );
    await db.into(db.mediaAssets).insert(
          MediaAssetsCompanion.insert(
            savedItemId: itemId,
            type: 'image',
            sourceUrl: 'https://example.com/image.jpg',
            normalizedUrl: 'https://example.com/image.jpg',
            toolHint: 'none',
          ),
        );

    final jobResult = await queueRepository.enqueueForItem(
      (await (db.select(db.savedItems)
            ..where((tbl) => tbl.id.equals(itemId)))
          .getSingle()),
      policySnapshot: 'skip_if_exists',
    );

    final fakeDownloader = FakeDownloader(shouldComplete: false);
    final scheduler = DownloadScheduler(
      queueRepository: queueRepository,
      settingsRepository: settingsRepository,
      logsRepository: logsRepository,
      sessionRepository: sessionRepository,
      telemetry: telemetry,
      downloader: fakeDownloader,
    );
    scheduler.start();
    addTearDown(() async => scheduler.dispose());

    await _waitForStatus(db, jobResult.job.id, 'running');
    await queueRepository.pauseJob(jobResult.job.id);
    await _waitForStatus(db, jobResult.job.id, 'paused');

    fakeDownloader.shouldComplete = true;
    await queueRepository.resumeJob(jobResult.job.id);
    await _waitForStatus(db, jobResult.job.id, 'completed');
  });
}

Future<DownloadJob> _waitForStatus(
  AppDatabase db,
  int jobId,
  String status, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final start = DateTime.now();
  while (true) {
    final job = await (db.select(db.downloadJobs)
          ..where((tbl) => tbl.id.equals(jobId)))
        .getSingle();
    if (job.status == status) {
      return job;
    }
    if (DateTime.now().difference(start) > timeout) {
      throw StateError('Timed out waiting for status $status');
    }
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

class FakeDownloader extends HttpMediaDownloader {
  FakeDownloader({required this.shouldComplete})
      : super(Dio(), OverwritePolicyEvaluator(Dio()));

  bool shouldComplete;

  @override
  Future<MediaDownloadResult> download({
    required MediaAsset asset,
    required File targetFile,
    required OverwritePolicy policy,
    required void Function(double progress) onProgress,
    void Function(Headers headers)? onHeaders,
    CancelToken? cancelToken,
  }) async {
    if (!shouldComplete) {
      while (cancelToken != null && !cancelToken.isCancelled) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      throw DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.cancel,
      );
    }

    if (!await targetFile.parent.exists()) {
      await targetFile.parent.create(recursive: true);
    }
    await targetFile.writeAsString('data');
    onProgress(1);
    return MediaDownloadResult.completed(targetFile.path);
  }
}
