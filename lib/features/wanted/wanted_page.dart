import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/logs_repository.dart';
import '../../data/queue_repository.dart';
import '../../navigation/app_section.dart';
import '../../navigation/navigation_cubit.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import '../logs/log_record.dart';
import 'wanted_cubit.dart';

class WantedPage extends StatelessWidget {
  const WantedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WantedCubit, WantedState>(
      builder: (context, state) {
        final colors = context.appColors;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wanted', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: AppTokens.space.s6),
                  Text(
                    '${state.items.length} items need attention',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppTokens.space.s16),
            if (state.items.isEmpty)
              AppCard(
                child: Text(
                  'No wanted items right now.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              Column(
                children:
                    state.items
                        .map(
                          (record) => Padding(
                            padding: EdgeInsets.only(
                              bottom: AppTokens.space.s12,
                            ),
                            child: _WantedCard(record: record),
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

class _WantedCard extends StatelessWidget {
  const _WantedCard({required this.record});

  final WantedRecord record;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reasonLabel = _reasonLabel(record.reason);
    final job = record.job;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.item.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: AppTokens.space.s6),
          Text(
            '${record.item.subreddit} • $reasonLabel',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
          ),
          if (job?.lastError != null && job!.lastError!.isNotEmpty) ...[
            SizedBox(height: AppTokens.space.s6),
            Text(job.lastError!, style: Theme.of(context).textTheme.bodySmall),
          ],
          SizedBox(height: AppTokens.space.s12),
          Wrap(
            spacing: AppTokens.space.s8,
            runSpacing: AppTokens.space.s8,
            children: _buildActions(context, record),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context, WantedRecord record) {
    final actions = <Widget>[];
    final job = record.job;

    if (record.reason == WantedReason.missingTool ||
        record.reason == WantedReason.nsfw) {
      actions.add(
        AppButton(
          label: 'Open Settings',
          variant: AppButtonVariant.secondary,
          onPressed: () {
            context.read<NavigationCubit>().select(AppSection.settings);
            _log(context, 'Opened settings from wanted.');
          },
        ),
      );
    }

    if (job != null && job.status == 'failed') {
      actions.add(
        AppButton(
          label: 'Retry job',
          onPressed: () async {
            await context.read<QueueRepository>().retryJob(job.id);
            if (!context.mounted) {
              return;
            }
            _log(context, 'Retry requested for job ${job.id}.');
            AppToast.show(context, 'Retry queued.');
          },
        ),
      );
    }

    if (job == null && record.reason == WantedReason.noMedia) {
      actions.add(
        AppButton(
          label: 'Open Library',
          variant: AppButtonVariant.ghost,
          onPressed: () {
            context.read<NavigationCubit>().select(AppSection.library);
            _log(context, 'Opened library from wanted.');
          },
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(
        AppButton(
          label: 'Open Library',
          variant: AppButtonVariant.secondary,
          onPressed: () {
            context.read<NavigationCubit>().select(AppSection.library);
            _log(context, 'Opened library from wanted.');
          },
        ),
      );
    }

    return actions;
  }

  String _reasonLabel(WantedReason reason) {
    switch (reason) {
      case WantedReason.nsfw:
        return 'NSFW download blocked';
      case WantedReason.missingTool:
        return 'Missing external tool';
      case WantedReason.repeatedFailures:
        return 'Repeated failures';
      case WantedReason.noMedia:
        return 'No media extracted';
    }
  }

  void _log(BuildContext context, String message) {
    context.read<LogsRepository>().add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: 'wanted',
        level: 'info',
        message: message,
      ),
    );
  }
}
