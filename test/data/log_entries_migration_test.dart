import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/migrations.dart';

void main() {
  test('ensureLogEntriesPrimaryKey rebuilds missing primary key', () async {
    final database = AppDatabase.inMemory();
    addTearDown(() => database.close());

    await database.customStatement('DROP TABLE log_entries');
    await database.customStatement('''
CREATE TABLE log_entries (
  id INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  scope TEXT NOT NULL,
  level TEXT NOT NULL,
  message TEXT NOT NULL,
  context_json TEXT,
  related_job_id INTEGER
)
''');

    await ensureLogEntriesPrimaryKey(database);

    await database
        .into(database.logEntries)
        .insert(
          LogEntriesCompanion.insert(
            timestamp: DateTime.now(),
            scope: 'import',
            level: 'info',
            message: 'Test insert',
          ),
        );

    final columns =
        await database.customSelect('PRAGMA table_info(log_entries)').get();
    final idColumn = columns.firstWhere((row) => row.data['name'] == 'id');
    expect((idColumn.data['pk'] as int?) ?? 0, greaterThan(0));
  });
}
