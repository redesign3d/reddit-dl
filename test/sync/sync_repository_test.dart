import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as drift;

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/sync_repository.dart';
import 'package:reddit_dl/features/sync/reddit_json_parser.dart';

void main() {
  test('updates existing saved item from zip with sync data', () async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());

    final savedId = await db.into(db.savedItems).insert(
          SavedItemsCompanion.insert(
            permalink: 'https://www.reddit.com/r/test/comments/abc/title',
            kind: 'post',
            subreddit: 'test',
            author: 'zipper',
            createdUtc: 1600000000,
            title: 'Old title',
            bodyMarkdown: const drift.Value.absent(),
            source: 'zip',
            resolutionStatus: 'partial',
          ),
        );

    final resolved = ResolvedItem(
      permalink: 'https://www.reddit.com/r/test/comments/abc/title',
      kind: 'post',
      subreddit: 'test',
      author: 'syncer',
      createdUtc: 1700000000,
      title: 'New title',
      body: '',
      over18: true,
      media: const [
        ResolvedMediaAsset(
          type: 'image',
          sourceUrl: 'https://i.redd.it/abc.jpg',
          normalizedUrl: 'https://i.redd.it/abc.jpg',
          toolHint: 'none',
        ),
      ],
      status: ResolutionStatus.ok,
    );

    final repository = SyncRepository(db);
    final result = await repository.upsertResolved(resolved);

    expect(result.inserted, isFalse);
    expect(result.updated, isTrue);
    expect(result.mediaInserted, 1);

    final item = await (db.select(db.savedItems)
          ..where((tbl) => tbl.id.equals(savedId)))
        .getSingle();
    expect(item.title, 'New title');
    expect(item.source, 'zip');
    expect(item.over18, isTrue);
    expect(item.resolutionStatus, 'ok');
    expect(item.syncedAt, isNotNull);

    final media = await db.select(db.mediaAssets).get();
    expect(media.length, 1);
  });
}
