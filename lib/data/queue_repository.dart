import 'package:drift/drift.dart';

import 'app_database.dart';

class QueueRepository {
  QueueRepository(this._db);

  final AppDatabase _db;

  Stream<List<QueueRecord>> watchQueue() {
    final query = _db.select(_db.downloadJobs).join([
      innerJoin(
        _db.savedItems,
        _db.savedItems.id.equalsExp(_db.downloadJobs.savedItemId),
      ),
    ])
      ..orderBy([
        OrderingTerm(expression: _db.downloadJobs.id, mode: OrderingMode.desc),
      ]);

    return query.watch().map(
          (rows) => rows
              .map(
                (row) => QueueRecord(
                  job: row.readTable(_db.downloadJobs),
                  item: row.readTable(_db.savedItems),
                ),
              )
              .toList(),
        );
  }

  Future<QueueEnqueueResult> enqueueForItem(SavedItem item) async {
    final existing = await (_db.select(_db.downloadJobs)
          ..where(
            (tbl) => tbl.savedItemId.equals(item.id) &
                tbl.status.isIn(['queued', 'running', 'paused']),
          ))
        .getSingleOrNull();
    if (existing != null) {
      return QueueEnqueueResult(created: false, job: existing);
    }

    final jobId = await _db.into(_db.downloadJobs).insert(
          DownloadJobsCompanion.insert(
            savedItemId: item.id,
            status: 'queued',
            policySnapshot: 'skip_if_exists',
            outputPath: 'pending',
          ),
        );

    final job = await (_db.select(_db.downloadJobs)
          ..where((tbl) => tbl.id.equals(jobId)))
        .getSingle();

    return QueueEnqueueResult(created: true, job: job);
  }

  Future<void> pauseJob(int jobId) async {
    await (_db.update(_db.downloadJobs)
          ..where((tbl) => tbl.id.equals(jobId)))
        .write(const DownloadJobsCompanion(status: Value('paused')));
  }

  Future<void> resumeJob(int jobId) async {
    await (_db.update(_db.downloadJobs)
          ..where((tbl) => tbl.id.equals(jobId)))
        .write(const DownloadJobsCompanion(status: Value('queued')));
  }

  Future<void> retryJob(int jobId) async {
    final job = await (_db.select(_db.downloadJobs)
          ..where((tbl) => tbl.id.equals(jobId)))
        .getSingle();
    await (_db.update(_db.downloadJobs)
          ..where((tbl) => tbl.id.equals(jobId)))
        .write(
          DownloadJobsCompanion(
            status: const Value('queued'),
            progress: const Value(0),
            lastError: const Value.absent(),
            attempts: Value(job.attempts + 1),
          ),
        );
  }

  Future<void> clearCompleted() async {
    await (_db.delete(_db.downloadJobs)
          ..where((tbl) => tbl.status.equals('completed')))
        .go();
  }

  Future<void> pauseAll() async {
    await (_db.update(_db.downloadJobs)
          ..where(
            (tbl) => tbl.status.isIn(['queued', 'running']),
          ))
        .write(const DownloadJobsCompanion(status: Value('paused')));
  }

  Future<void> resumeAll() async {
    await (_db.update(_db.downloadJobs)
          ..where((tbl) => tbl.status.equals('paused')))
        .write(const DownloadJobsCompanion(status: Value('queued')));
  }
}

class QueueRecord {
  const QueueRecord({required this.job, required this.item});

  final DownloadJob job;
  final SavedItem item;
}

class QueueEnqueueResult {
  const QueueEnqueueResult({required this.created, required this.job});

  final bool created;
  final DownloadJob job;
}
