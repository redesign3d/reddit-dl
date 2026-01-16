import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_database.dart';
import '../../data/library_repository.dart';
import '../../data/queue_repository.dart';
import '../../data/settings_repository.dart';

class WantedCubit extends Cubit<WantedState> {
  WantedCubit({
    required QueueRepository queueRepository,
    required LibraryRepository libraryRepository,
    required SettingsRepository settingsRepository,
  }) : _queueRepository = queueRepository,
       _libraryRepository = libraryRepository,
       _settingsRepository = settingsRepository,
       super(const WantedState(items: [], isLoading: true)) {
    _queueSubscription = _queueRepository.watchQueue().listen((records) {
      _queueRecords = records;
      _recompute();
    });
    _librarySubscription = _libraryRepository.watchItemsWithoutMedia().listen((
      items,
    ) {
      _noMediaItems = items;
      _recompute();
    });
    _settingsSubscription = _settingsRepository.watch().listen((settings) {
      _settings = settings;
      _recompute();
    });
  }

  final QueueRepository _queueRepository;
  final LibraryRepository _libraryRepository;
  final SettingsRepository _settingsRepository;

  late final StreamSubscription<List<QueueRecord>> _queueSubscription;
  late final StreamSubscription<List<SavedItem>> _librarySubscription;
  late final StreamSubscription<AppSettings> _settingsSubscription;

  List<QueueRecord> _queueRecords = const [];
  List<SavedItem> _noMediaItems = const [];
  AppSettings _settings = AppSettings.defaults();

  void _recompute() {
    final wanted = <int, WantedRecord>{};

    for (final record in _queueRecords) {
      final job = record.job;
      final item = record.item;
      final reason = _reasonForJob(job, item);
      if (reason == null) {
        continue;
      }
      wanted[item.id] = WantedRecord(item: item, job: job, reason: reason);
    }

    for (final item in _noMediaItems) {
      if (wanted.containsKey(item.id)) {
        continue;
      }
      wanted[item.id] = WantedRecord(
        item: item,
        job: null,
        reason: WantedReason.noMedia,
      );
    }

    emit(
      WantedState(
        items:
            wanted.values.toList()
              ..sort((a, b) => a.item.id.compareTo(b.item.id)),
        isLoading: false,
      ),
    );
  }

  WantedReason? _reasonForJob(DownloadJob job, SavedItem item) {
    final error = (job.lastError ?? '').toLowerCase();
    if (job.status == 'skipped') {
      if (error.contains('nsfw')) {
        return WantedReason.nsfw;
      }
      if (error.contains('no media') || error.contains('no outputs')) {
        return WantedReason.noMedia;
      }
    }
    if (job.status == 'failed') {
      if (error.contains('not available') || error.contains('configure')) {
        return WantedReason.missingTool;
      }
      if (error.contains('max attempts') ||
          job.attempts >= _settings.maxDownloadAttempts) {
        return WantedReason.repeatedFailures;
      }
    }
    if (item.over18 && !_settings.downloadNsfw) {
      return WantedReason.nsfw;
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _queueSubscription.cancel();
    await _librarySubscription.cancel();
    await _settingsSubscription.cancel();
    return super.close();
  }
}

class WantedState extends Equatable {
  const WantedState({required this.items, required this.isLoading});

  final List<WantedRecord> items;
  final bool isLoading;

  @override
  List<Object?> get props => [items, isLoading];
}

class WantedRecord extends Equatable {
  const WantedRecord({
    required this.item,
    required this.job,
    required this.reason,
  });

  final SavedItem item;
  final DownloadJob? job;
  final WantedReason reason;

  @override
  List<Object?> get props => [item, job, reason];
}

enum WantedReason { nsfw, missingTool, repeatedFailures, noMedia }
