import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/app_database.dart';
import 'data/logs_repository.dart';
import 'data/settings_repository.dart';
import 'features/import/import_page.dart';
import 'features/library/library_cubit.dart';
import 'features/library/library_page.dart';
import 'features/logs/logs_cubit.dart';
import 'features/logs/logs_page.dart';
import 'features/queue/queue_cubit.dart';
import 'features/queue/queue_page.dart';
import 'features/settings/settings_cubit.dart';
import 'features/settings/settings_page.dart';
import 'features/sync/sync_page.dart';
import 'navigation/app_section.dart';
import 'navigation/navigation_cubit.dart';
import 'ui/app_theme.dart';
import 'ui/components/app_button.dart';
import 'ui/components/app_scaffold.dart';

class App extends StatefulWidget {
  const App({super.key, this.database});

  final AppDatabase? database;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppDatabase _database;

  @override
  void initState() {
    super.initState();
    _database = widget.database ?? AppDatabase();
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _database),
        RepositoryProvider(
          create: (context) =>
              SettingsRepository(context.read<AppDatabase>()),
        ),
        RepositoryProvider(
          create: (context) => LogsRepository(context.read<AppDatabase>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => NavigationCubit()),
          BlocProvider(create: (_) => LibraryCubit()),
          BlocProvider(create: (_) => QueueCubit()),
          BlocProvider(
            create: (context) =>
                SettingsCubit(context.read<SettingsRepository>()),
          ),
          BlocProvider(
            create: (context) => LogsCubit(context.read<LogsRepository>()),
          ),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return MaterialApp(
              title: 'reddit-dl',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: state.settings.themeModeValue,
              debugShowCheckedModeBanner: false,
              home: const AppShell(),
            );
          },
        ),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, AppSection>(
      builder: (context, section) {
        return Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyO):
                const OpenImportIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO):
                const OpenImportIntent(),
            LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyR):
                const RunSyncIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR):
                const RunSyncIntent(),
            LogicalKeySet(LogicalKeyboardKey.space): const TogglePauseIntent(),
          },
          child: Actions(
            actions: {
              OpenImportIntent: CallbackAction<OpenImportIntent>(
                onInvoke: (intent) {
                  context.read<NavigationCubit>().select(AppSection.import);
                  return null;
                },
              ),
              RunSyncIntent: CallbackAction<RunSyncIntent>(
                onInvoke: (intent) {
                  context.read<NavigationCubit>().select(AppSection.sync);
                  return null;
                },
              ),
              TogglePauseIntent: CallbackAction<TogglePauseIntent>(
                onInvoke: (intent) {
                  context.read<QueueCubit>().togglePauseAll();
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: AppScaffold(
                section: section,
                title: section.label,
                actions: _buildActions(context, section),
                onSectionSelected: context.read<NavigationCubit>().select,
                child: _buildPage(section),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildActions(BuildContext context, AppSection section) {
    switch (section) {
      case AppSection.library:
        return [
          AppButton(
            label: 'Import ZIP',
            onPressed: () =>
                context.read<NavigationCubit>().select(AppSection.import),
          ),
          AppButton(
            label: 'Sync',
            variant: AppButtonVariant.secondary,
            onPressed: () =>
                context.read<NavigationCubit>().select(AppSection.sync),
          ),
        ];
      case AppSection.queue:
        return [
          AppButton(
            label: 'Pause',
            variant: AppButtonVariant.secondary,
            onPressed: () => context.read<QueueCubit>().togglePauseAll(),
          ),
        ];
      case AppSection.import:
        return [
          AppButton(
            label: 'Open library',
            variant: AppButtonVariant.secondary,
            onPressed: () =>
                context.read<NavigationCubit>().select(AppSection.library),
          ),
        ];
      case AppSection.sync:
        return [
          AppButton(
            label: 'Open queue',
            variant: AppButtonVariant.secondary,
            onPressed: () =>
                context.read<NavigationCubit>().select(AppSection.queue),
          ),
        ];
      case AppSection.logs:
        return [
          AppButton(
            label: 'Copy logs',
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
        ];
      case AppSection.settings:
        return [
          AppButton(
            label: 'Reset defaults',
            variant: AppButtonVariant.ghost,
            onPressed: () {},
          ),
        ];
    }
  }

  Widget _buildPage(AppSection section) {
    switch (section) {
      case AppSection.library:
        return const LibraryPage();
      case AppSection.queue:
        return const QueuePage();
      case AppSection.logs:
        return const LogsPage();
      case AppSection.import:
        return const ImportPage();
      case AppSection.sync:
        return const SyncPage();
      case AppSection.settings:
        return const SettingsPage();
    }
  }
}

class OpenImportIntent extends Intent {
  const OpenImportIntent();
}

class RunSyncIntent extends Intent {
  const RunSyncIntent();
}

class TogglePauseIntent extends Intent {
  const TogglePauseIntent();
}
