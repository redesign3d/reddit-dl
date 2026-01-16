import 'package:flutter/material.dart';

enum AppSection { library, queue, logs, import, sync, diagnostics, settings }

extension AppSectionMeta on AppSection {
  String get label {
    switch (this) {
      case AppSection.library:
        return 'Library';
      case AppSection.queue:
        return 'Queue';
      case AppSection.logs:
        return 'Logs';
      case AppSection.import:
        return 'Import';
      case AppSection.sync:
        return 'Sync';
      case AppSection.diagnostics:
        return 'Diagnostics';
      case AppSection.settings:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case AppSection.library:
        return Icons.inventory_2_outlined;
      case AppSection.queue:
        return Icons.downloading_outlined;
      case AppSection.logs:
        return Icons.article_outlined;
      case AppSection.import:
        return Icons.unarchive_outlined;
      case AppSection.sync:
        return Icons.sync_outlined;
      case AppSection.diagnostics:
        return Icons.health_and_safety_outlined;
      case AppSection.settings:
        return Icons.tune_outlined;
    }
  }
}
