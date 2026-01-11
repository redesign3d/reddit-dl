import 'package:drift/drift.dart';

import 'app_database.dart';

MigrationStrategy buildMigrationStrategy(AppDatabase database) {
  return MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from == 1) {
        // Future migrations go here.
      }
    },
    beforeOpen: (details) async {
      await database.customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
