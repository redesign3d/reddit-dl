import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_database.dart';
import '../../data/logs_repository.dart';
import '../../data/queue_repository.dart';
import '../../data/settings_repository.dart';
import '../logs/log_record.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_chip.dart';
import '../../ui/components/app_progress.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import '../../utils/reveal_in_file_manager.dart';
import '../../utils/reveal_path_resolver.dart';
import 'queue_cubit.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QueueCubit, QueueState>(
      builder: (context, state) {
        final colors = context.appColors;
        final running = state.items
            .where((item) => item.job.status == 'running')
            .length;
        final failed = state.items
            .where((item) => item.job.status == 'failed')
            .length;
        final remaining = state.rateLimitRemaining;
        final resetAt = state.rateLimitResetAt;

        return SizedBox(
          height: _contentHeight(context),
          child: Column(
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
                    onPressed: () =>
                        context.read<QueueCubit>().togglePauseAll(),
                    variant: state.paused
                        ? AppButtonVariant.primary
                        : AppButtonVariant.secondary,
                  ),
                  SizedBox(width: AppTokens.space.s8),
                  AppButton(
                    label: 'Clear completed',
                    variant: AppButtonVariant.ghost,
                    onPressed:
                        state.items.any(
                          (item) => item.job.status == 'completed',
                        )
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
                Expanded(
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppTokens.space.s12,
                            AppTokens.space.s12,
                            AppTokens.space.s12,
                            index == state.items.length - 1
                                ? AppTokens.space.s12
                                : 0,
                          ),
                          child: _QueueItemCard(
                            key: ValueKey<int>(item.job.id),
                            item: item,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QueueItemCard extends StatefulWidget {
  const _QueueItemCard({super.key, required this.item});

  final QueueRecord item;

  @override
  State<_QueueItemCard> createState() => _QueueItemCardState();
}

class _QueueItemCardState extends State<_QueueItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final status = widget.item.job.status;
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
          await context.read<QueueCubit>().retryJob(widget.item.job.id);
          if (!context.mounted) {
            return;
          }
          AppToast.show(context, 'Retry queued.');
        }
        if (selection == 'reveal') {
          await _revealLatestOutput(context);
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
                        widget.item.item.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: AppTokens.space.s6),
                      Text(
                        'r/${widget.item.item.subreddit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppTokens.space.s8),
                AppChip(
                  label: status.toUpperCase(),
                  selected: isActive || status == 'completed',
                  onSelected: (_) {},
                ),
              ],
            ),
            SizedBox(height: AppTokens.space.s12),
            AppProgress(
              progress: widget.item.job.progress,
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
            SizedBox(height: AppTokens.space.s12),
            Wrap(
              spacing: AppTokens.space.s8,
              runSpacing: AppTokens.space.s8,
              children: [
                ..._buildPrimaryActions(
                  context,
                  isQueued: isQueued,
                  isPaused: isPaused,
                  isFailed: isFailed,
                  isSkipped: isSkipped,
                  isActive: isActive,
                  isCompleted: isCompleted,
                ),
                AppButton(
                  label: _expanded ? 'Hide details' : 'View details',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
            if (_expanded) ...[
              SizedBox(height: AppTokens.space.s12),
              Divider(color: colors.border),
              SizedBox(height: AppTokens.space.s12),
              _QueueItemDetailsDrawer(
                item: widget.item,
                phase: _phaseLabel(status),
                jobId: widget.item.job.id,
                onRetry: () =>
                    context.read<QueueCubit>().retryJob(widget.item.job.id),
                onReveal: () => _revealLatestOutput(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPrimaryActions(
    BuildContext context, {
    required bool isQueued,
    required bool isPaused,
    required bool isFailed,
    required bool isSkipped,
    required bool isActive,
    required bool isCompleted,
  }) {
    final actions = <Widget>[];
    if (isFailed || isSkipped) {
      actions.add(
        AppButton(
          label: 'Retry',
          variant: AppButtonVariant.secondary,
          onPressed: () =>
              context.read<QueueCubit>().retryJob(widget.item.job.id),
        ),
      );
    }
    if (isPaused) {
      actions.add(
        AppButton(
          label: 'Resume',
          variant: AppButtonVariant.secondary,
          onPressed: () =>
              context.read<QueueCubit>().resumeJob(widget.item.job.id),
        ),
      );
    }
    if (isQueued) {
      actions.add(
        AppButton(
          label: 'Pause',
          variant: AppButtonVariant.ghost,
          onPressed: () =>
              context.read<QueueCubit>().pauseJob(widget.item.job.id),
        ),
      );
    }
    if (!isCompleted && !isFailed && !isSkipped) {
      actions.add(
        AppButton(
          label: isActive ? 'Cancel running' : 'Cancel',
          variant: AppButtonVariant.ghost,
          onPressed: () =>
              context.read<QueueCubit>().cancelJob(widget.item.job.id),
        ),
      );
    }
    return actions;
  }

  Future<void> _revealLatestOutput(BuildContext context) async {
    final path = await resolveRevealPath(
      queueRepository: context.read<QueueRepository>(),
      settingsRepository: context.read<SettingsRepository>(),
      jobId: widget.item.job.id,
      savedItemId: widget.item.item.id,
      legacyOutputPath: widget.item.job.outputPath,
    );
    if (!context.mounted) {
      return;
    }
    if (path == null) {
      AppToast.show(
        context,
        'No output path available. Set Download root in Settings.',
      );
      return;
    }
    final success = await revealInFileManager(path);
    if (!context.mounted) {
      return;
    }
    AppToast.show(context, success ? 'Opened file manager.' : 'Reveal failed.');
  }
}

class _QueueItemDetailsDrawer extends StatelessWidget {
  const _QueueItemDetailsDrawer({
    required this.item,
    required this.phase,
    required this.jobId,
    required this.onRetry,
    required this.onReveal,
  });

  final QueueRecord item;
  final String phase;
  final int jobId;
  final Future<void> Function() onRetry;
  final Future<void> Function() onReveal;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current phase: $phase',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
        ),
        SizedBox(height: AppTokens.space.s12),
        Text('Recent logs', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: AppTokens.space.s6),
        _QueueJobLogsSection(jobId: jobId),
        SizedBox(height: AppTokens.space.s12),
        Text(
          'Produced outputs',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: AppTokens.space.s6),
        _QueueOutputsSection(jobId: jobId),
        SizedBox(height: AppTokens.space.s12),
        Text(
          'Technical details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: AppTokens.space.s6),
        _QueueTechnicalDetails(item: item),
        SizedBox(height: AppTokens.space.s12),
        Wrap(
          spacing: AppTokens.space.s8,
          runSpacing: AppTokens.space.s8,
          children: [
            AppButton(
              label: 'Retry',
              variant: AppButtonVariant.secondary,
              onPressed: () => onRetry(),
            ),
            AppButton(
              label: 'Reveal',
              variant: AppButtonVariant.ghost,
              onPressed: () => onReveal(),
            ),
            AppButton(
              label: 'Copy permalink',
              variant: AppButtonVariant.ghost,
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: item.item.permalink),
                );
                if (!context.mounted) {
                  return;
                }
                AppToast.show(context, 'Permalink copied.');
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _QueueJobLogsSection extends StatelessWidget {
  const _QueueJobLogsSection({required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return StreamBuilder<List<LogRecord>>(
      stream: context.read<LogsRepository>().watchByJobId(jobId, limit: 20),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const <LogRecord>[];
        if (entries.isEmpty) {
          return Text(
            'No logs for this job yet.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radii.md),
            border: Border.all(color: colors.border),
          ),
          padding: EdgeInsets.all(AppTokens.space.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries
                .map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(bottom: AppTokens.space.s6),
                    child: Text(
                      '${entry.timestamp.toLocal().toIso8601String()} [${entry.level.toUpperCase()}] ${entry.message}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.mutedForeground,
                        fontFamily: AppTokens.fontFamilyMono,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );
  }
}

class _QueueOutputsSection extends StatelessWidget {
  const _QueueOutputsSection({required this.jobId});

  final int jobId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return StreamBuilder<List<DownloadOutput>>(
      stream: context.read<QueueRepository>().watchOutputsForJob(jobId),
      builder: (context, snapshot) {
        final outputs = snapshot.data ?? const <DownloadOutput>[];
        if (outputs.isEmpty) {
          return Text(
            'No outputs recorded yet.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radii.md),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: outputs
                .map(
                  (output) => InkWell(
                    onTap: () => _revealOutputPath(context, output.path),
                    child: Padding(
                      padding: EdgeInsets.all(AppTokens.space.s8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.insert_drive_file, size: 16),
                          SizedBox(width: AppTokens.space.s8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  output.kind,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colors.mutedForeground),
                                ),
                                SizedBox(height: AppTokens.space.s4),
                                Text(
                                  output.path,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );
  }

  Future<void> _revealOutputPath(BuildContext context, String path) async {
    final success = await revealInFileManager(path);
    if (!context.mounted) {
      return;
    }
    AppToast.show(
      context,
      success ? 'Opened file manager.' : 'Unable to reveal output path.',
    );
  }
}

class _QueueTechnicalDetails extends StatelessWidget {
  const _QueueTechnicalDetails({required this.item});

  final QueueRecord item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FutureBuilder<List<MediaAsset>>(
      future: context.read<QueueRepository>().fetchMediaAssets(item.item.id),
      builder: (context, snapshot) {
        final assets = snapshot.data ?? const <MediaAsset>[];
        final firstAsset = assets.isEmpty ? null : assets.first;
        final primaryUrl = _primaryUrl(firstAsset);
        final toolHints = assets
            .map((asset) => asset.toolHint.trim())
            .where((hint) => hint.isNotEmpty)
            .toSet()
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailsLine(context, 'URL', primaryUrl ?? 'Not available'),
            SizedBox(height: AppTokens.space.s4),
            _detailsLine(
              context,
              'Tool',
              toolHints.isEmpty ? 'none' : toolHints.join(', '),
            ),
            SizedBox(height: AppTokens.space.s4),
            _detailsLine(
              context,
              'Last error',
              item.job.lastError?.trim().isNotEmpty == true
                  ? item.job.lastError!
                  : 'none',
              valueColor: item.job.lastError?.trim().isNotEmpty == true
                  ? colors.destructive
                  : colors.mutedForeground,
            ),
          ],
        );
      },
    );
  }

  String? _primaryUrl(MediaAsset? asset) {
    if (asset == null) {
      return null;
    }
    if (asset.normalizedUrl.trim().isNotEmpty) {
      return asset.normalizedUrl;
    }
    if (asset.sourceUrl.trim().isNotEmpty) {
      return asset.sourceUrl;
    }
    return null;
  }

  Widget _detailsLine(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final colors = context.appColors;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
          ),
          TextSpan(
            text: value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: valueColor ?? colors.foreground,
            ),
          ),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
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

String _phaseLabel(String status) {
  switch (status) {
    case 'merging':
      return 'merge';
    case 'running_tool':
      return 'tool';
    case 'exporting':
      return 'export';
    default:
      return 'download';
  }
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

double _contentHeight(BuildContext context) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  final reserved =
      AppTokens.layout.titleBarHeight +
      AppTokens.space.s20 * 2 +
      AppTokens.space.s16;
  return math.max(560, screenHeight - reserved);
}
