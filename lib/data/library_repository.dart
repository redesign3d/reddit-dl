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
