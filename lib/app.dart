import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';

import 'data/app_database.dart';
import 'data/import_repository.dart';
import 'data/history_repository.dart';
import 'data/library_repository.dart';
import 'data/logs_repository.dart';
import 'data/queue_repository.dart';
import 'data/session_repository.dart';
import 'data/settings_repository.dart';
import 'data/sync_repository.dart';
import 'features/import/import_cubit.dart';
import 'features/import/import_page.dart';
import 'features/import/zip_import_parser.dart';
import 'features/history/history_cubit.dart';
import 'features/history/history_page.dart';
import 'features/library/library_cubit.dart';
import 'features/library/library_page.dart';
import 'features/logs/logs_cubit.dart';
import 'features/logs/logs_page.dart';
import 'features/queue/queue_cubit.dart';
import 'features/queue/queue_page.dart';
import 'features/settings/settings_cubit.dart';
import 'features/settings/settings_page.dart';
import 'features/sync/sync_cubit.dart';
import 'features/sync/sync_page.dart';
import 'features/wanted/wanted_cubit.dart';
import 'features/wanted/wanted_page.dart';
import 'features/tools/tools_cubit.dart';
import 'features/ffmpeg/ffmpeg_cubit.dart';
import 'navigation/app_section.dart';
import 'navigation/navigation_cubit.dart';
import 'ui/app_theme.dart';
import 'ui/components/app_button.dart';
import 'ui/components/app_scaffold.dart';
import 'ui/components/app_toast.dart';
import 'services/download/download_scheduler.dart';
import 'services/download/download_telemetry.dart';
import 'services/ffmpeg_runtime_manager.dart';
import 'services/tools/external_tool_runner.dart';
import 'services/tools/tool_detector.dart';
import 'services/tray_controller.dart';
import 'features/diagnostics/diagnostics_cubit.dart';
import 'features/diagnostics/diagnostics_page.dart';

class App extends StatefulWidget {
  const App({super.key, this.database});

  final AppDatabase? database;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppDatabase _database;
  late final SettingsRepository _settingsRepository;
  late final LogsRepository _logsRepository;
  late final QueueRepository _queueRepository;
  late final SessionRepository _sessionRepository;
  late final DownloadTelemetry _downloadTelemetry;
  late final DownloadScheduler _downloadScheduler;

  @override
  void initState() {
    super.initState();
    _database = widget.database ?? AppDatabase();
    _settingsRepository = SettingsRepository(_database);
    _logsRepository = LogsRepository(_database);
    _queueRepository = QueueRepository(_database);
    _sessionRepository = SessionRepository();
    _downloadTelemetry = DownloadTelemetry();
    _downloadScheduler = DownloadScheduler(
      queueRepository: _queueRepository,
      settingsRepository: _settingsRepository,
      logsRepository: _logsRepository,
      sessionRepository: _sessionRepository,
      telemetry: _downloadTelemetry,
    );
    _downloadScheduler.start();
  }

