import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QueueCubit extends Cubit<QueueState> {
  QueueCubit()
      : super(
          QueueState(
            paused: false,
            items: _seedItems,
          ),
        );

  void togglePauseAll() {
    final paused = !state.paused;
    final updated = state.items
        .map(
          (item) => item.status == QueueStatus.running && paused
              ? item.copyWith(status: QueueStatus.paused)
              : item.status == QueueStatus.paused && !paused
                  ? item.copyWith(status: QueueStatus.queued)
                  : item,
        )
        .toList();
    emit(state.copyWith(paused: paused, items: updated));
  }

  void retryItem(String id) {
    emit(state.copyWith(
      items: state.items
          .map(
            (item) => item.id == id
                ? item.copyWith(
                    status: QueueStatus.queued,
                    progress: 0,
                    error: null,
                  )
                : item,
          )
          .toList(),
    ));
  }

  void cancelItem(String id) {
    emit(state.copyWith(
      items: state.items
          .map(
            (item) => item.id == id
                ? item.copyWith(status: QueueStatus.skipped)
                : item,
          )
          .toList(),
    ));
  }

  void markComplete(String id) {
    emit(state.copyWith(
      items: state.items
          .map(
            (item) => item.id == id
                ? item.copyWith(status: QueueStatus.completed, progress: 1)
                : item,
          )
          .toList(),
    ));
  }

  void clearCompleted() {
    emit(state.copyWith(
      items: state.items
          .where(
            (item) => item.status != QueueStatus.completed,
          )
          .toList(),
    ));
  }
}

enum QueueStatus { queued, running, paused, failed, completed, skipped }

class QueueItem extends Equatable {
  const QueueItem({
    required this.id,
    required this.title,
    required this.subreddit,
    required this.status,
    required this.progress,
    this.error,
  });

  final String id;
  final String title;
  final String subreddit;
  final QueueStatus status;
  final double progress;
  final String? error;

  QueueItem copyWith({
    QueueStatus? status,
    double? progress,
    String? error,
  }) {
    return QueueItem(
      id: id,
      title: title,
      subreddit: subreddit,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
    );
  }

  @override
  List<Object?> get props => [id, title, subreddit, status, progress, error];
}

class QueueState extends Equatable {
  const QueueState({
    required this.paused,
    required this.items,
  });

  final bool paused;
  final List<QueueItem> items;

  QueueState copyWith({
    bool? paused,
    List<QueueItem>? items,
  }) {
    return QueueState(
      paused: paused ?? this.paused,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [paused, items];
}

const List<QueueItem> _seedItems = [
  QueueItem(
    id: 'job-1',
    title: 'Hubble composite with real-time color grading notes',
    subreddit: 'spaceporn',
    status: QueueStatus.running,
    progress: 0.62,
  ),
  QueueItem(
    id: 'job-2',
    title: 'City ambience mix for late-night renders',
    subreddit: 'cyberpunk',
    status: QueueStatus.queued,
    progress: 0,
  ),
  QueueItem(
    id: 'job-3',
    title: 'Layered risograph palette breakdown',
    subreddit: 'printmaking',
    status: QueueStatus.failed,
    progress: 0.2,
    error: 'Remote server responded with 429.',
  ),
  QueueItem(
    id: 'job-4',
    title: 'Medium format scan workflow checklist',
    subreddit: 'analog',
    status: QueueStatus.completed,
    progress: 1,
  ),
];
