import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_database.dart';
import '../../data/logs_repository.dart';
import '../../data/queue_repository.dart';
import '../../data/settings_repository.dart';
import '../../services/download/download_telemetry.dart';
import '../logs/log_record.dart';

class QueueCubit extends Cubit<QueueState> {
  QueueCubit(
    this._repository,
    this._logs,
    this._settingsRepository,
    this._telemetry,
  ) : super(const QueueState(
          items: [],
          paused: false,
          concurrency: 2,
          rateLimitPerMinute: 30,
        )) {
    _subscription = _repository.watchQueue().listen(_handleItems);
    _settingsSubscription =
        _settingsRepository.watch().listen(_handleSettings);
    _telemetrySubscription = _telemetry.stream.listen(_handleTelemetry);
  }

  final QueueRepository _repository;
  final LogsRepository _logs;
  final SettingsRepository _settingsRepository;
  final DownloadTelemetry _telemetry;
  late final StreamSubscription<List<QueueRecord>> _subscription;
  late final StreamSubscription<AppSettings> _settingsSubscription;
  late final StreamSubscription<DownloadTelemetryState> _telemetrySubscription;
  AppSettings _settings = AppSettings.defaults();

  void _handleItems(List<QueueRecord> items) {
    final hasActive = items.any(
      (item) => item.job.status == 'queued' || item.job.status == 'running',
    );
    final paused = !hasActive && items.any((item) => item.job.status == 'paused');
    emit(state.copyWith(items: items, paused: paused));
  }

  void _handleSettings(AppSettings settings) {
    _settings = settings;
    emit(state.copyWith(
      concurrency: settings.concurrency,
      rateLimitPerMinute: settings.rateLimitPerMinute,
    ));
  }

  void _handleTelemetry(DownloadTelemetryState telemetry) {
    emit(state.copyWith(
      rateLimitRemaining: telemetry.remaining,
      rateLimitResetAt: telemetry.resetAt,
    ));
  }

  Future<bool> enqueueSavedItem(SavedItem item) async {
    final policySnapshot = _settings.overwritePolicy == OverwritePolicy.skipIfExists
        ? 'skip_if_exists'
        : 'overwrite_if_newer';
    final result = await _repository.enqueueForItem(
      item,
      policySnapshot: policySnapshot,
    );
    await _logs.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: 'download',
        level: 'info',
        message: result.created
            ? 'Enqueued download for ${item.permalink}.'
            : 'Download already queued for ${item.permalink}.',
      ),
    );
    return result.created;
  }

  Future<void> togglePauseAll() async {
    if (state.paused) {
      await _repository.resumeAll();
    } else {
      await _repository.pauseAll();
    }
  }

  Future<void> pauseJob(int jobId) async {
    await _repository.pauseJob(jobId);
  }

  Future<void> resumeJob(int jobId) async {
    await _repository.resumeJob(jobId);
  }

  Future<void> retryJob(int jobId) async {
    await _repository.retryJob(jobId);
  }

  Future<void> clearCompleted() async {
    await _repository.clearCompleted();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await _settingsSubscription.cancel();
    await _telemetrySubscription.cancel();
    return super.close();
  }
}

class QueueState extends Equatable {
  const QueueState({
    required this.items,
    required this.paused,
    required this.concurrency,
    required this.rateLimitPerMinute,
    this.rateLimitRemaining,
    this.rateLimitResetAt,
  });

  final List<QueueRecord> items;
  final bool paused;
  final int concurrency;
  final int rateLimitPerMinute;
  final double? rateLimitRemaining;
  final DateTime? rateLimitResetAt;

  QueueState copyWith({
    List<QueueRecord>? items,
    bool? paused,
    int? concurrency,
    int? rateLimitPerMinute,
    double? rateLimitRemaining,
    DateTime? rateLimitResetAt,
  }) {
    return QueueState(
      items: items ?? this.items,
      paused: paused ?? this.paused,
      concurrency: concurrency ?? this.concurrency,
      rateLimitPerMinute: rateLimitPerMinute ?? this.rateLimitPerMinute,
      rateLimitRemaining: rateLimitRemaining ?? this.rateLimitRemaining,
      rateLimitResetAt: rateLimitResetAt ?? this.rateLimitResetAt,
    );
  }

  @override
  List<Object?> get props => [
        items,
        paused,
        concurrency,
        rateLimitPerMinute,
        rateLimitRemaining,
        rateLimitResetAt,
      ];
}
