import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

class DownloadTelemetry {
  DownloadTelemetry();

  final _controller = StreamController<DownloadTelemetryState>.broadcast();
  var _state = const DownloadTelemetryState();

  Stream<DownloadTelemetryState> get stream => _controller.stream;
  DownloadTelemetryState get state => _state;

  void updateFromHeaders(Headers headers) {
    final remainingRaw = headers.value('x-ratelimit-remaining');
    final resetRaw = headers.value('x-ratelimit-reset');
    final remaining = remainingRaw == null
        ? null
        : double.tryParse(remainingRaw);
    final resetSeconds = resetRaw == null ? null : int.tryParse(resetRaw);
    final resetAt = resetSeconds == null
        ? null
        : DateTime.now().add(Duration(seconds: resetSeconds));
    if (remaining == null && resetAt == null) {
      return;
    }
    _state = _state.copyWith(remaining: remaining, resetAt: resetAt);
    _controller.add(_state);
  }

  void dispose() {
    _controller.close();
  }
}

class DownloadTelemetryState extends Equatable {
  const DownloadTelemetryState({this.remaining, this.resetAt});

  final double? remaining;
  final DateTime? resetAt;

  DownloadTelemetryState copyWith({double? remaining, DateTime? resetAt}) {
    return DownloadTelemetryState(
      remaining: remaining ?? this.remaining,
      resetAt: resetAt ?? this.resetAt,
    );
  }

  @override
  List<Object?> get props => [remaining, resetAt];
}
