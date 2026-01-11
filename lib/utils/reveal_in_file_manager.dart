import 'dart:io';

Future<bool> revealInFileManager(String path) async {
  try {
    if (Platform.isMacOS) {
      final result = await Process.run('open', [path]);
      return result.exitCode == 0;
    }
    if (Platform.isWindows) {
      final result = await Process.run('explorer', [path]);
      return result.exitCode == 0;
    }
    if (Platform.isLinux) {
      final result = await Process.run('xdg-open', [path]);
      return result.exitCode == 0;
    }
  } catch (_) {
    return false;
  }
  return false;
}
