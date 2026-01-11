import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../data/logs_repository.dart';
import '../../features/logs/log_record.dart';
import 'tool_detector.dart';

class ExternalToolRunner {
  ExternalToolRunner(this._logsRepository);

  final LogsRepository _logsRepository;

  Future<ExternalToolResult> run({
    required ToolInfo tool,
    required List<String> args,
    String? workingDirectory,
  }) async {
    if (!tool.isAvailable || tool.path == null) {
      return ExternalToolResult(
        exitCode: -1,
        stdout: const [],
        stderr: const ['Tool is not available.'],
      );
    }

    final process = await Process.start(
      tool.path!,
      args,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );

    final stdoutLines = <String>[];
    final stderrLines = <String>[];

    final stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      stdoutLines.add(line);
      _logsRepository.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'tools',
          level: 'info',
          message: line,
        ),
      );
    });

    final stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      stderrLines.add(line);
      _logsRepository.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'tools',
          level: 'error',
          message: line,
        ),
      );
    });

    final exitCode = await process.exitCode;
    await stdoutSubscription.cancel();
    await stderrSubscription.cancel();

    return ExternalToolResult(
      exitCode: exitCode,
      stdout: stdoutLines,
      stderr: stderrLines,
    );
  }
}

class ExternalToolResult {
  const ExternalToolResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final List<String> stdout;
  final List<String> stderr;

  bool get isSuccess => exitCode == 0;
}
