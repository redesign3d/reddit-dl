import 'dart:convert';

import 'package:drift/drift.dart';

import '../features/sync/reddit_json_parser.dart';
import 'app_database.dart';

class SyncRepository {
  SyncRepository(this._db);

  final AppDatabase _db;

  Future<SyncUpsertResult> upsertResolved(ResolvedItem resolved) async {
    final existing = await (_db.select(_db.savedItems)
          ..where((tbl) => tbl.permalink.equals(resolved.permalink)))
        .getSingleOrNull();

    final now = DateTime.now();
    final author = _selectText(resolved.author, existing?.author ?? '');
    final subreddit = _selectText(resolved.subreddit, existing?.subreddit ?? '');
    final title = _selectText(resolved.title, existing?.title ?? '');
    final body = _selectText(
      resolved.body,
      existing?.bodyMarkdown ?? '',
    );
    final createdUtc =
        resolved.createdUtc > 0 ? resolved.createdUtc : (existing?.createdUtc ?? 0);
    final over18 = resolved.over18 || (existing?.over18 ?? false);
    final source = existing?.source == 'zip' ? 'zip' : 'sync';
    final resolutionStatus = _statusName(resolved.status);

    final companion = SavedItemsCompanion(
      id: const Value.absent(),
      permalink: Value(resolved.permalink),
      kind: Value(resolved.kind),
      subreddit: Value(subreddit),
      author: Value(author),
      createdUtc: Value(createdUtc),
      title: Value(title),
      bodyMarkdown: Value(body.isEmpty ? null : body),
      over18: Value(over18),
      source: Value(source),
      importedAt: Value(existing?.importedAt),
      syncedAt: Value(now),
      lastResolvedAt: Value(now),
      resolutionStatus: Value(resolutionStatus),
      rawJsonCache: const Value.absent(),
    );

    int savedItemId;
    var inserted = false;
    if (existing == null) {
      savedItemId = await _db.into(_db.savedItems).insert(companion);
      inserted = true;
    } else {
      await (_db.update(_db.savedItems)..where((tbl) => tbl.id.equals(existing.id)))
          .write(companion);
      savedItemId = existing.id;
    }

    final mediaInserted = await _insertMediaAssets(savedItemId, resolved.media);
    return SyncUpsertResult(
      inserted: inserted,
      updated: !inserted,
      mediaInserted: mediaInserted,
    );
  }

  Future<void> markResolutionFailed(String permalink) async {
    await (_db.update(_db.savedItems)
          ..where((tbl) => tbl.permalink.equals(permalink)))
        .write(
          SavedItemsCompanion(
            resolutionStatus: const Value('failed'),
            lastResolvedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<int> _insertMediaAssets(
    int savedItemId,
    List<ResolvedMediaAsset> assets,
  ) async {
    if (assets.isEmpty) {
      return 0;
    }

    final existing = await (_db.select(_db.mediaAssets)
          ..where((tbl) => tbl.savedItemId.equals(savedItemId)))
        .get();
    final existingSet = existing.map((row) => row.normalizedUrl).toSet();

    final inserts = <MediaAssetsCompanion>[];
    for (final asset in assets) {
      if (asset.normalizedUrl.isEmpty || existingSet.contains(asset.normalizedUrl)) {
        continue;
      }
      existingSet.add(asset.normalizedUrl);
      inserts.add(
        MediaAssetsCompanion.insert(
          savedItemId: savedItemId,
          type: asset.type,
          sourceUrl: asset.sourceUrl,
          normalizedUrl: asset.normalizedUrl,
          toolHint: asset.toolHint,
          filenameSuggested: const Value.absent(),
          metadataJson: asset.metadata == null
              ? const Value.absent()
              : Value(jsonEncode(asset.metadata)),
        ),
      );
    }

    if (inserts.isEmpty) {
      return 0;
    }

    await _db.batch((batch) {
      batch.insertAll(_db.mediaAssets, inserts);
    });

    return inserts.length;
  }

  String _selectText(String incoming, String fallback) {
    if (incoming.isNotEmpty && incoming.toLowerCase() != 'unknown') {
      return incoming;
    }
    return fallback;
  }

  String _statusName(ResolutionStatus status) {
    switch (status) {
      case ResolutionStatus.ok:
        return 'ok';
      case ResolutionStatus.partial:
        return 'partial';
      case ResolutionStatus.failed:
        return 'failed';
    }
  }
}

class SyncUpsertResult {
  const SyncUpsertResult({
    required this.inserted,
    required this.updated,
    required this.mediaInserted,
  });

  final bool inserted;
  final bool updated;
  final int mediaInserted;
}
