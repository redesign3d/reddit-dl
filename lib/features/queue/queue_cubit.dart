import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_database.dart';
import '../../data/logs_repository.dart';
import '../../data/queue_repository.dart';
import '../logs/log_record.dart';

class QueueCubit extends Cubit<QueueState> {
  QueueCubit(this._repository, this._logs)
      : super(const QueueState(items: [], paused: false)) {
    _subscription = _repository.watchQueue().listen(_handleItems);
  }

  final QueueRepository _repository;
  final LogsRepository _logs;
  late final StreamSubscription<List<QueueRecord>> _subscription;

  void _handleItems(List<QueueRecord> items) {
    final hasActive = items.any(
      (item) => item.job.status == 'queued' || item.job.status == 'running',
    );
    final paused = !hasActive && items.any((item) => item.job.status == 'paused');
    emit(state.copyWith(items: items, paused: paused));
  }

  Future<bool> enqueueSavedItem(SavedItem item) async {
    final result = await _repository.enqueueForItem(item);
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
    return super.close();
  }
}

class QueueState extends Equatable {
  const QueueState({required this.items, required this.paused});

  final List<QueueRecord> items;
  final bool paused;

  QueueState copyWith({
    List<QueueRecord>? items,
    bool? paused,
  }) {
    return QueueState(
      items: items ?? this.items,
      paused: paused ?? this.paused,
    );
  }

  @override
  List<Object?> get props => [items, paused];
}
