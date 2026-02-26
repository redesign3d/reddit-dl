import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:drift/native.dart';

import 'migrations.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    SavedItems,
    MediaAssets,
    DownloadJobs,
    DownloadJobAssets,
    DownloadOutputs,
    LogEntries,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor})
    : super(executor ?? driftDatabase(name: 'reddit_dl'));

  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);
}

@TableIndex(name: 'saved_items_permalink', columns: {#permalink}, unique: true)
@TableIndex(name: 'saved_items_subreddit', columns: {#subreddit})
@TableIndex(name: 'saved_items_over18', columns: {#over18})
class SavedItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get permalink => text()();
  TextColumn get kind => text()();
  TextColumn get subreddit => text()();
  TextColumn get author => text()();
  IntColumn get createdUtc => integer()();
  TextColumn get title => text()();
  TextColumn get bodyMarkdown => text().nullable()();
  BoolColumn get over18 => boolean().withDefault(const Constant(false))();
  TextColumn get source => text()();
  DateTimeColumn get importedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  DateTimeColumn get lastResolvedAt => dateTime().nullable()();
  TextColumn get resolutionStatus => text()();
  TextColumn get rawJsonCache => text().nullable()();
}

class MediaAssets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get savedItemId => integer().references(SavedItems, #id)();
  TextColumn get type => text()();
  TextColumn get sourceUrl => text()();
  TextColumn get normalizedUrl => text()();
  TextColumn get toolHint => text()();
  TextColumn get filenameSuggested => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
}

@TableIndex(name: 'download_jobs_status', columns: {#status})
class DownloadJobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get savedItemId => integer().references(SavedItems, #id)();
  TextColumn get status => text()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get policySnapshot => text()();
  TextColumn get outputPath => text()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

@TableIndex(
  name: 'download_job_assets_job_asset',
  columns: {#jobId, #mediaAssetId},
  unique: true,
)
@TableIndex(name: 'download_job_assets_job_id', columns: {#jobId})
class DownloadJobAssets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get jobId => integer().references(DownloadJobs, #id)();
  IntColumn get mediaAssetId => integer().references(MediaAssets, #id)();
  TextColumn get url => text()();
  TextColumn get localTempPath => text()();
  TextColumn get expectedFinalPath => text()();
  TextColumn get etag => text().nullable()();
  TextColumn get lastModified => text().nullable()();
  IntColumn get totalBytes => integer().nullable()();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'download_outputs_job_id', columns: {#jobId})
@TableIndex(name: 'download_outputs_saved_item_id', columns: {#savedItemId})
class DownloadOutputs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get jobId => integer().references(DownloadJobs, #id)();
  IntColumn get savedItemId => integer().references(SavedItems, #id)();
  TextColumn get path => text()();
  TextColumn get kind => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class LogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get scope => text()();
  TextColumn get level => text()();
  TextColumn get message => text()();
  TextColumn get contextJson => text().nullable()();
  IntColumn get relatedJobId => integer().nullable()();
}

class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dataJson => text()();
  DateTimeColumn get updatedAt => dateTime()();
}
