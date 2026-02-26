import 'dart:io';

typedef RevealProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

enum RevealPlatform { macos, windows, linux, unsupported }

class RevealCommand {
  const RevealCommand({required this.executable, required this.arguments});

  final String executable;
  final List<String> arguments;
}

Future<bool> revealInFileManager(
  String path, {
  RevealProcessRunner runner = _runProcess,
}) async {
  final normalizedPath = path.trim();
  if (normalizedPath.isEmpty) {
    return false;
  }

  final target = _resolveRevealTarget(normalizedPath);
  final command = buildRevealCommand(
    platform: currentRevealPlatform(),
    path: target.path,
    isDirectory: target.isDirectory,
  );
  if (command == null) {
    return false;
  }

  try {
    final result = await runner(command.executable, command.arguments);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}

RevealPlatform currentRevealPlatform() {
  if (Platform.isMacOS) {
    return RevealPlatform.macos;
  }
  if (Platform.isWindows) {
    return RevealPlatform.windows;
  }
  if (Platform.isLinux) {
    return RevealPlatform.linux;
  }
  return RevealPlatform.unsupported;
}

RevealCommand? buildRevealCommand({
  required RevealPlatform platform,
  required String path,
  required bool isDirectory,
}) {
  switch (platform) {
    case RevealPlatform.macos:
      if (isDirectory) {
        return RevealCommand(executable: 'open', arguments: [path]);
      }
      return RevealCommand(executable: 'open', arguments: ['-R', path]);
    case RevealPlatform.windows:
      if (isDirectory) {
        return RevealCommand(executable: 'explorer', arguments: [path]);
      }
      return RevealCommand(executable: 'explorer', arguments: ['/select,$path']);
    case RevealPlatform.linux:
      final directoryPath = isDirectory ? path : File(path).parent.path;
      return RevealCommand(executable: 'xdg-open', arguments: [directoryPath]);
    case RevealPlatform.unsupported:
      return null;
  }
}

Future<ProcessResult> _runProcess(String executable, List<String> arguments) {
  return Process.run(executable, arguments);
}

_ResolvedRevealTarget _resolveRevealTarget(String path) {
  final directory = Directory(path);
  if (directory.existsSync()) {
    return _ResolvedRevealTarget(path: directory.path, isDirectory: true);
  }

  final file = File(path);
  if (file.existsSync()) {
    return _ResolvedRevealTarget(path: file.path, isDirectory: false);
  }

  final parent = file.parent;
  if (parent.existsSync()) {
    return _ResolvedRevealTarget(path: parent.path, isDirectory: true);
  }

  return _ResolvedRevealTarget(path: path, isDirectory: false);
}

class _ResolvedRevealTarget {
  const _ResolvedRevealTarget({required this.path, required this.isDirectory});

  final String path;
  final bool isDirectory;
}
