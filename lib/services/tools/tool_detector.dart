import 'dart:io';

class ToolInfo {
  const ToolInfo({
    required this.name,
    this.path,
    this.version,
    this.isAvailable = false,
    this.isOverride = false,
    this.errorMessage,
  });

  final String name;
  final String? path;
  final String? version;
  final bool isAvailable;
  final bool isOverride;
  final String? errorMessage;
}

class ToolDetector {
  Future<ToolInfo> detect(
    String name, {
    String? overridePath,
  }) async {
    if (overridePath != null && overridePath.trim().isNotEmpty) {
      final trimmed = overridePath.trim();
      final file = File(trimmed);
      if (!await file.exists()) {
        return ToolInfo(
          name: name,
          path: trimmed,
          isAvailable: false,
          isOverride: true,
          errorMessage: 'Override path not found.',
        );
      }
      final version = await _versionFor(trimmed);
      return ToolInfo(
        name: name,
        path: trimmed,
        version: version,
        isAvailable: true,
        isOverride: true,
      );
    }

    final path = await _findOnPath(name);
    if (path == null) {
      return ToolInfo(
        name: name,
        isAvailable: false,
        errorMessage: 'Not found on PATH.',
      );
    }
    final version = await _versionFor(path);
    return ToolInfo(
      name: name,
      path: path,
      version: version,
      isAvailable: true,
      isOverride: false,
    );
  }

  Future<String?> _findOnPath(String name) async {
    final command = Platform.isWindows ? 'where' : 'which';
    final result = await Process.run(command, [name]);
    if (result.exitCode != 0) {
      return null;
    }
    final output = (result.stdout as String).trim();
    if (output.isEmpty) {
      return null;
    }
    return output.split(RegExp(r'\r?\n')).first.trim();
  }

  Future<String?> _versionFor(String path) async {
    final result = await Process.run(path, ['--version']);
    if (result.exitCode != 0) {
      return null;
    }
    final stdout = (result.stdout as String).trim();
    final stderr = (result.stderr as String).trim();
    final output = stdout.isNotEmpty ? stdout : stderr;
    if (output.isEmpty) {
      return null;
    }
    return output.split(RegExp(r'\r?\n')).first.trim();
  }
}
