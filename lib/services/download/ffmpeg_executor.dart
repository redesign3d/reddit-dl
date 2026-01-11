import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

abstract class FfmpegExecutor {
  Future<FfmpegRunResult> run({
    required String ffmpegPath,
    required List<String> args,
    String? workingDirectory,
    CancelToken? cancelToken,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  });
}

class ProcessFfmpegExecutor implements FfmpegExecutor {
  @override
  Future<FfmpegRunResult> run({
    required String ffmpegPath,
    required List<String> args,
    String? workingDirectory,
    CancelToken? cancelToken,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  }) async {
    final process = await Process.start(
      ffmpegPath,
      args,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );

    unawaited(
      cancelToken?.whenCancel.then((_) {
        process.kill();
      }),
    );

    final stdoutLines = <String>[];
    final stderrLines = <String>[];

    final stdoutSub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      stdoutLines.add(line);
      onStdout?.call(line);
    });

    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      stderrLines.add(line);
      onStderr?.call(line);
    });

    final exitCode = await process.exitCode;
    await stdoutSub.cancel();
    await stderrSub.cancel();

    return FfmpegRunResult(
      exitCode: exitCode,
      stdout: stdoutLines,
      stderr: stderrLines,
    );
  }
}

class FfmpegRunResult {
  const FfmpegRunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final List<String> stdout;
  final List<String> stderr;

  bool get isSuccess => exitCode == 0;
}
