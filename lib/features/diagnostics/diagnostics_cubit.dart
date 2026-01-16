import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/library_repository.dart';
import '../../data/logs_repository.dart';
import '../../data/session_repository.dart';
import '../../data/settings_repository.dart';
import '../../data/reddit_saved_listing_client.dart';
import '../../services/ffmpeg_runtime_manager.dart';
import '../../services/path_template_engine.dart';
import '../../services/tools/tool_detector.dart';
import '../logs/log_record.dart';

class DiagnosticsCubit extends Cubit<DiagnosticsState> {
  DiagnosticsCubit({
    required SettingsRepository settingsRepository,
    required SessionRepository sessionRepository,
    required LogsRepository logsRepository,
    required ToolDetector toolDetector,
    required FfmpegRuntimeManager ffmpegRuntime,
    required LibraryRepository libraryRepository,
  }) : _settingsRepository = settingsRepository,
       _sessionRepository = sessionRepository,
       _logsRepository = logsRepository,
       _toolDetector = toolDetector,
       _ffmpegRuntime = ffmpegRuntime,
       _libraryRepository = libraryRepository,
       super(DiagnosticsState.initial()) {
    refresh();
  }

  final SettingsRepository _settingsRepository;
  final SessionRepository _sessionRepository;
  final LogsRepository _logsRepository;
  final ToolDetector _toolDetector;
  final FfmpegRuntimeManager _ffmpegRuntime;
  final LibraryRepository _libraryRepository;

