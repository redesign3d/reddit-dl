import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/import_repository.dart';
import 'package:reddit_dl/features/import/zip_import_parser.dart';

void main() {
  test(
    'safe upsert keeps higher-quality synced fields when zip row is worse',
    () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());
      final repository = ImportRepository(db, ZipImportParser());

      const permalink = 'https://www.reddit.com/r/test/comments/abc/post-title';
      final importedAt = DateTime(2024, 1, 1);
      final syncedAt = DateTime(2025, 1, 1);
      final lastResolvedAt = DateTime(2025, 1, 2);
      await db
          .into(db.savedItems)
          .insert(
            SavedItemsCompanion.insert(
              permalink: permalink,
              kind: 'post',
              subreddit: 'test',
              author: 'sync-author',
              createdUtc: 1700001234,
              title: 'Synced title',
              bodyMarkdown: const drift.Value('Synced body'),
              over18: const drift.Value(true),
              source: 'sync',
              importedAt: drift.Value(importedAt),
              syncedAt: drift.Value(syncedAt),
              lastResolvedAt: drift.Value(lastResolvedAt),
              resolutionStatus: 'ok',
              rawJsonCache: const drift.Value('{"ok":true}'),
            ),
          );

      final zipBytes = _buildZip({
        'saved_posts.csv': [
          'permalink,subreddit,author,title,created_utc',
          'https://old.reddit.com/r/test/comments/abc/post-title/,,unknown,,0',
        ].join('\n'),
      });

      final result = await repository.importZipBytes(zipBytes);

      expect(result.inserted, 0);
      expect(result.updated, 1);

      final row = await (db.select(
        db.savedItems,
      )..where((tbl) => tbl.permalink.equals(permalink))).getSingle();
      expect(row.resolutionStatus, 'ok');
      expect(row.over18, isTrue);
      expect(row.title, 'Synced title');
      expect(row.subreddit, 'test');
      expect(row.author, 'sync-author');
      expect(row.bodyMarkdown, 'Synced body');
      expect(row.createdUtc, 1700001234);
      expect(row.syncedAt, syncedAt);
      expect(row.lastResolvedAt, lastResolvedAt);
      expect(row.importedAt, importedAt);
      expect(row.rawJsonCache, '{"ok":true}');
    },
  );

  test('safe upsert fills missing text fields from zip rows', () async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final repository = ImportRepository(db, ZipImportParser());

    const permalink = 'https://www.reddit.com/r/test/comments/def/post-title';
    await db
        .into(db.savedItems)
        .insert(
          SavedItemsCompanion.insert(
            permalink: permalink,
            kind: 'post',
            subreddit: '',
            author: 'unknown',
            createdUtc: 0,
            title: '',
            bodyMarkdown: const drift.Value.absent(),
            source: 'zip',
            resolutionStatus: 'partial',
          ),
        );

    final zipBytes = _buildZip({
      'saved_posts.csv': [
        'permalink,subreddit,author,title,created_utc',
        '/r/test/comments/def/post-title,test,alice,Imported title,1700002000',
      ].join('\n'),
      'saved_comments.csv': [
        'permalink,subreddit,author,body,created_utc',
        '/r/test/comments/def/post-title/comment1,test,alice,Imported body,1700002001',
      ].join('\n'),
    });

    final result = await repository.importZipBytes(zipBytes);

    expect(result.inserted, 1);
    expect(result.updated, 1);

    final post = await (db.select(
      db.savedItems,
    )..where((tbl) => tbl.permalink.equals(permalink))).getSingle();
    expect(post.title, 'Imported title');
    expect(post.subreddit, 'test');
    expect(post.author, 'alice');
    expect(post.createdUtc, 1700002000);
  });

  test('normalizes mixed permalink formats to canonical saved item values', () async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final repository = ImportRepository(db, ZipImportParser());

    final zipBytes = _buildZip({
      'saved_posts.csv': [
        'permalink,subreddit,author,title,created_utc',
        'https://old.reddit.com/r/test/comments/abc/post-title/,test,alice,Post title,1700000000',
        '/r/test/comments/abc/post-title/,test,alice,Post title,1700000000',
      ].join('\n'),
      'saved_comments.csv': [
        'permalink,subreddit,author,body,created_utc',
        'https://reddit.com/r/test/comments/abc/post-title/def456/,test,bob,Comment one,1700000100',
        'https://www.reddit.com/r/test/comments/abc/post-title/def456/.json,test,bob,Comment one,1700000100',
      ].join('\n'),
    });

    final result = await repository.importZipBytes(zipBytes);

    expect(result.inserted, 2);
    expect(result.updated, 0);
    expect(result.skipped, 2);

    final rows = await db.select(db.savedItems).get();
    expect(rows, hasLength(2));
    expect(rows.map((row) => row.permalink).toSet(), {
      'https://www.reddit.com/r/test/comments/abc/post-title',
      'https://www.reddit.com/r/test/comments/abc/post-title/def456',
    });
  });

  test(
    'importing the same zip twice is idempotent for normalized permalinks',
    () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());
      final repository = ImportRepository(db, ZipImportParser());

      final zipBytes = _buildZip({
        'saved_posts.csv': [
          'permalink,subreddit,author,title,created_utc',
          'https://old.reddit.com/r/test/comments/abc/post-title/,test,alice,Post title,1700000000',
        ].join('\n'),
        'saved_comments.csv': [
          'permalink,subreddit,author,body,created_utc',
          '/r/test/comments/abc/post-title/def456/,test,bob,Comment one,1700000100',
        ].join('\n'),
      });

      final first = await repository.importZipBytes(zipBytes);
      final second = await repository.importZipBytes(zipBytes);

      expect(first.inserted, 2);
      expect(first.updated, 0);
      expect(second.inserted, 0);
      expect(second.updated, 2);

      final rows = await db.select(db.savedItems).get();
      expect(rows, hasLength(2));
      expect(rows.map((row) => row.permalink).toSet(), {
        'https://www.reddit.com/r/test/comments/abc/post-title',
        'https://www.reddit.com/r/test/comments/abc/post-title/def456',
      });
    },
  );

  test('skips rows whose normalized permalink is empty or unsupported', () async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final repository = ImportRepository(db, ZipImportParser());

    final zipBytes = _buildZip({
      'saved_posts.csv': [
        'permalink,subreddit,author,title,created_utc',
        'https://www.reddit.com/,test,alice,Invalid root,1700000000',
        'https://www.reddit.com/r/test,test,alice,Invalid subreddit only,1700000001',
        'https://reddit.com/r/test/comments/abc/post-title/,test,alice,Valid post,1700000002',
      ].join('\n'),
      'saved_comments.csv': 'permalink,subreddit,author,body,created_utc',
    });

    final result = await repository.importZipBytes(zipBytes);

    expect(result.inserted, 1);
    expect(result.skipped, 0);

    final rows = await db.select(db.savedItems).get();
    expect(rows, hasLength(1));
    expect(
      rows.single.permalink,
      'https://www.reddit.com/r/test/comments/abc/post-title',
    );
  });
}

Uint8List _buildZip(Map<String, String> files) {
  final archive = Archive();
  files.forEach((path, content) {
    archive.addFile(ArchiveFile.string(path, content));
  });
  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded);
}
