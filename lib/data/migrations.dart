import 'package:drift/drift.dart';

import 'app_database.dart';

MigrationStrategy buildMigrationStrategy(AppDatabase database) {
  return MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await ensureLogEntriesPrimaryKey(database);
      }
    },
    beforeOpen: (details) async {
      await database.customStatement('PRAGMA foreign_keys = ON');
      await ensureLogEntriesPrimaryKey(database);
    },
  );
}

Future<void> ensureLogEntriesPrimaryKey(AppDatabase database) async {
  final columns =
      await database.customSelect('PRAGMA table_info(log_entries)').get();
  if (columns.isEmpty) {
    return;
  }
  var hasPrimaryKey = false;
  for (final row in columns) {
    final name = row.data['name'] as String?;
    final pk = row.data['pk'] as int? ?? 0;
    if (name == 'id' && pk > 0) {
      hasPrimaryKey = true;
      break;
    }
  }
  if (hasPrimaryKey) {
    return;
  }

  await database.customStatement('''
CREATE TABLE log_entries_new (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER NOT NULL,
  scope TEXT NOT NULL,
  level TEXT NOT NULL,
  message TEXT NOT NULL,
  context_json TEXT,
  related_job_id INTEGER
)
''');
  await database.customStatement('''
INSERT INTO log_entries_new (
  id,
  timestamp,
  scope,
  level,
  message,
  context_json,
  related_job_id
) SELECT
  COALESCE(id, rowid),
  timestamp,
  scope,
  level,
  message,
  context_json,
  related_job_id
FROM log_entries
''');
  await database.customStatement('DROP TABLE log_entries');
  await database.customStatement(
    'ALTER TABLE log_entries_new RENAME TO log_entries',
  );
}
