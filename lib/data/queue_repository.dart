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
    ])..orderBy([_fifoOrdering()]);

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

  Future<QueueEnqueueResult> enqueueForItem(
    SavedItem item, {
    required String policySnapshot,
  }) async {
    final existing =
        await (_db.select(_db.downloadJobs)..where(
              (tbl) =>
                  tbl.savedItemId.equals(item.id) &
                  tbl.status.isIn(['queued', 'running', 'paused']),
            ))
            .getSingleOrNull();
    if (existing != null) {
      return QueueEnqueueResult(created: false, job: existing);
    }

    final jobId = await _db
        .into(_db.downloadJobs)
        .insert(
          DownloadJobsCompanion.insert(
            savedItemId: item.id,
            status: 'queued',
            policySnapshot: policySnapshot,
            outputPath: 'pending',
          ),
        );

    final job = await (_db.select(
      _db.downloadJobs,
    )..where((tbl) => tbl.id.equals(jobId))).getSingle();

    return QueueEnqueueResult(created: true, job: job);
  }

  Future<List<QueueRecord>> fetchQueuedRecords(int limit) async {
    final query =
        _db.select(_db.downloadJobs).join([
            innerJoin(
              _db.savedItems,
              _db.savedItems.id.equalsExp(_db.downloadJobs.savedItemId),
            ),
          ])
          ..where(_db.downloadJobs.status.equals('queued'))
          ..orderBy([_fifoOrdering()])
          ..limit(limit);

    final rows = await query.get();
    return rows
        .map(
          (row) => QueueRecord(
            job: row.readTable(_db.downloadJobs),
            item: row.readTable(_db.savedItems),
          ),
        )
        .toList();
  }

  Future<List<MediaAsset>> fetchMediaAssets(int savedItemId) {
    return (_db.select(
      _db.mediaAssets,
    )..where((tbl) => tbl.savedItemId.equals(savedItemId))).get();
  }

  Future<void> markJobRunning(int jobId) async {
    await (_db.update(
      _db.downloadJobs,
    )..where((tbl) => tbl.id.equals(jobId))).write(
      DownloadJobsCompanion(
        status: const Value('running'),
        startedAt: Value(DateTime.now()),
        lastError: const Value.absent(),
      ),
    );
  }

  Future<void> updateJobStatus(int jobId, String status) async {
    await (_db.update(_db.downloadJobs)..where((tbl) => tbl.id.equals(jobId)))
        .write(DownloadJobsCompanion(status: Value(status)));
  }

  Future<void> updateJobProgress(int jobId, double progress) async {
    await (_db.update(_db.downloadJobs)..where((tbl) => tbl.id.equals(jobId)))
        .write(DownloadJobsCompanion(progress: Value(progress)));
  }

  Future<void> markJobCompleted(int jobId, String outputPath) async {
    await (_db.update(
      _db.downloadJobs,
    )..where((tbl) => tbl.id.equals(jobId))).write(
      DownloadJobsCompanion(
        status: const Value('completed'),
        progress: const Value(1),
        outputPath: Value(outputPath),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markJobFailed(int jobId, String error) async {
    await (_db.update(
      _db.downloadJobs,
    )..where((tbl) => tbl.id.equals(jobId))).write(
      DownloadJobsCompanion(
        status: const Value('failed'),
        lastError: Value(error),
      ),
    );
  }

  Future<void> markJobSkipped(int jobId, String reason) async {
    await (_db.update(
      _db.downloadJobs,
    )..where((tbl) => tbl.id.equals(jobId))).write(
      DownloadJobsCompanion(
        status: const Value('skipped'),
        progress: const Value(1),
        lastError: Value(reason),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> pauseJob(int jobId) async {
    await (_db.update(_db.downloadJobs)..where((tbl) => tbl.id.equals(jobId)))
        .write(const DownloadJobsCompanion(status: Value('paused')));
  }

  Future<void> resumeJob(int jobId) async {
    await (_db.update(_db.downloadJobs)..where((tbl) => tbl.id.equals(jobId)))
        .write(const DownloadJobsCompanion(status: Value('queued')));
  }

  Future<void> retryJob(int jobId) async {
    await (_db.update(
      _db.downloadJobs,
    )..where((tbl) => tbl.id.equals(jobId))).write(
      DownloadJobsCompanion(
        status: const Value('queued'),
        progress: const Value(0),
        lastError: const Value.absent(),
      ),
    );
  }

  Future<void> incrementAttempts(int jobId) async {
    final job = await (_db.select(
      _db.downloadJobs,
    )..where((tbl) => tbl.id.equals(jobId))).getSingle();
    await (_db.update(_db.downloadJobs)..where((tbl) => tbl.id.equals(jobId)))
        .write(DownloadJobsCompanion(attempts: Value(job.attempts + 1)));
  }

  Future<void> clearCompleted() async {
    final completedRows =
        await (_db.selectOnly(_db.downloadJobs)
              ..addColumns([_db.downloadJobs.id])
              ..where(_db.downloadJobs.status.equals('completed')))
            .get();
    final completedJobIds = completedRows
        .map((row) => row.read(_db.downloadJobs.id))
        .whereType<int>()
        .toList();
    if (completedJobIds.isEmpty) {
      return;
    }

    await _db.batch((batch) {
      batch.deleteWhere(
        _db.downloadOutputs,
        (tbl) => tbl.jobId.isIn(completedJobIds),
      );
      batch.deleteWhere(
        _db.downloadJobs,
        (tbl) => tbl.id.isIn(completedJobIds),
      );
    });
  }

  Future<void> pauseAll() async {
    await (_db.update(_db.downloadJobs)..where(
          (tbl) => tbl.status.isIn([
            'queued',
            'running',
            'merging',
            'running_tool',
            'exporting',
          ]),
        ))
        .write(const DownloadJobsCompanion(status: Value('paused')));
  }

  Future<void> resumeAll() async {
    await (_db.update(_db.downloadJobs)
          ..where((tbl) => tbl.status.equals('paused')))
        .write(const DownloadJobsCompanion(status: Value('queued')));
  }

  Future<int> markStuckJobsPaused(String reason) async {
    return (_db.update(_db.downloadJobs)..where(
          (tbl) => tbl.status.isIn([
            'running',
            'merging',
            'running_tool',
            'exporting',
          ]),
        ))
        .write(
          DownloadJobsCompanion(
            status: const Value('paused'),
            lastError: Value(reason),
          ),
        );
  }

  Future<void> recordJobOutput({
    required int jobId,
    required int savedItemId,
    required String path,
    required String kind,
  }) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      return;
    }
    await _db
        .into(_db.downloadOutputs)
        .insert(
          DownloadOutputsCompanion.insert(
            jobId: jobId,
            savedItemId: savedItemId,
            path: normalizedPath,
            kind: kind.trim().isEmpty ? 'unknown' : kind.trim(),
          ),
        );
  }

  Future<String?> fetchLatestOutputPathForJob(int jobId) async {
    final row =
        await (_db.select(_db.downloadOutputs)
              ..where((tbl) => tbl.jobId.equals(jobId))
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
                (tbl) =>
                    OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.path;
  }

  Future<String?> fetchLatestOutputPathForSavedItem(int savedItemId) async {
    final row =
        await (_db.select(_db.downloadOutputs)
              ..where((tbl) => tbl.savedItemId.equals(savedItemId))
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.createdAt,
                  mode: OrderingMode.desc,
                ),
                (tbl) =>
                    OrderingTerm(expression: tbl.id, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.path;
  }

  OrderingTerm _fifoOrdering() {
    // `download_jobs` has no explicit created timestamp; auto-increment id
    // provides stable FIFO ordering for queued jobs.
    return OrderingTerm(
      expression: _db.downloadJobs.id,
      mode: OrderingMode.asc,
    );
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
