import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/import_repository.dart';
import '../../data/logs_repository.dart';
import '../logs/log_record.dart';

class ImportCubit extends Cubit<ImportState> {
  ImportCubit(this._repository, this._logs)
      : super(const ImportState(status: ImportStatus.idle));

  final ImportRepository _repository;
  final LogsRepository _logs;

  Future<void> importZipBytes(Uint8List bytes, {String? filename}) async {
    emit(state.copyWith(status: ImportStatus.importing, errorMessage: null));
    await _logs.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: 'import',
        level: 'info',
        message: 'ZIP import started${filename == null ? '' : ': $filename'}.',
      ),
    );

    try {
      final result = await _repository.importZipBytes(bytes);
      emit(state.copyWith(
        status: ImportStatus.success,
        result: result,
        filename: filename,
      ));
      await _logs.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'import',
          level: 'info',
          message:
              'ZIP import complete: ${result.posts} posts, ${result.comments} comments, ${result.inserted} new, ${result.updated} updated, ${result.skipped} skipped.',
        ),
      );
    } catch (error) {
      emit(state.copyWith(
        status: ImportStatus.error,
        errorMessage: error.toString(),
        filename: filename,
      ));
      await _logs.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'import',
          level: 'error',
          message: 'ZIP import failed: $error',
        ),
      );
    }
  }

  void setDragging(bool isDragging) {
    emit(state.copyWith(isDragging: isDragging));
  }

  Future<void> setError(String message) async {
    emit(state.copyWith(status: ImportStatus.error, errorMessage: message));
    await _logs.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: 'import',
        level: 'error',
        message: message,
      ),
    );
  }

  void reset() {
    emit(const ImportState(status: ImportStatus.idle));
  }
}

enum ImportStatus { idle, importing, success, error }

class ImportState extends Equatable {
  const ImportState({
    required this.status,
    this.result,
    this.filename,
    this.errorMessage,
    this.isDragging = false,
  });

  final ImportStatus status;
  final ImportResult? result;
  final String? filename;
  final String? errorMessage;
  final bool isDragging;

  ImportState copyWith({
    ImportStatus? status,
    ImportResult? result,
    String? filename,
    String? errorMessage,
    bool? isDragging,
  }) {
    return ImportState(
      status: status ?? this.status,
      result: result ?? this.result,
      filename: filename ?? this.filename,
      errorMessage: errorMessage,
      isDragging: isDragging ?? this.isDragging,
    );
  }

  @override
  List<Object?> get props => [status, result, filename, errorMessage, isDragging];
}