  Future<void> refresh() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    await _log('Starting diagnostics refresh.', level: 'info');
    try {
      final settings = await _settingsRepository.load();
      await _sessionRepository.initialize(remember: settings.rememberSession);

      final cookieStatus = await _checkCookies(settings);
      final sessionStatus = await _checkSession();
      final tools = await _checkTools(settings);
      final ffmpeg = await _checkFfmpeg();
      final templates = await _checkTemplates(settings);
      final hints = _platformHints();

      emit(
        DiagnosticsState(
          isLoading: false,
          lastUpdated: DateTime.now(),
          session: sessionStatus,
          cookies: cookieStatus,
          tools: tools,
          ffmpeg: ffmpeg,
          templates: templates,
          hints: hints,
          errorMessage: null,
        ),
      );
      await _log('Diagnostics refresh completed.', level: 'info');
    } catch (error) {
      await _log('Diagnostics refresh failed: $error', level: 'error');
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<CookieDiagnostics> _checkCookies(AppSettings settings) async {
    final persistence =
        settings.rememberSession
            ? CookiePersistence.persisted
            : CookiePersistence.ephemeral;
    final storagePath = await _sessionRepository.cookieStoragePath();
    final exists = await Directory(storagePath).exists();
    final detail =
        settings.rememberSession
            ? 'Persisted store ${exists ? 'found' : 'missing'} at $storagePath'
            : 'Ephemeral cookies (cleared on exit).';
    await _log(
      'Cookie storage: ${persistence.name}. $detail',
      level: settings.rememberSession && !exists ? 'warn' : 'info',
    );
    return CookieDiagnostics(
      persistence: persistence,
      storagePath: storagePath,
      storeExists: exists,
    );
  }

  Future<SessionDiagnostics> _checkSession() async {
    final client = RedditSavedListingClient(
      cookieJar: _sessionRepository.cookieJar,
    );
    try {
      final result = await client.checkSession();
      if (result.isValid) {
        await _log(
          'Session valid for ${result.username ?? 'unknown user'}.',
          level: 'info',
        );
        return SessionDiagnostics(
          level: DiagnosticsLevel.ok,
          isValid: true,
          username: result.username,
          message: 'Logged in to old.reddit.com.',
        );
      }
      await _log('Session expired or not logged in.', level: 'warn');
      return SessionDiagnostics(
        level: DiagnosticsLevel.warn,
        isValid: false,
        username: result.username,
        message: 'Session expired or not logged in.',
      );
    } on RateLimitException catch (error) {
      final retryAfter = error.retryAfterSeconds;
      await _log(
        'Session check rate limited (${retryAfter ?? 'unknown'}s).',
        level: 'warn',
      );
      return SessionDiagnostics(
        level: DiagnosticsLevel.warn,
        isValid: false,
        username: null,
        message: 'Rate limited. Retry after ${retryAfter ?? 10} seconds.',
      );
    } catch (error) {
      await _log('Session check failed: $error', level: 'error');
      return SessionDiagnostics(
        level: DiagnosticsLevel.error,
        isValid: false,
        username: null,
        message: 'Session check failed.',
      );
    }
  }

  Future<List<ToolDiagnostics>> _checkTools(AppSettings settings) async {
    final gallery = await _toolDetector.detect(
      'gallery-dl',
      overridePath: settings.galleryDlPathOverride,
    );
    final ytdlp = await _toolDetector.detect(
      'yt-dlp',
      overridePath: settings.ytDlpPathOverride,
    );

    final results = [
      ToolDiagnostics.fromToolInfo(gallery),
      ToolDiagnostics.fromToolInfo(ytdlp),
    ];
    for (final tool in results) {
      final level = tool.level == DiagnosticsLevel.ok ? 'info' : 'warn';
      await _log('Tool ${tool.name}: ${tool.summary}.', level: level);
    }
    return results;
  }

  Future<FfmpegDiagnostics> _checkFfmpeg() async {
    final status = await _ffmpegRuntime.status();
    final version =
        status.ffmpegPath == null
            ? null
            : await _ffmpegVersion(status.ffmpegPath!);
    final isInstalled = status.isInstalled && status.ffmpegPath != null;
    final level = isInstalled ? DiagnosticsLevel.ok : DiagnosticsLevel.warn;
    final message =
        isInstalled ? 'ffmpeg runtime installed.' : 'ffmpeg runtime missing.';
    await _log(
      'ffmpeg runtime: $message',
      level: isInstalled ? 'info' : 'warn',
    );
    return FfmpegDiagnostics(
      level: level,
      isInstalled: isInstalled,
      ffmpegPath: status.ffmpegPath,
      ffprobePath: status.ffprobePath,
      version: version,
    );
  }

  Future<TemplateDiagnostics> _checkTemplates(AppSettings settings) async {
    final root = settings.downloadRoot.trim();
    if (root.isEmpty) {
      await _log('Download root missing.', level: 'warn');
      return TemplateDiagnostics(
        level: DiagnosticsLevel.warn,
        rootPath: '',
        rootExists: false,
        previewPath: null,
        warnings: const ['Download root is not set.'],
        message: 'Download root is not set.',
      );
    }

    final rootExists = await Directory(root).exists();
    if (!rootExists) {
      await _log('Download root does not exist at $root.', level: 'warn');
    }

    final sample = await _libraryRepository.fetchLatest();
    if (sample == null) {
      await _log('No items available for template preview.', level: 'info');
      return TemplateDiagnostics(
        level: rootExists ? DiagnosticsLevel.ok : DiagnosticsLevel.warn,
        rootPath: root,
        rootExists: rootExists,
        previewPath: null,
        warnings: const ['Import ZIP or Sync to preview templates.'],
        message: 'No items available to preview templates.',
      );
    }

    final engine = PathTemplateEngine(settings);
    final preview = engine.previewForItem(sample);
    final warnings = [...preview.warnings];
    if (!preview.isValid && preview.error != null) {
      warnings.add(preview.error!);
    }
    if (warnings.isEmpty) {
      await _log('Template preview OK.', level: 'info');
    } else {
      await _log('Template warnings: ${warnings.join(' • ')}', level: 'warn');
    }

    return TemplateDiagnostics(
      level: warnings.isEmpty ? DiagnosticsLevel.ok : DiagnosticsLevel.warn,
      rootPath: root,
      rootExists: rootExists,
      previewPath: preview.filePath.isEmpty ? null : preview.filePath,
      warnings: warnings,
      message: warnings.isEmpty ? 'Template preview OK.' : warnings.first,
    );
  }

  List<PlatformHint> _platformHints() {
    final hints = <PlatformHint>[];
    if (Platform.isLinux) {
      hints.add(
        const PlatformHint(
          title: 'Linux WebView dependencies',
          message:
              'If login is blank, install WebKitGTK (e.g. libwebkit2gtk-4.1) and GTK3.',
        ),
      );
    }
    if (Platform.isWindows) {
      hints.add(
        const PlatformHint(
          title: 'Windows long paths',
          message:
              'Enable long paths in Group Policy if you hit MAX_PATH errors.',
        ),
      );
    }
    for (final hint in hints) {
      _logsRepository.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'diagnostics',
          level: 'info',
          message: '${hint.title}: ${hint.message}',
        ),
      );
    }
    return hints;
  }

  Future<String?> _ffmpegVersion(String path) async {
    try {
      final result = await Process.run(path, ['-version']);
      if (result.exitCode != 0) {
        return null;
      }
      final output = (result.stdout as String).trim();
      if (output.isEmpty) {
        return null;
      }
      return output.split(RegExp(r'\r?\n')).first;
    } catch (_) {
      return null;
    }
  }

  Future<void> _log(String message, {required String level}) {
    return _logsRepository.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: 'diagnostics',
        level: level,
        message: message,
      ),
    );
  }
}

class DiagnosticsState extends Equatable {
  const DiagnosticsState({
    required this.isLoading,
    required this.lastUpdated,
    required this.session,
    required this.cookies,
    required this.tools,
    required this.ffmpeg,
    required this.templates,
    required this.hints,
    required this.errorMessage,
  });

