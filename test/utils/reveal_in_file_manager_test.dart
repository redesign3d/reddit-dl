import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/utils/reveal_in_file_manager.dart';

void main() {
  test('builds macOS reveal command for file paths', () {
    final command = buildRevealCommand(
      platform: RevealPlatform.macos,
      path: '/tmp/video.mp4',
      isDirectory: false,
    );

    expect(command, isNotNull);
    expect(command!.executable, 'open');
    expect(command.arguments, ['-R', '/tmp/video.mp4']);
  });

  test('builds Windows reveal command for file paths', () {
    final command = buildRevealCommand(
      platform: RevealPlatform.windows,
      path: r'C:\Downloads\video.mp4',
      isDirectory: false,
    );

    expect(command, isNotNull);
    expect(command!.executable, 'explorer');
    expect(command.arguments, [r'/select,C:\Downloads\video.mp4']);
  });

  test(
    'builds Linux reveal command for file paths by opening parent folder',
    () {
      final command = buildRevealCommand(
        platform: RevealPlatform.linux,
        path: '/tmp/video.mp4',
        isDirectory: false,
      );

      expect(command, isNotNull);
      expect(command!.executable, 'xdg-open');
      expect(command.arguments, ['/tmp']);
    },
  );

  test('builds Linux reveal command for directory paths', () {
    final command = buildRevealCommand(
      platform: RevealPlatform.linux,
      path: '/tmp/downloads',
      isDirectory: true,
    );

    expect(command, isNotNull);
    expect(command!.executable, 'xdg-open');
    expect(command.arguments, ['/tmp/downloads']);
  });

  test('returns null reveal command for unsupported platform', () {
    final command = buildRevealCommand(
      platform: RevealPlatform.unsupported,
      path: '/tmp/video.mp4',
      isDirectory: false,
    );

    expect(command, isNull);
  });
}
