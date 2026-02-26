import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/logs_repository.dart';
import 'package:reddit_dl/data/queue_repository.dart';
import 'package:reddit_dl/data/settings_repository.dart';
import 'package:reddit_dl/features/logs/log_record.dart';
import 'package:reddit_dl/features/queue/queue_cubit.dart';
import 'package:reddit_dl/features/queue/queue_page.dart';
import 'package:reddit_dl/services/download/download_telemetry.dart';

void main() {
  testWidgets('expands and collapses queue details drawer sections', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final queueRepository = QueueRepository(db);
    final logsRepository = LogsRepository(db);
    final settingsRepository = SettingsRepository(db);
    final telemetry = DownloadTelemetry();
    addTearDown(telemetry.dispose);

    await settingsRepository.save(AppSettings.defaults());
    final savedItemId = await db
        .into(db.savedItems)
        .insert(
          SavedItemsCompanion.insert(
            permalink: 'https://www.reddit.com/r/test/comments/abc/title',
            kind: 'post',
            subreddit: 'test',
            author: 'alice',
            createdUtc: 1700000000,
            title: 'Queue Drawer Item',
            bodyMarkdown: const drift.Value('Body preview'),
            source: 'sync',
            resolutionStatus: 'ok',
          ),
        );
    await db
        .into(db.mediaAssets)
        .insert(
          MediaAssetsCompanion.insert(
            savedItemId: savedItemId,
            type: 'image',
            sourceUrl: 'https://example.com/image.jpg',
            normalizedUrl: 'https://example.com/image.jpg',
            toolHint: 'none',
          ),
        );

    final item = await (db.select(
      db.savedItems,
    )..where((tbl) => tbl.id.equals(savedItemId))).getSingle();
    final enqueueResult = await queueRepository.enqueueForItem(
      item,
      policySnapshot: 'skip_if_exists',
    );
    await logsRepository.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: 'download',
        level: 'info',
        message: 'started',
        relatedJobId: enqueueResult.job.id,
      ),
    );
    await queueRepository.recordJobOutput(
      jobId: enqueueResult.job.id,
      savedItemId: savedItemId,
      path: '/tmp/output.jpg',
      kind: 'media_image',
    );

    final cubit = QueueCubit(
      queueRepository,
      logsRepository,
      settingsRepository,
      telemetry,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await cubit.close();
      await tester.pump();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<QueueRepository>.value(value: queueRepository),
            RepositoryProvider<LogsRepository>.value(value: logsRepository),
            RepositoryProvider<SettingsRepository>.value(
              value: settingsRepository,
            ),
          ],
          child: BlocProvider.value(
            value: cubit,
            child: const Scaffold(body: QueuePage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View details'), findsOneWidget);
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('Recent logs'), findsOneWidget);
    expect(find.text('Produced outputs'), findsOneWidget);
    expect(find.text('Technical details'), findsOneWidget);
    expect(find.textContaining('Current phase'), findsOneWidget);

    await tester.tap(find.text('Hide details'));
    await tester.pumpAndSettle();

    expect(find.text('Recent logs'), findsNothing);
    expect(find.text('Produced outputs'), findsNothing);
    expect(find.text('Technical details'), findsNothing);
  });
}
