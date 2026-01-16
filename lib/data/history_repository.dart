import 'package:drift/drift.dart';

import 'app_database.dart';

class HistoryRepository {
  HistoryRepository(this._db);

  final AppDatabase _db;

  Stream<List<HistoryRecord>> watchHistory() {
    final query =
        _db.select(_db.downloadJobs).join([
            innerJoin(
              _db.savedItems,
              _db.savedItems.id.equalsExp(_db.downloadJobs.savedItemId),
            ),
          ])
          ..where(
            _db.downloadJobs.status.isIn(['completed', 'failed', 'skipped']),
          )
          ..orderBy([
            OrderingTerm(
              expression: _db.downloadJobs.completedAt,
              mode: OrderingMode.desc,
            ),
            OrderingTerm(
              expression: _db.downloadJobs.startedAt,
              mode: OrderingMode.desc,
            ),
          ]);

    return query.watch().map(
      (rows) =>
          rows
              .map(
                (row) => HistoryRecord(
                  job: row.readTable(_db.downloadJobs),
                  item: row.readTable(_db.savedItems),
                ),
              )
              .toList(),
    );
  }
}

class HistoryRecord {
  const HistoryRecord({required this.job, required this.item});

  final DownloadJob job;
  final SavedItem item;
}
