import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/logs_repository.dart';
import 'log_record.dart';

class LogsCubit extends Cubit<LogsState> {
  LogsCubit(this._repository)
    : super(const LogsState(entries: [], isLoading: true)) {
    _subscription = _repository.watchAll().listen(
      (entries) => emit(state.copyWith(entries: entries, isLoading: false)),
    );
    _seed();
  }

  final LogsRepository _repository;
  late final StreamSubscription<List<LogRecord>> _subscription;

  Future<void> _seed() async {
    await _repository.seedIfEmpty();
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

class LogsState extends Equatable {
  const LogsState({required this.entries, required this.isLoading});

  final List<LogRecord> entries;
  final bool isLoading;

  LogsState copyWith({List<LogRecord>? entries, bool? isLoading}) {
    return LogsState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [entries, isLoading];
}
