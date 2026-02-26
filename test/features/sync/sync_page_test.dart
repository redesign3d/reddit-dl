import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/logs_repository.dart';
import 'package:reddit_dl/data/session_repository.dart';
import 'package:reddit_dl/data/settings_repository.dart';
import 'package:reddit_dl/data/sync_repository.dart';
import 'package:reddit_dl/features/settings/settings_cubit.dart';
import 'package:reddit_dl/features/sync/sync_cubit.dart';
import 'package:reddit_dl/features/sync/sync_page.dart';

void main() {
  testWidgets('sync stepper transitions by sync state', (tester) async {
    final db = AppDatabase.inMemory();
    addTearDown(() async => db.close());
    final syncCubit = TestSyncCubit(
      SessionRepository(),
      SyncRepository(db),
      LogsRepository(db),
    );
    final settingsCubit = SettingsCubit(SettingsRepository(db));
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await syncCubit.close();
      await settingsCubit.close();
      await tester.pump();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SyncCubit>.value(value: syncCubit),
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
        ],
        child: const MaterialApp(home: Scaffold(body: SyncPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1) Login'), findsOneWidget);

    syncCubit.setTestState(
      SyncState.initial().copyWith(
        phase: SyncPhase.ready,
        sessionValid: true,
        runStage: SyncRunStage.idle,
        username: const Value('alice'),
        sessionCookieCount: 2,
        savedAccessOk: const Value(true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2) Validate session'), findsOneWidget);

    syncCubit.setTestState(
      SyncState.initial().copyWith(
        phase: SyncPhase.syncing,
        runStage: SyncRunStage.scanning,
        sessionValid: true,
        username: const Value('alice'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3) Scan saved pages'), findsOneWidget);

    syncCubit.setTestState(
      SyncState.initial().copyWith(
        phase: SyncPhase.syncing,
        runStage: SyncRunStage.resolving,
        sessionValid: true,
        username: const Value('alice'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('4) Resolve JSON'), findsOneWidget);

    syncCubit.setTestState(
      SyncState.initial().copyWith(
        phase: SyncPhase.completed,
        runStage: SyncRunStage.completed,
        summary: Value(
          const SyncSummary(
            pagesScanned: 3,
            permalinksFound: 12,
            resolved: 11,
            upserted: 10,
            inserted: 4,
            updated: 6,
            failures: 1,
            mediaInserted: 9,
            insertedItemIds: [1, 2, 3, 4],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('5) Summary'), findsOneWidget);
  });
}

class TestSyncCubit extends SyncCubit {
  TestSyncCubit(super.sessionRepository, super.syncRepository, super.logs);

  void setTestState(SyncState value) {
    emit(value);
  }
}
