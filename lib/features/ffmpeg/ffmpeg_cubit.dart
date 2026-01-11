import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/logs_repository.dart';
import '../../features/logs/log_record.dart';
import '../../services/ffmpeg_runtime_manager.dart';

class FfmpegCubit extends Cubit<FfmpegState> {
  FfmpegCubit(this._manager, this._logs)
      : super(const FfmpegState.initial()) {
    refresh();
  }

  final FfmpegRuntimeManager _manager;
  final LogsRepository _logs;

  Future<void> refresh() async {
    final status = await _manager.status();
    emit(state.copyWith(
      isInstalled: status.isInstalled,
      ffmpegPath: status.ffmpegPath,
      ffprobePath: status.ffprobePath,
      errorMessage: null,
    ));
  }

  Future<void> install() async {
    emit(state.copyWith(isInstalling: true, progress: 0, errorMessage: null));
    await _logs.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: 'tools',
        level: 'info',
        message: 'Installing ffmpeg runtime.',
      ),
    );
    try {
      final info = await _manager.install(
        onProgress: (progress) {
          emit(state.copyWith(progress: progress));
        },
      );
      emit(state.copyWith(
        isInstalling: false,
        isInstalled: info.isInstalled,
        ffmpegPath: info.ffmpegPath,
        ffprobePath: info.ffprobePath,
        progress: 1,
      ));
      await _logs.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'tools',
          level: 'info',
          message: 'ffmpeg runtime installed.',
        ),
      );
    } catch (error) {
      emit(state.copyWith(
        isInstalling: false,
        errorMessage: error.toString(),
      ));
      await _logs.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'tools',
          level: 'error',
          message: 'ffmpeg runtime install failed: $error',
        ),
      );
    }
  }
}

class FfmpegState extends Equatable {
  const FfmpegState({
    required this.isInstalled,
    required this.isInstalling,
    required this.progress,
    required this.ffmpegPath,
    required this.ffprobePath,
    required this.errorMessage,
  });

  const FfmpegState.initial()
      : isInstalled = false,
        isInstalling = false,
        progress = 0,
        ffmpegPath = null,
        ffprobePath = null,
        errorMessage = null;

  final bool isInstalled;
  final bool isInstalling;
  final double progress;
  final String? ffmpegPath;
  final String? ffprobePath;
  final String? errorMessage;

  FfmpegState copyWith({
    bool? isInstalled,
    bool? isInstalling,
    double? progress,
    String? ffmpegPath,
    String? ffprobePath,
    String? errorMessage,
  }) {
    return FfmpegState(
      isInstalled: isInstalled ?? this.isInstalled,
      isInstalling: isInstalling ?? this.isInstalling,
      progress: progress ?? this.progress,
      ffmpegPath: ffmpegPath ?? this.ffmpegPath,
      ffprobePath: ffprobePath ?? this.ffprobePath,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isInstalled,
        isInstalling,
        progress,
        ffmpegPath,
        ffprobePath,
        errorMessage,
      ];
}
