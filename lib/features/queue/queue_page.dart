import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        final running = state.items
            .where((item) => item.status == QueueStatus.running)
            .length;
        final failed = state.items
            .where((item) => item.status == QueueStatus.failed)
            .length;

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
                        Text('Queue status',
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(height: AppTokens.space.s6),
                        Text(
                          '${state.items.length} total • $running running • $failed failed',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
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
                        Text('Rate limits',
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(height: AppTokens.space.s6),
                        Text(
                          'Safe mode • 2 concurrency',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.mutedForeground),
                        ),
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
                  variant: state.paused
                      ? AppButtonVariant.primary
                      : AppButtonVariant.secondary,
                ),
                SizedBox(width: AppTokens.space.s8),
                AppButton(
                  label: 'Clear completed',
                  variant: AppButtonVariant.ghost,
                  onPressed: state.items.any(
                          (item) => item.status == QueueStatus.completed)
                      ? () => context.read<QueueCubit>().clearCompleted()
                      : null,
                ),
                const Spacer(),
                AppButton(
                  label: 'Copy queue summary',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    final summary = state.items
                        .map((item) =>
                            '${item.status.name.toUpperCase()} • ${item.title}')
                        .join('\n');
                    Clipboard.setData(ClipboardData(text: summary));
                    AppToast.show(context, 'Queue summary copied.');
                  },
                ),
              ],
            ),
            SizedBox(height: AppTokens.space.s16),
            Column(
              children: state.items
                  .map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: AppTokens.space.s12),
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

  final QueueItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
            PopupMenuItem(value: 'reveal', child: Text('Reveal in Finder/Explorer')),
          ],
        );
        if (!context.mounted) {
          return;
        }
        if (selection == 'retry') {
          context.read<QueueCubit>().retryItem(item.id);
          AppToast.show(context, 'Retry queued.');
        }
        if (selection == 'reveal') {
          final success =
              await revealInFileManager(Directory.systemTemp.path);
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
                        item.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: AppTokens.space.s6),
                      Text(
                        'r/${item.subreddit}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                if (item.status == QueueStatus.failed)
                  AppButton(
                    label: 'Retry',
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        context.read<QueueCubit>().retryItem(item.id),
                  )
                else
                  AppButton(
                    label: 'Mark done',
                    variant: AppButtonVariant.ghost,
                    onPressed: () =>
                        context.read<QueueCubit>().markComplete(item.id),
                  ),
              ],
            ),
            SizedBox(height: AppTokens.space.s12),
            Wrap(
              spacing: AppTokens.space.s8,
              runSpacing: AppTokens.space.s6,
              children: [
                AppChip(
                  label: item.status.name.toUpperCase(),
                  selected: item.status == QueueStatus.running,
                  onSelected: (_) {},
                ),
                if (item.error != null)
                  Text(
                    item.error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.destructive),
                  ),
              ],
            ),
            SizedBox(height: AppTokens.space.s12),
            AppProgress(
              progress: item.progress,
              label: item.status == QueueStatus.failed
                  ? 'Download stalled'
                  : 'Download progress',
            ),
          ],
        ),
      ),
    );
  }
}
