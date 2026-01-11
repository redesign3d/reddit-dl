import 'package:drift/drift.dart';

import '../features/import/zip_import_parser.dart';
import 'app_database.dart';

class ImportRepository {
  ImportRepository(this._db, this._parser);

  final AppDatabase _db;
  final ZipImportParser _parser;

  Future<ImportResult> importZipBytes(Uint8List bytes) async {
    final archive = _parser.parseBytes(bytes);
    final allItems = <ImportItem>[
      ...archive.posts,
      ...archive.comments,
    ];

    if (allItems.isEmpty) {
      return ImportResult.empty();
    }

    final uniqueMap = <String, ImportItem>{};
    var skipped = 0;
    for (final item in allItems) {
      if (item.permalink.isEmpty) {
        skipped++;
        continue;
      }
      if (uniqueMap.containsKey(item.permalink)) {
        skipped++;
        continue;
      }
      uniqueMap[item.permalink] = item;
    }

    final permalinks = uniqueMap.keys.toList();
    final existingRows = await (_db.select(_db.savedItems)
          ..where((tbl) => tbl.permalink.isIn(permalinks)))
        .get();
    final existingSet = existingRows.map((row) => row.permalink).toSet();

    var inserted = 0;
    var updated = 0;
    final now = DateTime.now();

    final inserts = <SavedItemsCompanion>[];
    for (final entry in uniqueMap.values) {
      final exists = existingSet.contains(entry.permalink);
      if (exists) {
        updated++;
      } else {
        inserted++;
      }

      final subreddit = entry.subreddit.isNotEmpty
          ? entry.subreddit
          : _deriveSubreddit(entry.permalink);

      inserts.add(
        SavedItemsCompanion(
          id: const Value.absent(),
          permalink: Value(entry.permalink),
          kind: Value(entry.kind.name),
          subreddit: Value(subreddit),
          author: Value(entry.author),
          createdUtc: Value(entry.createdUtc ?? 0),
          title: Value(entry.title),
          bodyMarkdown: Value(entry.body.isEmpty ? null : entry.body),
          over18: const Value(false),
          source: const Value('zip'),
          importedAt: Value(now),
          syncedAt: const Value.absent(),
          lastResolvedAt: const Value.absent(),
          resolutionStatus: const Value('partial'),
          rawJsonCache: const Value.absent(),
        ),
      );
    }

    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.savedItems, inserts);
    });

    return ImportResult(
      posts: archive.posts.length,
      comments: archive.comments.length,
      inserted: inserted,
      updated: updated,
      skipped: skipped,
      failures: 0,
    );
  }
}

class ImportResult {
  const ImportResult({
    required this.posts,
    required this.comments,
    required this.inserted,
    required this.updated,
    required this.skipped,
    required this.failures,
  });

  final int posts;
  final int comments;
  final int inserted;
  final int updated;
  final int skipped;
  final int failures;

  factory ImportResult.empty() => const ImportResult(
        posts: 0,
        comments: 0,
        inserted: 0,
        updated: 0,
        skipped: 0,
        failures: 0,
      );
}

String _deriveSubreddit(String permalink) {
  final match = RegExp(r'/r/([^/]+)/', caseSensitive: false).firstMatch(permalink);
  if (match == null) {
    return '';
  }
  return match.group(1) ?? '';
}
