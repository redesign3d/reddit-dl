import 'package:drift/drift.dart';

import 'app_database.dart';

class LibraryRepository {
  LibraryRepository(this._db);

  final AppDatabase _db;

  Stream<List<SavedItem>> watchLibraryPage({
    required LibraryQueryFilters filters,
    required int limit,
    required int offset,
  }) {
    final normalizedLimit = limit < 1 ? 1 : limit;
    final normalizedOffset = offset < 0 ? 0 : offset;
    final query = _db.select(_db.savedItems)
      ..where((tbl) => _buildFilterExpression(tbl, filters))
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdUtc, mode: OrderingMode.desc),
        (row) => OrderingTerm(expression: row.id, mode: OrderingMode.desc),
      ])
      ..limit(normalizedLimit, offset: normalizedOffset);
    return query.watch();
  }

  Future<Map<int, int>> fetchMediaCountsForSavedItemIds(
    Iterable<int> savedItemIds,
  ) async {
    final ids = savedItemIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const <int, int>{};
    }
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _db.customSelect(
      '''
SELECT saved_item_id, COUNT(*) AS media_count
FROM media_assets
WHERE saved_item_id IN ($placeholders)
GROUP BY saved_item_id
''',
      variables: ids.map((id) => Variable<int>(id)).toList(growable: false),
    ).get();
    final counts = <int, int>{};
    for (final row in rows) {
      final savedItemId = row.read<int>('saved_item_id');
      final count = row.read<int>('media_count');
      counts[savedItemId] = count;
    }
    return counts;
  }

  Future<Map<int, String>> fetchLatestDownloadStatusForSavedItemIds(
    Iterable<int> savedItemIds,
  ) async {
    final ids = savedItemIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const <int, String>{};
    }
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _db.customSelect(
      '''
SELECT job.saved_item_id, job.status
FROM download_jobs AS job
INNER JOIN (
  SELECT saved_item_id, MAX(id) AS max_id
  FROM download_jobs
  WHERE saved_item_id IN ($placeholders)
  GROUP BY saved_item_id
) AS latest ON latest.max_id = job.id
''',
      variables: ids.map((id) => Variable<int>(id)).toList(growable: false),
    ).get();
    final statuses = <int, String>{};
    for (final row in rows) {
      final savedItemId = row.read<int>('saved_item_id');
      final status = row.read<String>('status');
      if (status.isNotEmpty) {
        statuses[savedItemId] = status;
      }
    }
    return statuses;
  }

  Future<int> countLibrary(LibraryQueryFilters filters) {
    final countExpr = _db.savedItems.id.count();
    final query = _db.selectOnly(_db.savedItems)
      ..addColumns([countExpr])
      ..where(_buildFilterExpression(_db.savedItems, filters));
    return query.map((row) => row.read(countExpr) ?? 0).getSingle();
  }

  Stream<List<SavedItem>> watchAll() {
    final query = _db.select(_db.savedItems)
      ..orderBy([
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
    final query = _db.select(_db.savedItems)
      ..orderBy([
        (row) =>
            OrderingTerm(expression: row.createdUtc, mode: OrderingMode.desc),
      ])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Stream<List<SavedItem>> watchItemsWithoutMedia() {
    final query = _db.select(_db.savedItems).join([
      leftOuterJoin(
        _db.mediaAssets,
        _db.mediaAssets.savedItemId.equalsExp(_db.savedItems.id),
      ),
    ])..where(_db.mediaAssets.id.isNull());
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(_db.savedItems)).toList(),
    );
  }

  Expression<bool> _buildFilterExpression(
    $SavedItemsTable tbl,
    LibraryQueryFilters filters,
  ) {
    Expression<bool> expression = const Constant(true);
    final searchQuery = filters.searchQuery.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      final pattern = '%$searchQuery%';
      final searchExpression =
          tbl.title.lower().like(pattern) |
          (tbl.bodyMarkdown.isNotNull() &
              tbl.bodyMarkdown.lower().like(pattern)) |
          tbl.author.lower().like(pattern) |
          tbl.subreddit.lower().like(pattern) |
          tbl.permalink.lower().like(pattern);
      expression = expression & searchExpression;
    }

    if (filters.subreddit != null && filters.subreddit!.isNotEmpty) {
      expression = expression & tbl.subreddit.equals(filters.subreddit!);
    }

    if (filters.excludedSubreddit != null &&
        filters.excludedSubreddit!.isNotEmpty) {
      expression =
          expression & tbl.subreddit.isNotValue(filters.excludedSubreddit!);
    }

    if (!filters.includeNsfw) {
      expression = expression & tbl.over18.equals(false);
    }

    switch (filters.kind) {
      case LibraryItemKind.all:
        break;
      case LibraryItemKind.post:
        expression = expression & tbl.kind.equals('post');
        break;
      case LibraryItemKind.comment:
        expression = expression & tbl.kind.equals('comment');
        break;
      case LibraryItemKind.media:
        final mediaQuery = _db.selectOnly(_db.mediaAssets)
          ..addColumns([_db.mediaAssets.id])
          ..where(_db.mediaAssets.savedItemId.equalsExp(tbl.id))
          ..limit(1);
        expression = expression & existsQuery(mediaQuery);
        break;
    }

    if (filters.resolutionStatus != LibraryResolutionFilter.all) {
      expression =
          expression &
          tbl.resolutionStatus.equals(filters.resolutionStatus.name);
    }

    return expression;
  }
}

enum LibraryItemKind { all, post, comment, media }

enum LibraryResolutionFilter { all, ok, partial, failed }

class LibraryQueryFilters {
  const LibraryQueryFilters({
    this.searchQuery = '',
    this.subreddit,
    this.excludedSubreddit,
    this.kind = LibraryItemKind.all,
    this.includeNsfw = true,
    this.resolutionStatus = LibraryResolutionFilter.all,
  });

  final String searchQuery;
  final String? subreddit;
  final String? excludedSubreddit;
  final LibraryItemKind kind;
  final bool includeNsfw;
  final LibraryResolutionFilter resolutionStatus;
}
