import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/history_repository.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._repository)
    : super(const HistoryState(records: [], isLoading: true)) {
    _subscription = _repository.watchHistory().listen(_handleRecords);
  }

  final HistoryRepository _repository;
  late final StreamSubscription<List<HistoryRecord>> _subscription;

  void _handleRecords(List<HistoryRecord> records) {
    emit(HistoryState(records: records, isLoading: false));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

class HistoryState extends Equatable {
  const HistoryState({required this.records, required this.isLoading});

  final List<HistoryRecord> records;
  final bool isLoading;

  @override
  List<Object?> get props => [records, isLoading];
}
