import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/theme_cubit.dart';
import 'features/import/import_page.dart';
import 'features/library/library_cubit.dart';
import 'features/library/library_page.dart';
import 'features/logs/logs_page.dart';
import 'features/queue/queue_cubit.dart';
import 'features/queue/queue_page.dart';
import 'features/settings/settings_page.dart';
import 'features/sync/sync_page.dart';
import 'navigation/app_section.dart';
import 'navigation/navigation_cubit.dart';
import 'ui/app_theme.dart';
import 'ui/components/app_button.dart';
import 'ui/components/app_scaffold.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => NavigationCubit()),
        BlocProvider(create: (_) => LibraryCubit()),
        BlocProvider(create: (_) => QueueCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          return MaterialApp(
            title: 'reddit-dl',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            debugShowCheckedModeBanner: false,
            home: const AppShell(),
          );
        },
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
                onSectionSelected:
                    context.read<NavigationCubit>().select,
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
