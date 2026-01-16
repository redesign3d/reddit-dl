import 'package:drift/drift.dart';

import 'app_database.dart';

class LibraryRepository {
  LibraryRepository(this._db);

  final AppDatabase _db;

  Stream<List<SavedItem>> watchAll() {
    final query = _db.select(_db.savedItems)..orderBy([
      (row) =>
          OrderingTerm(expression: row.createdUtc, mode: OrderingMode.desc),
    ]);
    return query.watch();
  }

  Stream<List<String>> watchSubreddits() {
    final query = _db.selectOnly(_db.savedItems, distinct: true)
      ..addColumns([_db.savedItems.subreddit]);
    return query.watch().map((rows) {
      final subreddits =
          rows
              .map((row) => row.read(_db.savedItems.subreddit) ?? '')
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      return subreddits;
    });
  }

  Future<SavedItem?> fetchLatest() async {
    final query =
        _db.select(_db.savedItems)
          ..orderBy([
            (row) => OrderingTerm(
              expression: row.createdUtc,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1);
    return query.getSingleOrNull();
  }

  Stream<List<SavedItem>> watchItemsWithoutMedia() {
    final count = _db.mediaAssets.id.count();
    final query =
        _db.select(_db.savedItems).join([
            leftOuterJoin(
              _db.mediaAssets,
              _db.mediaAssets.savedItemId.equalsExp(_db.savedItems.id),
            ),
          ])
          ..addColumns([count])
          ..groupBy([_db.savedItems.id])
          ..having(count.equals(0));
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(_db.savedItems)).toList(),
    );
  }
}
