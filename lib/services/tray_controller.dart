import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayController with TrayListener, WindowListener {
  TrayController({
    required VoidCallback onPauseAll,
    required VoidCallback onResumeAll,
    required Future<void> Function() onQuit,
    required Future<void> Function() onFirstHide,
  })  : _onPauseAll = onPauseAll,
        _onResumeAll = onResumeAll,
        _onQuit = onQuit,
        _onFirstHide = onFirstHide;

  final VoidCallback _onPauseAll;
  final VoidCallback _onResumeAll;
  final Future<void> Function() _onQuit;
  final Future<void> Function() _onFirstHide;

  bool _allowClose = false;
  bool _hintShown = false;

  Future<void> init() async {
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
    trayManager.addListener(this);

    await trayManager.setIcon(_trayIconPath());
    await trayManager.setToolTip('reddit-dl');
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: 'Show/Hide'),
      MenuItem.separator(),
      MenuItem(key: 'pause', label: 'Pause all'),
      MenuItem(key: 'resume', label: 'Resume all'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit'),
    ]));
  }

  Future<void> dispose() async {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
  }

  @override
  Future<void> onWindowClose() async {
    if (_allowClose) {
      return;
    }
    await windowManager.hide();
    if (!_hintShown) {
      _hintShown = true;
      await _onFirstHide();
    }
  }

  @override
  Future<void> onTrayIconMouseDown() async {
    await _toggleWindow();
  }

  @override
  Future<void> onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show':
        await _toggleWindow();
        break;
      case 'pause':
        _onPauseAll();
        break;
      case 'resume':
        _onResumeAll();
        break;
      case 'quit':
        _allowClose = true;
        await _onQuit();
        break;
    }
  }

  Future<void> _toggleWindow() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  String _trayIconPath() {
    if (Platform.isWindows) {
      return 'windows/runner/resources/app_icon.ico';
    }
    if (Platform.isMacOS) {
      return 'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png';
    }
    return 'assets/icons/tray.png';
  }
}
