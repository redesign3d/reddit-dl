import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/history_repository.dart';
import '../../data/logs_repository.dart';
import '../../data/queue_repository.dart';
import '../logs/log_record.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import '../../utils/reveal_in_file_manager.dart';
import 'history_cubit.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        final colors = context.appColors;
        final total = state.records.length;
        final failed = state.records
            .where((record) => record.job.status == 'failed')
            .length;
        final skipped = state.records
            .where((record) => record.job.status == 'skipped')
            .length;
        final completed = state.records
            .where((record) => record.job.status == 'completed')
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: AppTokens.space.s6),
                  Text(
                    '$total total • $completed completed • $failed failed • $skipped skipped',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppTokens.space.s16),
            if (state.records.isEmpty)
              AppCard(
                child: Text(
                  'No completed or failed jobs yet.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              Column(
                children: state.records
                    .map(
                      (record) => Padding(
                        padding: EdgeInsets.only(bottom: AppTokens.space.s12),
                        child: _HistoryCard(record: record),
                      ),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});

  final HistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final job = record.job;
    final item = record.item;
    final statusLabel = job.status.toUpperCase();
    final duration = _formatDuration(job.startedAt, job.completedAt);
    final completedAt = job.completedAt == null
        ? 'In progress'
        : job.completedAt!.toLocal().toString();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: AppTokens.space.s6),
          Text(
            '${item.subreddit} • $statusLabel',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
          ),
          SizedBox(height: AppTokens.space.s6),
          Text(
            'Completed: $completedAt',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (duration != null) ...[
            SizedBox(height: AppTokens.space.s4),
            Text(
              'Duration: $duration',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (job.outputPath.isNotEmpty) ...[
            SizedBox(height: AppTokens.space.s4),
            Text(
              'Output: ${job.outputPath}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (job.lastError != null && job.lastError!.isNotEmpty) ...[
            SizedBox(height: AppTokens.space.s4),
            Text(
              'Details: ${job.lastError}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
          ],
          SizedBox(height: AppTokens.space.s12),
          Wrap(
            spacing: AppTokens.space.s8,
            runSpacing: AppTokens.space.s8,
            children: [
              AppButton(
                label: 'Open folder',
                variant: AppButtonVariant.secondary,
                onPressed: () async {
                  final path = job.outputPath.isEmpty
                      ? Directory.systemTemp.path
                      : job.outputPath;
                  final success = await revealInFileManager(path);
                  if (!context.mounted) {
                    return;
                  }
                  await context.read<LogsRepository>().add(
                    LogRecord(
                      timestamp: DateTime.now(),
                      scope: 'history',
                      level: success ? 'info' : 'warn',
                      message: 'Reveal output for job ${job.id}: $path',
                    ),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  AppToast.show(
                    context,
                    success ? 'Opened file manager.' : 'Reveal failed.',
                  );
                },
              ),
              AppButton(
                label: 'Copy log context',
                variant: AppButtonVariant.ghost,
                onPressed: () async {
                  final logs = await context
                      .read<LogsRepository>()
                      .fetchByJobId(job.id);
                  final text = logs
                      .map(
                        (entry) =>
                            '${entry.timestamp.toIso8601String()} [${entry.level}] ${entry.scope}: ${entry.message}',
                      )
                      .join('\n');
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!context.mounted) {
                    return;
                  }
                  await context.read<LogsRepository>().add(
                    LogRecord(
                      timestamp: DateTime.now(),
                      scope: 'history',
                      level: 'info',
                      message: 'Copied log context for job ${job.id}.',
                    ),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  AppToast.show(context, 'Log context copied.');
                },
              ),
              if (job.status == 'failed')
                AppButton(
                  label: 'Retry job',
                  onPressed: () async {
                    await context.read<QueueRepository>().retryJob(job.id);
                    if (!context.mounted) {
                      return;
                    }
                    await context.read<LogsRepository>().add(
                      LogRecord(
                        timestamp: DateTime.now(),
                        scope: 'history',
                        level: 'info',
                        message: 'Retry requested for job ${job.id}.',
                      ),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    AppToast.show(context, 'Retry queued.');
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  String? _formatDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return null;
    }
    final duration = end.difference(start);
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    }
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }
}
