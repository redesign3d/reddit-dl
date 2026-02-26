import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../features/import/zip_import_parser.dart';
import '../features/sync/permalink_utils.dart';
import 'app_database.dart';

class ImportRepository {
  ImportRepository(this._db, this._parser);

  final AppDatabase _db;
  final ZipImportParser _parser;

  Future<ImportResult> importZipBytes(Uint8List bytes) async {
    final archive = _parser.parseBytes(bytes);
    final allItems = <ImportItem>[...archive.posts, ...archive.comments];

    if (allItems.isEmpty) {
      return ImportResult.empty();
    }

    final uniqueMap = <String, ImportItem>{};
    var skipped = 0;
    for (final item in allItems) {
      final permalink = _canonicalPermalink(item.permalink);
      if (permalink == null) {
        developer.log(
          'Skipping ${item.kind.name} import row due to invalid permalink: '
          '${item.permalink}',
          name: 'ImportRepository',
          level: 900,
        );
        skipped++;
        continue;
      }
      if (uniqueMap.containsKey(permalink)) {
        skipped++;
        continue;
      }
      uniqueMap[permalink] = item;
    }

    final permalinks = uniqueMap.keys.toList();
    final existingRows = await (_db.select(
      _db.savedItems,
    )..where((tbl) => tbl.permalink.isIn(permalinks))).get();
    final existingByPermalink = {
      for (final row in existingRows) row.permalink: row,
    };

    var inserted = 0;
    var updated = 0;
    final now = DateTime.now();

    final inserts = <SavedItemsCompanion>[];
    final updates = <({int id, SavedItemsCompanion companion})>[];
    for (final importEntry in uniqueMap.entries) {
      final permalink = importEntry.key;
      final entry = importEntry.value;
      final existing = existingByPermalink[permalink];
      if (existing != null) {
        updates.add((
          id: existing.id,
          companion: _mergeSavedItem(
            existing: existing,
            entry: entry,
            permalink: permalink,
            now: now,
          ),
        ));
        updated++;
      } else {
        inserts.add(
          _insertCompanion(entry: entry, permalink: permalink, now: now),
        );
        inserted++;
      }
    }

    await _db.batch((batch) {
      if (inserts.isNotEmpty) {
        batch.insertAll(_db.savedItems, inserts);
      }
      for (final update in updates) {
        batch.update(
          _db.savedItems,
          update.companion,
          where: (tbl) => tbl.id.equals(update.id),
        );
      }
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

SavedItemsCompanion _insertCompanion({
  required ImportItem entry,
  required String permalink,
  required DateTime now,
}) {
  return SavedItemsCompanion(
    id: const Value.absent(),
    permalink: Value(permalink),
    kind: Value(entry.kind.name),
    subreddit: Value(
      _mergeKnownText('', entry.subreddit, _deriveSubreddit(permalink)),
    ),
    author: Value(_mergeKnownText('', entry.author, 'unknown')),
    createdUtc: Value(_mergeCreatedUtc(0, entry.createdUtc)),
    title: Value(_mergeKnownText('', entry.title, '')),
    bodyMarkdown: Value(_mergeKnownNullableText(null, entry.body)),
    over18: const Value(false),
    source: const Value('zip'),
    importedAt: Value(now),
    syncedAt: const Value.absent(),
    lastResolvedAt: const Value.absent(),
    resolutionStatus: const Value('partial'),
    rawJsonCache: const Value.absent(),
  );
}

SavedItemsCompanion _mergeSavedItem({
  required SavedItem existing,
  required ImportItem entry,
  required String permalink,
  required DateTime now,
}) {
  return SavedItemsCompanion(
    id: Value(existing.id),
    permalink: Value(permalink),
    kind: Value(_mergeKnownText(existing.kind, entry.kind.name, existing.kind)),
    subreddit: Value(
      _mergeKnownText(
        existing.subreddit,
        entry.subreddit,
        _deriveSubreddit(permalink),
      ),
    ),
    author: Value(
      _mergeKnownText(existing.author, entry.author, existing.author),
    ),
    createdUtc: Value(_mergeCreatedUtc(existing.createdUtc, entry.createdUtc)),
    title: Value(_mergeKnownText(existing.title, entry.title, existing.title)),
    bodyMarkdown: Value(
      _mergeKnownNullableText(existing.bodyMarkdown, entry.body),
    ),
    over18: Value(existing.over18),
    source: Value(_mergeKnownText(existing.source, 'zip', 'zip')),
    importedAt: Value(existing.importedAt ?? now),
    syncedAt: Value(existing.syncedAt),
    lastResolvedAt: Value(existing.lastResolvedAt),
    resolutionStatus: Value(
      _mergeKnownText(existing.resolutionStatus, 'partial', 'partial'),
    ),
    rawJsonCache: Value(existing.rawJsonCache),
  );
}

String _mergeKnownText(String existing, String incoming, String fallback) {
  if (_isKnownText(existing)) {
    return existing.trim();
  }
  if (_isKnownText(incoming)) {
    return incoming.trim();
  }
  return fallback;
}

String? _mergeKnownNullableText(String? existing, String incoming) {
  if (_isKnownText(existing)) {
    return existing!.trim();
  }
  if (_isKnownText(incoming)) {
    return incoming.trim();
  }
  return null;
}

bool _isKnownText(String? value) {
  if (value == null) {
    return false;
  }
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return false;
  }
  return normalized.toLowerCase() != 'unknown';
}

int _mergeCreatedUtc(int existing, int? incoming) {
  if (existing > 0) {
    return existing;
  }
  final incomingValue = incoming ?? 0;
  return incomingValue > 0 ? incomingValue : 0;
}

String _deriveSubreddit(String permalink) {
  final match = RegExp(
    r'/r/([^/]+)/',
    caseSensitive: false,
  ).firstMatch(permalink);
  if (match == null) {
    return '';
  }
  return match.group(1) ?? '';
}

String? _canonicalPermalink(String rawPermalink) {
  final normalized = normalizePermalink(rawPermalink);
  if (normalized.isEmpty) {
    return null;
  }
  if (!_isSupportedPermalink(normalized)) {
    return null;
  }
  return normalized;
}

bool _isSupportedPermalink(String permalink) {
  return RegExp(
    r'^https://www\.reddit\.com/r/[^/]+/comments/[^/]+(?:/[^/]+)*(?:/)?$',
    caseSensitive: false,
  ).hasMatch(permalink);
}
