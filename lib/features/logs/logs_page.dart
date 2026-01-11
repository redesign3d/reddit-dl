import 'package:flutter/material.dart';

import '../../ui/components/log_viewer.dart';
import '../../ui/tokens.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity stream',
            style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: AppTokens.space.s8),
        Text(
          'Logs are persisted and filterable. Export and copy from here.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: context.appColors.mutedForeground),
        ),
        SizedBox(height: AppTokens.space.s16),
        LogViewer(entries: _seedLogs),
      ],
    );
  }
}

final List<LogEntry> _seedLogs = [
  LogEntry(
    timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    scope: 'import',
    level: 'info',
    message: 'ZIP import parsed 152 saved items.',
  ),
  LogEntry(
    timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    scope: 'resolve',
    level: 'warn',
    message: '429 received. Backing off for 60 seconds.',
  ),
  LogEntry(
    timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    scope: 'download',
    level: 'info',
    message: 'Queued video merge for /r/analog/scan.',
  ),
  LogEntry(
    timestamp: DateTime.now().subtract(const Duration(seconds: 20)),
    scope: 'download',
    level: 'error',
    message: 'ffmpeg unavailable; will download on next run.',
  ),
];
