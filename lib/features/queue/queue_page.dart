import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/queue_repository.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_chip.dart';
import '../../ui/components/app_progress.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import '../../utils/reveal_in_file_manager.dart';
import 'queue_cubit.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QueueCubit, QueueState>(
      builder: (context, state) {
        final colors = context.appColors;
        final running =
            state.items.where((item) => item.job.status == 'running').length;
        final failed =
            state.items.where((item) => item.job.status == 'failed').length;
        final remaining = state.rateLimitRemaining;
        final resetAt = state.rateLimitResetAt;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Queue status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: AppTokens.space.s6),
                        Text(
                          '${state.items.length} total • $running running • $failed failed',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: AppTokens.space.s12),
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rate limits',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: AppTokens.space.s6),
                        Text(
                          'Rate limit: ${state.rateLimitPerMinute}/min • Concurrency: ${state.concurrency}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.mutedForeground),
                        ),
                        if (remaining != null || resetAt != null) ...[
                          SizedBox(height: AppTokens.space.s6),
                          Text(
                            _formatRateLimit(remaining, resetAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.mutedForeground),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTokens.space.s16),
            Row(
              children: [
                AppButton(
                  label: state.paused ? 'Resume all' : 'Pause all',
                  onPressed: () => context.read<QueueCubit>().togglePauseAll(),
                  variant:
                      state.paused
                          ? AppButtonVariant.primary
                          : AppButtonVariant.secondary,
                ),
                SizedBox(width: AppTokens.space.s8),
                AppButton(
                  label: 'Clear completed',
                  variant: AppButtonVariant.ghost,
                  onPressed:
                      state.items.any((item) => item.job.status == 'completed')
                          ? () => context.read<QueueCubit>().clearCompleted()
                          : null,
                ),
                const Spacer(),
                AppButton(
                  label: 'Copy queue summary',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    final summary = state.items
                        .map(
                          (item) =>
                              '${item.job.status.toUpperCase()} • ${item.item.title}',
                        )
                        .join('\n');
                    Clipboard.setData(ClipboardData(text: summary));
                    AppToast.show(context, 'Queue summary copied.');
                  },
                ),
              ],
            ),
            SizedBox(height: AppTokens.space.s16),
            if (state.items.isEmpty)
              AppCard(
                child: Text(
                  'No queued downloads yet. Enqueue items from the Library.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              Column(
                children:
                    state.items
                        .map(
                          (item) => Padding(
                            padding: EdgeInsets.only(
                              bottom: AppTokens.space.s12,
                            ),
                            child: _QueueItemCard(item: item),
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

class _QueueItemCard extends StatelessWidget {
  const _QueueItemCard({required this.item});

  final QueueRecord item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final status = item.job.status;
    final isQueued = status == 'queued';
    final isPaused = status == 'paused';
    final isFailed = status == 'failed';
    final isSkipped = status == 'skipped';
    final isCompleted = status == 'completed';
    final isMerging = status == 'merging';
    final isRunningTool = status == 'running_tool';
    final isExporting = status == 'exporting';
    final isActive =
        status == 'running' || isMerging || isRunningTool || isExporting;

    return GestureDetector(
      onSecondaryTapDown: (details) async {
        final selection = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: const [
            PopupMenuItem(value: 'retry', child: Text('Retry job')),
            PopupMenuItem(
              value: 'reveal',
              child: Text('Reveal in Finder/Explorer'),
            ),
          ],
        );
        if (!context.mounted) {
          return;
        }
        if (selection == 'retry') {
          await context.read<QueueCubit>().retryJob(item.job.id);
          if (!context.mounted) {
            return;
          }
          AppToast.show(context, 'Retry queued.');
        }
        if (selection == 'reveal') {
          final path =
              item.job.outputPath.isEmpty
                  ? Directory.systemTemp.path
                  : item.job.outputPath;
          final success = await revealInFileManager(path);
          if (!context.mounted) {
            return;
          }
          AppToast.show(
            context,
            success ? 'Opened file manager (mock path).' : 'Reveal failed.',
          );
        }
      },
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.item.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: AppTokens.space.s6),
                      Text(
                        'r/${item.item.subreddit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFailed)
                  AppButton(
                    label: 'Retry',
                    variant: AppButtonVariant.secondary,
                    onPressed:
                        () => context.read<QueueCubit>().retryJob(item.job.id),
                  )
                else if (isPaused)
                  AppButton(
                    label: 'Resume',
                    variant: AppButtonVariant.secondary,
                    onPressed:
                        () => context.read<QueueCubit>().resumeJob(item.job.id),
                  )
                else if (isQueued)
                  AppButton(
                    label: 'Pause',
                    variant: AppButtonVariant.ghost,
                    onPressed:
                        () => context.read<QueueCubit>().pauseJob(item.job.id),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            SizedBox(height: AppTokens.space.s12),
            Wrap(
              spacing: AppTokens.space.s8,
              runSpacing: AppTokens.space.s6,
              children: [
                AppChip(
                  label: status.toUpperCase(),
                  selected: isActive || status == 'completed',
                  onSelected: (_) {},
                ),
                if (item.job.lastError != null)
                  Text(
                    item.job.lastError!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.destructive),
                  ),
              ],
            ),
            SizedBox(height: AppTokens.space.s12),
            AppProgress(
              progress: item.job.progress,
              label: _statusLabel(
                isQueued: isQueued,
                isPaused: isPaused,
                isFailed: isFailed,
                isSkipped: isSkipped,
                isCompleted: isCompleted,
                isMerging: isMerging,
                isRunningTool: isRunningTool,
                isExporting: isExporting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel({
  required bool isQueued,
  required bool isPaused,
  required bool isFailed,
  required bool isSkipped,
  required bool isCompleted,
  required bool isMerging,
  required bool isRunningTool,
  required bool isExporting,
}) {
  if (isQueued) {
    return 'Queued';
  }
  if (isPaused) {
    return 'Paused';
  }
  if (isFailed) {
    return 'Failed';
  }
  if (isSkipped) {
    return 'Skipped';
  }
  if (isCompleted) {
    return 'Completed';
  }
  if (isMerging) {
    return 'Merging';
  }
  if (isRunningTool) {
    return 'Running tool';
  }
  if (isExporting) {
    return 'Exporting';
  }
  return 'Downloading';
}

String _formatRateLimit(double? remaining, DateTime? resetAt) {
  final parts = <String>[];
  if (remaining != null) {
    parts.add('Remaining: ${remaining.toStringAsFixed(1)}');
  }
  if (resetAt != null) {
    final local = resetAt.toLocal();
    parts.add(
      'Resets: ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}',
    );
  }
  return parts.join(' • ');
}
