import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/logs_repository.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_select.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import '../logs/log_record.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  bool _loggedIn = false;
  DateTime? _lastSyncedAt;
  String _timeframe = 'All time';
  final TextEditingController _maxItemsController = TextEditingController();

  @override
  void dispose() {
    _maxItemsController.dispose();
    super.dispose();
  }

  Future<void> _runSyncStub(BuildContext context) async {
    await context.read<LogsRepository>().add(
          LogRecord(
            timestamp: DateTime.now(),
            scope: 'sync',
            level: 'warn',
            message: 'Sync flow not implemented yet.',
          ),
        );
    setState(() {
      _lastSyncedAt = DateTime.now();
    });
    AppToast.show(context, 'Sync not implemented yet.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent sync (no tokens required)',
            style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: AppTokens.space.s6),
        Text(
          'Log in to old.reddit.com and sync saved items without developer credentials.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colors.mutedForeground),
        ),
        SizedBox(height: AppTokens.space.s16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Login session',
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: AppTokens.space.s6),
              Text(
                _loggedIn
                    ? 'Logged in as u/archivist (mock).'
                    : 'Not logged in yet.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.mutedForeground),
              ),
              SizedBox(height: AppTokens.space.s12),
              Wrap(
                spacing: AppTokens.space.s8,
                runSpacing: AppTokens.space.s8,
                children: [
                  AppButton(
                    label: _loggedIn ? 'Logged in' : 'Open login',
                    onPressed: () {
                      setState(() {
                        _loggedIn = true;
                      });
                      AppToast.show(context, 'Login session captured.');
                    },
                  ),
                  if (_loggedIn)
                    AppButton(
                      label: 'Log out',
                      variant: AppButtonVariant.ghost,
                      onPressed: () {
                        setState(() {
                          _loggedIn = false;
                        });
                        AppToast.show(context, 'Session cleared.');
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppTokens.space.s16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sync controls',
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: AppTokens.space.s12),
              Row(
                children: [
                  Expanded(
                    child: AppSelect<String>(
                      label: 'Timeframe',
                      value: _timeframe,
                      options: const [
                        AppSelectOption(label: 'All time', value: 'All time'),
                        AppSelectOption(
                            label: 'Last 90 days', value: 'Last 90 days'),
                        AppSelectOption(
                            label: 'Last 30 days', value: 'Last 30 days'),
                        AppSelectOption(label: 'Last 7 days', value: 'Last 7 days'),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _timeframe = value ?? 'All time';
                        });
                      },
                    ),
                  ),
                  SizedBox(width: AppTokens.space.s12),
                  Expanded(
                    child: AppTextField(
                      label: 'Max items',
                      hint: 'Unlimited',
                      controller: _maxItemsController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTokens.space.s12),
              AppButton(
                label: 'Run sync',
                onPressed: _loggedIn ? () => _runSyncStub(context) : null,
              ),
              if (_lastSyncedAt != null) ...[
                SizedBox(height: AppTokens.space.s8),
                Text(
                  'Last sync attempt: ${_lastSyncedAt!.toLocal()} (stub).',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.mutedForeground),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