  factory DiagnosticsState.initial() {
    return DiagnosticsState(
      isLoading: true,
      lastUpdated: null,
      session: const SessionDiagnostics(
        level: DiagnosticsLevel.warn,
        isValid: false,
        username: null,
        message: 'Not checked yet.',
      ),
      cookies: const CookieDiagnostics(
        persistence: CookiePersistence.ephemeral,
        storagePath: '',
        storeExists: false,
      ),
      tools: const [],
      ffmpeg: const FfmpegDiagnostics(
        level: DiagnosticsLevel.warn,
        isInstalled: false,
        ffmpegPath: null,
        ffprobePath: null,
        version: null,
      ),
      templates: const TemplateDiagnostics(
        level: DiagnosticsLevel.warn,
        rootPath: '',
        rootExists: false,
        previewPath: null,
        warnings: [],
        message: 'Not checked yet.',
      ),
      hints: const [],
      errorMessage: null,
    );
  }

  final bool isLoading;
  final DateTime? lastUpdated;
  final SessionDiagnostics session;
  final CookieDiagnostics cookies;
  final List<ToolDiagnostics> tools;
  final FfmpegDiagnostics ffmpeg;
  final TemplateDiagnostics templates;
  final List<PlatformHint> hints;
  final String? errorMessage;

  DiagnosticsState copyWith({
    bool? isLoading,
    DateTime? lastUpdated,
    SessionDiagnostics? session,
    CookieDiagnostics? cookies,
    List<ToolDiagnostics>? tools,
    FfmpegDiagnostics? ffmpeg,
    TemplateDiagnostics? templates,
    List<PlatformHint>? hints,
    String? errorMessage,
  }) {
    return DiagnosticsState(
      isLoading: isLoading ?? this.isLoading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      session: session ?? this.session,
      cookies: cookies ?? this.cookies,
      tools: tools ?? this.tools,
      ffmpeg: ffmpeg ?? this.ffmpeg,
      templates: templates ?? this.templates,
      hints: hints ?? this.hints,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    lastUpdated,
    session,
    cookies,
    tools,
    ffmpeg,
    templates,
    hints,
    errorMessage,
  ];
}

enum DiagnosticsLevel { ok, warn, error }

class SessionDiagnostics extends Equatable {
  const SessionDiagnostics({
    required this.level,
    required this.isValid,
    required this.username,
    required this.message,
  });

  final DiagnosticsLevel level;
  final bool isValid;
  final String? username;
  final String message;

  @override
  List<Object?> get props => [level, isValid, username, message];
}

enum CookiePersistence { ephemeral, persisted }

class CookieDiagnostics extends Equatable {
  const CookieDiagnostics({
    required this.persistence,
    required this.storagePath,
    required this.storeExists,
  });

  final CookiePersistence persistence;
  final String storagePath;
  final bool storeExists;

  @override
  List<Object?> get props => [persistence, storagePath, storeExists];
}

class ToolDiagnostics extends Equatable {
  const ToolDiagnostics({
    required this.name,
    required this.level,
    required this.summary,
    required this.path,
    required this.version,
    required this.isOverride,
  });

  factory ToolDiagnostics.fromToolInfo(ToolInfo info) {
    final available = info.isAvailable;
    final summary =
        available
            ? 'Detected${info.isOverride ? ' (override)' : ''}'
            : (info.errorMessage ?? 'Not available');
    return ToolDiagnostics(
      name: info.name,
      level: available ? DiagnosticsLevel.ok : DiagnosticsLevel.warn,
      summary: summary,
      path: info.path,
      version: info.version,
      isOverride: info.isOverride,
    );
  }

  final String name;
  final DiagnosticsLevel level;
  final String summary;
  final String? path;
  final String? version;
  final bool isOverride;

  @override
  List<Object?> get props => [name, level, summary, path, version, isOverride];
}

class FfmpegDiagnostics extends Equatable {
  const FfmpegDiagnostics({
    required this.level,
    required this.isInstalled,
    required this.ffmpegPath,
    required this.ffprobePath,
    required this.version,
  });

  final DiagnosticsLevel level;
  final bool isInstalled;
  final String? ffmpegPath;
  final String? ffprobePath;
  final String? version;

  @override
  List<Object?> get props => [
    level,
    isInstalled,
    ffmpegPath,
    ffprobePath,
    version,
  ];
}

class TemplateDiagnostics extends Equatable {
  const TemplateDiagnostics({
    required this.level,
    required this.rootPath,
    required this.rootExists,
    required this.previewPath,
    required this.warnings,
    required this.message,
  });

  final DiagnosticsLevel level;
  final String rootPath;
  final bool rootExists;
  final String? previewPath;
  final List<String> warnings;
  final String message;

  @override
  List<Object?> get props => [
    level,
    rootPath,
    rootExists,
    previewPath,
    warnings,
    message,
  ];
}

class PlatformHint extends Equatable {
  const PlatformHint({required this.title, required this.message});

  final String title;
  final String message;

  @override
  List<Object?> get props => [title, message];
}
