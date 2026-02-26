import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/library_repository.dart';
import 'package:reddit_dl/features/library/library_cubit.dart';

void main() {
  test(
    'selection supports select all, toggle, clear, and visible retention',
    () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());
      final repository = LibraryRepository(db);
      await _insertItem(
        db,
        permalink: 'https://www.reddit.com/r/test/comments/1/alpha',
        title: 'Alpha title',
      );
      await _insertItem(
        db,
        permalink: 'https://www.reddit.com/r/test/comments/2/beta',
        title: 'Beta title',
      );

      final cubit = LibraryCubit(repository);
      addTearDown(() async => cubit.close());

      await _waitUntil(
        () => !cubit.state.isPageLoading && cubit.state.items.length == 2,
      );

      cubit.selectAllVisible();
      expect(cubit.state.selectedItemIds.length, 2);

      final firstVisibleId = cubit.state.items.first.id;
      cubit.toggleItemSelection(firstVisibleId, false);
      expect(cubit.state.selectedItemIds.contains(firstVisibleId), isFalse);

      cubit.clearSelection();
      expect(cubit.state.selectedItemIds, isEmpty);

      cubit.selectAllVisible();
      cubit.updateSearch('alpha');
      await _waitUntil(
        () => !cubit.state.isPageLoading && cubit.state.items.length == 1,
        timeout: const Duration(seconds: 3),
      );

      expect(cubit.state.selectedItemIds.length, 1);
      expect(cubit.state.selectedItemIds.single, cubit.state.items.single.id);
    },
  );

  test(
    'selected item id stays stable when selected item remains visible',
    () async {
      final db = AppDatabase.inMemory();
      addTearDown(() async => db.close());
      final repository = LibraryRepository(db);
      await _insertItem(
        db,
        permalink: 'https://www.reddit.com/r/test/comments/1/alpha',
        title: 'Alpha title',
      );
      await _insertItem(
        db,
        permalink: 'https://www.reddit.com/r/test/comments/2/beta',
        title: 'Beta title',
      );

      final cubit = LibraryCubit(repository);
      addTearDown(() async => cubit.close());
      await _waitUntil(
        () => !cubit.state.isPageLoading && cubit.state.items.length == 2,
      );

      final beta = cubit.state.items.firstWhere(
        (item) => item.title.contains('Beta'),
      );
      cubit.selectItem(beta.id);
      expect(cubit.state.selectedItemId, beta.id);

      cubit.updateSearch('beta');
      await _waitUntil(
        () => !cubit.state.isPageLoading && cubit.state.items.length == 1,
        timeout: const Duration(seconds: 3),
      );

      expect(cubit.state.selectedItemId, beta.id);
      expect(cubit.state.selectedItem?.id, beta.id);
    },
  );
}

Future<int> _insertItem(
  AppDatabase db, {
  required String permalink,
  required String title,
}) {
  return db
      .into(db.savedItems)
      .insert(
        SavedItemsCompanion.insert(
          permalink: permalink,
          kind: 'post',
          subreddit: 'test',
          author: 'author',
          createdUtc: 1700000000,
          title: title,
          bodyMarkdown: const drift.Value('body'),
          source: 'sync',
          resolutionStatus: 'ok',
        ),
      );
}

Future<void> _waitUntil(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final start = DateTime.now();
  while (!predicate()) {
    if (DateTime.now().difference(start) > timeout) {
      throw StateError('Timed out waiting for condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}
