import 'package:drift/drift.dart';

import '../features/logs/log_record.dart';
import 'app_database.dart';

class LogsRepository {
  LogsRepository(this._db);

  final AppDatabase _db;

  Stream<List<LogRecord>> watchAll() {
    final query = _db.select(_db.logEntries)
      ..orderBy([
        (row) => OrderingTerm(expression: row.timestamp, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => LogRecord(
                  timestamp: row.timestamp,
                  scope: row.scope,
                  level: row.level,
                  message: row.message,
                ),
              )
              .toList(),
        );
  }

  Future<List<LogRecord>> fetchAll() async {
    final query = _db.select(_db.logEntries)
      ..orderBy([
        (row) => OrderingTerm(expression: row.timestamp, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows
        .map(
          (row) => LogRecord(
            timestamp: row.timestamp,
            scope: row.scope,
            level: row.level,
            message: row.message,
          ),
        )
        .toList();
  }

  Future<void> add(LogRecord entry) async {
    await _db.into(_db.logEntries).insert(
          LogEntriesCompanion.insert(
            timestamp: entry.timestamp,
            scope: entry.scope,
            level: entry.level,
            message: entry.message,
          ),
        );
  }

  Future<void> seedIfEmpty() async {
    final countExpression = _db.logEntries.id.count();
    final query = _db.selectOnly(_db.logEntries)..addColumns([countExpression]);
    final row = await query.getSingle();
    final count = row.read(countExpression) ?? 0;
    if (count > 0) {
      return;
    }
    final now = DateTime.now();
    final seeds = [
      LogRecord(
        timestamp: now.subtract(const Duration(minutes: 3)),
        scope: 'import',
        level: 'info',
        message: 'ZIP import parsed 152 saved items.',
      ),
      LogRecord(
        timestamp: now.subtract(const Duration(minutes: 2)),
        scope: 'resolve',
        level: 'warn',
        message: '429 received. Backing off for 60 seconds.',
      ),
      LogRecord(
        timestamp: now.subtract(const Duration(minutes: 1)),
        scope: 'download',
        level: 'info',
        message: 'Queued video merge for /r/analog/scan.',
      ),
      LogRecord(
        timestamp: now.subtract(const Duration(seconds: 20)),
        scope: 'download',
        level: 'error',
        message: 'ffmpeg unavailable; will download on next run.',
      ),
    ];
    await _db.batch((batch) {
      batch.insertAll(
        _db.logEntries,
        seeds
            .map(
              (entry) => LogEntriesCompanion.insert(
                timestamp: entry.timestamp,
                scope: entry.scope,
                level: entry.level,
                message: entry.message,
              ),
            )
            .toList(),
      );
    });
  }
}
