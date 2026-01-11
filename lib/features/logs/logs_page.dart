import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ui/components/app_card.dart';
import '../../ui/components/log_viewer.dart';
import '../../ui/tokens.dart';
import 'logs_cubit.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity stream', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: AppTokens.space.s8),
        Text(
          'Logs are persisted and filterable. Export and copy from here.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
        ),
        SizedBox(height: AppTokens.space.s16),
        BlocBuilder<LogsCubit, LogsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.entries.isEmpty) {
              return AppCard(
                child: Text(
                  'No logs yet. Start an import or sync to populate activity.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            return LogViewer(entries: state.entries);
          },
        ),
      ],
    );
  }
}
