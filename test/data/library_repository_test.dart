import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/library_repository.dart';

void main() {
  test(
    'watchLibraryPage applies text, subreddit, kind, nsfw, and resolution filters',
    () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());
      final repository = LibraryRepository(db);

      await _insertSavedItem(
        db,
        permalink: 'https://www.reddit.com/r/pics/comments/one/one',
        kind: 'post',
        subreddit: 'pics',
        author: 'alice',
        title: 'Sunset',
        bodyMarkdown: 'Nature',
        createdUtc: 1700000001,
        over18: false,
        resolutionStatus: 'ok',
      );
      final targetItemId = await _insertSavedItem(
        db,
        permalink: 'https://www.reddit.com/r/pics/comments/two/two',
        kind: 'comment',
        subreddit: 'pics',
        author: 'bob',
        title: 'Note',
        bodyMarkdown: 'Needle in haystack',
        createdUtc: 1700000002,
        over18: true,
        resolutionStatus: 'partial',
      );
      await _insertSavedItem(
        db,
        permalink: 'https://www.reddit.com/r/videos/comments/three/three',
        kind: 'post',
        subreddit: 'videos',
        author: 'carol',
        title: 'Video',
        bodyMarkdown: 'Clip',
        createdUtc: 1700000003,
        over18: false,
        resolutionStatus: 'ok',
      );

      final items = await repository
          .watchLibraryPage(
            filters: const LibraryQueryFilters(
              searchQuery: 'needle',
              subreddit: 'pics',
              kind: LibraryItemKind.comment,
              includeNsfw: true,
              resolutionStatus: LibraryResolutionFilter.partial,
            ),
            limit: 20,
            offset: 0,
          )
          .first;

      expect(items, hasLength(1));
      expect(items.single.id, targetItemId);

      final nsfwExcluded = await repository
          .watchLibraryPage(
            filters: const LibraryQueryFilters(
              searchQuery: 'needle',
              subreddit: 'pics',
              kind: LibraryItemKind.comment,
              includeNsfw: false,
              resolutionStatus: LibraryResolutionFilter.partial,
            ),
            limit: 20,
            offset: 0,
          )
          .first;
      expect(nsfwExcluded, isEmpty);
    },
  );

  test('watchLibraryPage filters media kind using media assets', () async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final repository = LibraryRepository(db);

    final withMediaId = await _insertSavedItem(
      db,
      permalink: 'https://www.reddit.com/r/videos/comments/media/one',
      kind: 'post',
      subreddit: 'videos',
      author: 'alice',
      title: 'Has media',
      bodyMarkdown: 'clip',
      createdUtc: 1700000001,
      over18: false,
      resolutionStatus: 'ok',
    );
    await db
        .into(db.mediaAssets)
        .insert(
          MediaAssetsCompanion.insert(
            savedItemId: withMediaId,
            type: 'video',
            sourceUrl: 'https://v.redd.it/abc/DASH_720.mp4',
            normalizedUrl: 'https://v.redd.it/abc/DASH_720.mp4',
            toolHint: 'none',
          ),
        );

    await _insertSavedItem(
      db,
      permalink: 'https://www.reddit.com/r/videos/comments/media/two',
      kind: 'post',
      subreddit: 'videos',
      author: 'bob',
      title: 'No media',
      bodyMarkdown: '',
      createdUtc: 1700000002,
      over18: false,
      resolutionStatus: 'ok',
    );

    final mediaItems = await repository
        .watchLibraryPage(
          filters: const LibraryQueryFilters(kind: LibraryItemKind.media),
          limit: 20,
          offset: 0,
        )
        .first;

    expect(mediaItems.map((item) => item.id), [withMediaId]);
  });

  test('watchLibraryPage paginates with limit and offset', () async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final repository = LibraryRepository(db);

    for (var index = 0; index < 5; index++) {
      await _insertSavedItem(
        db,
        permalink: 'https://www.reddit.com/r/test/comments/item/$index',
        kind: 'post',
        subreddit: 'test',
        author: 'user$index',
        title: 'Item $index',
        bodyMarkdown: '',
        createdUtc: 1700000000 + index,
        over18: false,
        resolutionStatus: 'ok',
      );
    }

    final firstPage = await repository
        .watchLibraryPage(
          filters: const LibraryQueryFilters(),
          limit: 2,
          offset: 0,
        )
        .first;
    final secondPage = await repository
        .watchLibraryPage(
          filters: const LibraryQueryFilters(),
          limit: 2,
          offset: 2,
        )
        .first;
    final total = await repository.countLibrary(const LibraryQueryFilters());

    expect(firstPage.map((item) => item.title).toList(), ['Item 4', 'Item 3']);
    expect(secondPage.map((item) => item.title).toList(), ['Item 2', 'Item 1']);
    expect(total, 5);
  });
}

Future<int> _insertSavedItem(
  AppDatabase db, {
  required String permalink,
  required String kind,
  required String subreddit,
  required String author,
  required String title,
  required String bodyMarkdown,
  required int createdUtc,
  required bool over18,
  required String resolutionStatus,
}) {
  return db
      .into(db.savedItems)
      .insert(
        SavedItemsCompanion.insert(
          permalink: permalink,
          kind: kind,
          subreddit: subreddit,
          author: author,
          createdUtc: createdUtc,
          title: title,
          bodyMarkdown: drift.Value(bodyMarkdown),
          over18: drift.Value(over18),
          source: 'sync',
          resolutionStatus: resolutionStatus,
        ),
      );
}
