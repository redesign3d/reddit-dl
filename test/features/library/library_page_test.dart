import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/library_repository.dart';
import 'package:reddit_dl/data/queue_repository.dart';
import 'package:reddit_dl/features/library/library_cubit.dart';
import 'package:reddit_dl/features/library/library_page.dart';

void main() {
  testWidgets('renders wide 3-pane layout controls', (tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final repository = LibraryRepository(db);

    await _pumpLibraryPage(
      tester,
      db: db,
      repository: repository,
      width: 1300,
      height: 900,
    );

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Select an item to view details.'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
  });

  testWidgets('renders narrow list mode with filters entry point', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final repository = LibraryRepository(db);

    await _pumpLibraryPage(
      tester,
      db: db,
      repository: repository,
      width: 860,
      height: 900,
    );

    expect(find.text('Search'), findsNothing);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('No items indexed yet.'), findsOneWidget);
  });

  testWidgets('wide layout selection updates details panel content', (
    tester,
  ) async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final repository = LibraryRepository(db);
    await _insertItem(
      db,
      permalink: 'https://www.reddit.com/r/test/comments/1/alpha',
      title: 'Alpha title',
      body: 'Alpha body preview',
    );
    await _insertItem(
      db,
      permalink: 'https://www.reddit.com/r/test/comments/2/beta',
      title: 'Beta title',
      body: 'Beta body preview',
    );

    await _pumpLibraryPage(
      tester,
      db: db,
      repository: repository,
      width: 1300,
      height: 900,
    );
    await tester.tap(find.text('Alpha title').first);
    await tester.pumpAndSettle();

    expect(find.text('Alpha body preview'), findsOneWidget);
  });
}

Future<void> _pumpLibraryPage(
  WidgetTester tester, {
  required AppDatabase db,
  required LibraryRepository repository,
  required double width,
  required double height,
}) async {
  final queueRepository = _StubQueueRepository(db);
  final cubit = LibraryCubit(repository);
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
    await tester.pump();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<QueueRepository>.value(value: queueRepository),
        ],
        child: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: LibraryPage()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _StubQueueRepository extends QueueRepository {
  _StubQueueRepository(super.db);

  @override
  Stream<List<QueueRecord>> watchQueue() =>
      Stream<List<QueueRecord>>.value(<QueueRecord>[]);
}

Future<void> _insertItem(
  AppDatabase db, {
  required String permalink,
  required String title,
  required String body,
}) async {
  await db
      .into(db.savedItems)
      .insert(
        SavedItemsCompanion.insert(
          permalink: permalink,
          kind: 'post',
          subreddit: 'test',
          author: 'author',
          createdUtc: 1700000000,
          title: title,
          bodyMarkdown: drift.Value(body),
          source: 'sync',
          resolutionStatus: 'ok',
        ),
      );
}
