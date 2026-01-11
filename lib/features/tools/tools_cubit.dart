import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/logs_repository.dart';
import '../../data/settings_repository.dart';
import '../../services/tools/tool_detector.dart';
import '../logs/log_record.dart';

class ToolsCubit extends Cubit<ToolsState> {
  ToolsCubit(this._settingsRepository, this._logsRepository, this._detector)
      : super(const ToolsState.initial()) {
    _settingsSubscription = _settingsRepository.watch().listen(_handleSettings);
    refresh();
  }

  final SettingsRepository _settingsRepository;
  final LogsRepository _logsRepository;
  final ToolDetector _detector;
  StreamSubscription<AppSettings>? _settingsSubscription;

  String? _galleryOverride;
  String? _ytOverride;

  void _handleSettings(AppSettings settings) {
    final gallery = settings.galleryDlPathOverride;
    final yt = settings.ytDlpPathOverride;
    if (gallery != _galleryOverride || yt != _ytOverride) {
      _galleryOverride = gallery;
      _ytOverride = yt;
      refresh();
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final gallery = await _detector.detect(
        'gallery-dl',
        overridePath: _galleryOverride,
      );
      final ytDlp = await _detector.detect(
        'yt-dlp',
        overridePath: _ytOverride,
      );
      emit(state.copyWith(
        isLoading: false,
        galleryDl: gallery,
        ytDlp: ytDlp,
      ));
      await _logsRepository.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'tools',
          level: 'info',
          message: 'Tool scan complete.',
        ),
      );
    } catch (error) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      ));
      await _logsRepository.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'tools',
          level: 'error',
          message: 'Tool scan failed: $error',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _settingsSubscription?.cancel();
    return super.close();
  }
}

class ToolsState extends Equatable {
  const ToolsState({
    required this.isLoading,
    required this.galleryDl,
    required this.ytDlp,
    required this.errorMessage,
  });

  const ToolsState.initial()
      : isLoading = true,
        galleryDl = null,
        ytDlp = null,
        errorMessage = null;

  final bool isLoading;
  final ToolInfo? galleryDl;
  final ToolInfo? ytDlp;
  final String? errorMessage;

  ToolsState copyWith({
    bool? isLoading,
    ToolInfo? galleryDl,
    ToolInfo? ytDlp,
    String? errorMessage,
  }) {
    return ToolsState(
      isLoading: isLoading ?? this.isLoading,
      galleryDl: galleryDl ?? this.galleryDl,
      ytDlp: ytDlp ?? this.ytDlp,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, galleryDl, ytDlp, errorMessage];
}
