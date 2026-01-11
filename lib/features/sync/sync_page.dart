import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../navigation/app_section.dart';
import '../../navigation/navigation_cubit.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_progress.dart';
import '../../ui/components/app_select.dart';
import '../../ui/components/app_switch.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import '../settings/settings_cubit.dart';
import 'sync_cubit.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final TextEditingController _maxItemsController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  int? _timeframeDays;

  @override
  void dispose() {
    _maxItemsController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  int? _parseMaxItems() {
    final value = int.tryParse(_maxItemsController.text.trim());
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final rememberSession = settingsState.settings.rememberSession;
        return BlocBuilder<SyncCubit, SyncState>(
          builder: (context, syncState) {
            final progress = syncState.progress;
            final summary = syncState.summary;
            final maxItems = _parseMaxItems();
            final processed = progress.resolved + progress.failures;
            final progressValue = maxItems != null && maxItems > 0
                ? (processed / maxItems).clamp(0, 1).toDouble()
                : 0.0;

            if (_usernameController.text.isEmpty &&
                syncState.username != null) {
              _usernameController.text = syncState.username!;
            }

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
                      Text('Session',
                          style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: AppTokens.space.s12),
                      AppSwitch(
                        label: 'Remember me',
                        description:
                            'Persist cookies in app data for future syncs.',
                        value: rememberSession,
                        onChanged: (value) {
                          context
                              .read<SettingsCubit>()
                              .updateRememberSession(value);
                          context
                              .read<SyncCubit>()
                              .updateRememberSession(value);
                        },
                      ),
                      SizedBox(height: AppTokens.space.s12),
                      Text(
                        syncState.sessionValid
                            ? 'Session OK${syncState.username == null ? '' : ' • u/${syncState.username}'}'
                            : 'Session not validated yet.',
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
                            label: syncState.loginVisible
                                ? 'Login open'
                                : 'Start login',
                            onPressed: syncState.loginVisible
                                ? null
                                : () => context
                                    .read<SyncCubit>()
                                    .prepareLogin(
                                      rememberSession: rememberSession,
                                    ),
                          ),
                          AppButton(
                            label: 'Check session',
                            variant: AppButtonVariant.secondary,
                            onPressed: () => context
                                .read<SyncCubit>()
                                .checkSession(
                                  rememberSession: rememberSession,
                                ),
                          ),
                          AppButton(
                            label: 'Clear session',
                            variant: AppButtonVariant.ghost,
                            onPressed: () async {
                              await context
                                  .read<SyncCubit>()
                                  .clearSession(
                                    rememberSession: rememberSession,
                                  );
                              if (!context.mounted) {
                                return;
                              }
                              AppToast.show(context, 'Session cleared.');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (syncState.loginVisible) ...[
                  SizedBox(height: AppTokens.space.s16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Login window',
                                style: Theme.of(context).textTheme.titleLarge),
                            const Spacer(),
                            AppButton(
                              label: 'Close',
                              variant: AppButtonVariant.ghost,
                              onPressed: () =>
                                  context.read<SyncCubit>().hideLogin(),
                            ),
                          ],
                        ),
                        SizedBox(height: AppTokens.space.s12),
                        SizedBox(
                          height: 420,
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radii.lg),
                            child: InAppWebView(
                              initialUrlRequest: URLRequest(
                                url: WebUri('https://old.reddit.com/login'),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppTokens.space.s12),
                        AppButton(
                          label: 'Finish login',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => context
                              .read<SyncCubit>()
                              .checkSession(
                                rememberSession: rememberSession,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                            child: AppTextField(
                              label: 'Username',
                              hint: 'u/username',
                              controller: _usernameController,
                              onChanged: (value) => context
                                  .read<SyncCubit>()
                                  .updateManualUsername(value),
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
                      AppSelect<int?>(
                        label: 'Timeframe',
                        value: _timeframeDays,
                        options: const [
                          AppSelectOption(label: 'All time', value: null),
                          AppSelectOption(label: 'Last 7 days', value: 7),
                          AppSelectOption(label: 'Last 30 days', value: 30),
                          AppSelectOption(label: 'Last 90 days', value: 90),
                          AppSelectOption(label: 'Last 365 days', value: 365),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _timeframeDays = value;
                          });
                        },
                      ),
                      SizedBox(height: AppTokens.space.s12),
                      Wrap(
                        spacing: AppTokens.space.s8,
                        runSpacing: AppTokens.space.s8,
                        children: [
                          AppButton(
                            label: syncState.phase == SyncPhase.syncing
                                ? 'Syncing...'
                                : 'Start sync',
                            onPressed: syncState.phase == SyncPhase.syncing
                                ? null
                                : () => context.read<SyncCubit>().startSync(
                                      rememberSession: rememberSession,
                                      rateLimitPerMinute: settingsState
                                          .settings.rateLimitPerMinute,
                                      maxItems: _parseMaxItems(),
                                      timeframeDays: _timeframeDays,
                                    ),
                          ),
                          AppButton(
                            label: syncState.isCancelling
                                ? 'Stopping...'
                                : 'Stop sync',
                            variant: AppButtonVariant.secondary,
                            onPressed:
                                syncState.phase == SyncPhase.syncing &&
                                        !syncState.isCancelling
                                    ? () => context.read<SyncCubit>().cancelSync()
                                    : null,
                          ),
                          if (syncState.phase == SyncPhase.completed &&
                              summary != null)
                            AppButton(
                              label: 'Open library',
                              variant: AppButtonVariant.ghost,
                              onPressed: () => context
                                  .read<NavigationCubit>()
                                  .select(AppSection.library),
                            ),
                        ],
                      ),
                      if (syncState.errorMessage != null) ...[
                        SizedBox(height: AppTokens.space.s12),
                        Text(
                          syncState.errorMessage!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.destructive),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: AppTokens.space.s16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progress',
                          style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: AppTokens.space.s12),
                      AppProgress(
                        progress: progressValue,
                        label: syncState.phase == SyncPhase.syncing
                            ? 'Sync in progress'
                            : 'Idle',
                      ),
                      SizedBox(height: AppTokens.space.s12),
                      Wrap(
                        spacing: AppTokens.space.s12,
                        runSpacing: AppTokens.space.s12,
                        children: [
                          _StatTile(
                            label: 'Pages scanned',
                            value: progress.pagesScanned.toString(),
                          ),
                          _StatTile(
                            label: 'Permalinks found',
                            value: progress.permalinksFound.toString(),
                          ),
                          _StatTile(
                            label: 'Resolved',
                            value: progress.resolved.toString(),
                          ),
                          _StatTile(
                            label: 'Upserted',
                            value: progress.upserted.toString(),
                          ),
                          _StatTile(
                            label: 'Failures',
                            value: progress.failures.toString(),
                          ),
                          _StatTile(
                            label: 'Media assets',
                            value: progress.mediaInserted.toString(),
                          ),
                        ],
                      ),
                      if (progress.retryAfterSeconds != null) ...[
                        SizedBox(height: AppTokens.space.s12),
                        Text(
                          'Rate limited. Retrying in ${progress.retryAfterSeconds}s.',
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
          },
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: AppTokens.space.s4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
