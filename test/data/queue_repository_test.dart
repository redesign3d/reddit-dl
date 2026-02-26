import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/queue_repository.dart';

void main() {
  test('fetchQueuedRecords returns queued jobs in FIFO order', () async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final repository = QueueRepository(db);

    final firstItem = await _insertItem(
      db,
      'https://www.reddit.com/r/test/comments/a/title',
    );
    final secondItem = await _insertItem(
      db,
      'https://www.reddit.com/r/test/comments/b/title',
    );
    final thirdItem = await _insertItem(
      db,
      'https://www.reddit.com/r/test/comments/c/title',
    );

    final firstJob = await repository.enqueueForItem(
      firstItem,
      policySnapshot: 'skip_if_exists',
    );
    final secondJob = await repository.enqueueForItem(
      secondItem,
      policySnapshot: 'skip_if_exists',
    );
    final thirdJob = await repository.enqueueForItem(
      thirdItem,
      policySnapshot: 'skip_if_exists',
    );

    final queued = await repository.fetchQueuedRecords(10);
    expect(queued.map((record) => record.job.id).toList(), [
      firstJob.job.id,
      secondJob.job.id,
      thirdJob.job.id,
    ]);
  });

  test('watchQueue emits jobs ordered oldest first', () async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final repository = QueueRepository(db);

    final firstItem = await _insertItem(
      db,
      'https://www.reddit.com/r/test/comments/d/title',
    );
    final secondItem = await _insertItem(
      db,
      'https://www.reddit.com/r/test/comments/e/title',
    );

    final firstJob = await repository.enqueueForItem(
      firstItem,
      policySnapshot: 'skip_if_exists',
    );
    final secondJob = await repository.enqueueForItem(
      secondItem,
      policySnapshot: 'skip_if_exists',
    );

    final records = await repository.watchQueue().first;
    expect(records.take(2).map((record) => record.job.id).toList(), [
      firstJob.job.id,
      secondJob.job.id,
    ]);
  });

  test(
    'enqueueForItems batches inserts and skips already active jobs',
    () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());
      final repository = QueueRepository(db);

      final firstItem = await _insertItem(
        db,
        'https://www.reddit.com/r/test/comments/f/title',
      );
      final secondItem = await _insertItem(
        db,
        'https://www.reddit.com/r/test/comments/g/title',
      );
      final thirdItem = await _insertItem(
        db,
        'https://www.reddit.com/r/test/comments/h/title',
      );

      await repository.enqueueForItem(
        firstItem,
        policySnapshot: 'skip_if_exists',
      );

      final result = await repository.enqueueForItems([
        firstItem,
        secondItem,
        thirdItem,
      ], policySnapshot: 'skip_if_exists');

      expect(result.createdCount, 2);
      expect(result.skippedCount, 1);

      final jobs =
          await (db.select(db.downloadJobs)..orderBy([
                (tbl) => drift.OrderingTerm(
                  expression: tbl.savedItemId,
                  mode: drift.OrderingMode.asc,
                ),
              ]))
              .get();
      expect(jobs, hasLength(3));
      expect(jobs.map((job) => job.savedItemId).toSet(), {
        firstItem.id,
        secondItem.id,
        thirdItem.id,
      });
    },
  );
}

Future<SavedItem> _insertItem(AppDatabase db, String permalink) async {
  final id = await db
      .into(db.savedItems)
      .insert(
        SavedItemsCompanion.insert(
          permalink: permalink,
          kind: 'post',
          subreddit: 'test',
          author: 'alice',
          createdUtc: 1700000000,
          title: 'Title',
          bodyMarkdown: const drift.Value.absent(),
          source: 'sync',
          resolutionStatus: 'ok',
        ),
      );
  return (db.select(
    db.savedItems,
  )..where((tbl) => tbl.id.equals(id))).getSingle();
}