  @override
  void dispose() {
    _downloadScheduler.dispose();
    _downloadTelemetry.dispose();
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _database),
        RepositoryProvider.value(value: _settingsRepository),
        RepositoryProvider.value(value: _logsRepository),
        RepositoryProvider(
          create: (context) =>
              ImportRepository(context.read<AppDatabase>(), ZipImportParser()),
        ),
        RepositoryProvider(
          create: (context) => LibraryRepository(context.read<AppDatabase>()),
        ),
        RepositoryProvider(
          create: (context) => HistoryRepository(context.read<AppDatabase>()),
        ),
        RepositoryProvider.value(value: _queueRepository),
        RepositoryProvider.value(value: _sessionRepository),
        RepositoryProvider(
          create: (context) => SyncRepository(context.read<AppDatabase>()),
        ),
        RepositoryProvider(create: (_) => FfmpegRuntimeManager()),
        RepositoryProvider(create: (_) => ToolDetector()),
        RepositoryProvider(
          create: (context) =>
              ExternalToolRunner(context.read<LogsRepository>()),
        ),
        RepositoryProvider.value(value: _downloadTelemetry),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => NavigationCubit()),
          BlocProvider(
            create: (context) =>
                LibraryCubit(context.read<LibraryRepository>()),
          ),
          BlocProvider(
            create: (context) => QueueCubit(
              context.read<QueueRepository>(),
              context.read<LogsRepository>(),
              context.read<SettingsRepository>(),
              context.read<DownloadTelemetry>(),
            ),
          ),
          BlocProvider(
            create: (context) => ImportCubit(
              context.read<ImportRepository>(),
              context.read<LogsRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                SettingsCubit(context.read<SettingsRepository>()),
          ),
          BlocProvider(
            create: (context) => LogsCubit(context.read<LogsRepository>()),
          ),
          BlocProvider(
            create: (context) => SyncCubit(
              context.read<SessionRepository>(),
              context.read<SyncRepository>(),
              context.read<LogsRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) =>
                HistoryCubit(context.read<HistoryRepository>()),
          ),
          BlocProvider(
            create: (context) => WantedCubit(
              queueRepository: context.read<QueueRepository>(),
              libraryRepository: context.read<LibraryRepository>(),
              settingsRepository: context.read<SettingsRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ToolsCubit(
              context.read<SettingsRepository>(),
              context.read<LogsRepository>(),
              context.read<ToolDetector>(),
              context.read<ExternalToolRunner>(),
            ),
          ),
          BlocProvider(
            create: (context) => FfmpegCubit(
              context.read<FfmpegRuntimeManager>(),
              context.read<LogsRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => DiagnosticsCubit(
              settingsRepository: context.read<SettingsRepository>(),
              sessionRepository: context.read<SessionRepository>(),
              logsRepository: context.read<LogsRepository>(),
              toolDetector: context.read<ToolDetector>(),
              ffmpegRuntime: context.read<FfmpegRuntimeManager>(),
              libraryRepository: context.read<LibraryRepository>(),
            ),
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

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  TrayController? _trayController;

  @override
  void initState() {
    super.initState();
    _trayController = TrayController(
      onPauseAll: () => context.read<QueueCubit>().pauseAll(),
      onResumeAll: () => context.read<QueueCubit>().resumeAll(),
      onQuit: () => windowManager.destroy(),
      onFirstHide: () async {
        if (!mounted) {
          return;
        }
        AppToast.show(context, 'App is still running in the tray.');
      },
    );
    unawaited(_trayController!.init());
  }

  @override
  void dispose() {
    _trayController?.dispose();
    super.dispose();
  }

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
      case AppSection.history:
        return [];
      case AppSection.wanted:
        return [];
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
            onPressed: () async {
              final logs = await context.read<LogsRepository>().fetchAll();
              if (!context.mounted) {
                return;
              }
              final text = logs
                  .map(
                    (entry) =>
                        '${entry.timestamp.toIso8601String()} [${entry.level}] ${entry.scope}: ${entry.message}',
                  )
                  .join('\n');
              Clipboard.setData(ClipboardData(text: text));
              AppToast.show(context, 'Logs copied.');
            },
          ),
        ];
      case AppSection.settings:
        return [
          AppButton(
            label: 'Reset defaults',
            variant: AppButtonVariant.ghost,
            onPressed: () => context.read<SettingsCubit>().updateSettings(
              AppSettings.defaults(),
            ),
          ),
        ];
      case AppSection.diagnostics:
        return [
          AppButton(
            label: 'Refresh',
            variant: AppButtonVariant.secondary,
            onPressed: () => context.read<DiagnosticsCubit>().refresh(),
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
      case AppSection.history:
        return const HistoryPage();
      case AppSection.wanted:
        return const WantedPage();
      case AppSection.logs:
        return const LogsPage();
      case AppSection.import:
        return const ImportPage();
      case AppSection.sync:
        return const SyncPage();
      case AppSection.diagnostics:
        return const DiagnosticsPage();
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
