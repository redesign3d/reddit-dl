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
import '../library/library_cubit.dart';
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
            final currentStep = syncUiStepFromState(syncState);
            if (_usernameController.text.isEmpty &&
                syncState.username != null) {
              _usernameController.text = syncState.username!;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Stepper',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: AppTokens.space.s6),
                Text(
                  'Follow each step to log in, validate session, scan saved pages, resolve JSON, and review summary.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                SizedBox(height: AppTokens.space.s16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 980;
                    if (!isWide) {
                      return Column(
                        children: [
                          _SyncStepperRail(currentStep: currentStep),
                          SizedBox(height: AppTokens.space.s12),
                          _SyncStepContent(
                            state: syncState,
                            rememberSession: rememberSession,
                            rateLimitPerMinute:
                                settingsState.settings.rateLimitPerMinute,
                            maxItemsController: _maxItemsController,
                            usernameController: _usernameController,
                            timeframeDays: _timeframeDays,
                            parseMaxItems: _parseMaxItems,
                            onTimeframeChanged: (value) {
                              setState(() {
                                _timeframeDays = value;
                              });
                            },
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 280,
                          child: _SyncStepperRail(currentStep: currentStep),
                        ),
                        SizedBox(width: AppTokens.space.s12),
                        Expanded(
                          child: _SyncStepContent(
                            state: syncState,
                            rememberSession: rememberSession,
                            rateLimitPerMinute:
                                settingsState.settings.rateLimitPerMinute,
                            maxItemsController: _maxItemsController,
                            usernameController: _usernameController,
                            timeframeDays: _timeframeDays,
                            parseMaxItems: _parseMaxItems,
                            onTimeframeChanged: (value) {
                              setState(() {
                                _timeframeDays = value;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SyncStepperRail extends StatelessWidget {
  const _SyncStepperRail({required this.currentStep});

  final SyncUiStep currentStep;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final definitions = _stepDefinitions;
    final currentIndex = definitions.indexWhere(
      (entry) => entry.step == currentStep,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Steps', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: AppTokens.space.s12),
          ...definitions.asMap().entries.map((entry) {
            final index = entry.key;
            final definition = entry.value;
            final isCurrent = index == currentIndex;
            final isDone = index < currentIndex;
            final indicatorColor = isCurrent
                ? colors.sidebarAccent
                : isDone
                ? colors.sidebarForeground
                : colors.border;
            return Padding(
              padding: EdgeInsets.only(bottom: AppTokens.space.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: AppTokens.space.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          definition.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: AppTokens.space.s2),
                        Text(
                          definition.subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SyncStepContent extends StatelessWidget {
  const _SyncStepContent({
    required this.state,
    required this.rememberSession,
    required this.rateLimitPerMinute,
    required this.maxItemsController,
    required this.usernameController,
    required this.timeframeDays,
    required this.parseMaxItems,
    required this.onTimeframeChanged,
  });

  final SyncState state;
  final bool rememberSession;
  final int rateLimitPerMinute;
  final TextEditingController maxItemsController;
  final TextEditingController usernameController;
  final int? timeframeDays;
  final int? Function() parseMaxItems;
  final ValueChanged<int?> onTimeframeChanged;

  @override
  Widget build(BuildContext context) {
    final step = syncUiStepFromState(state);
    switch (step) {
      case SyncUiStep.login:
        return _buildLoginStep(context);
      case SyncUiStep.validateSession:
        return _buildValidateStep(context);
      case SyncUiStep.scanSavedPages:
        return _buildScanStep(context);
      case SyncUiStep.resolveJson:
        return _buildResolveStep(context);
      case SyncUiStep.summary:
        return _buildSummaryStep(context);
    }
  }

  Widget _buildLoginStep(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1) Login', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: AppTokens.space.s12),
          AppSwitch(
            label: 'Remember session',
            description: 'Persist cookies for future syncs.',
            value: rememberSession,
            onChanged: (value) {
              context.read<SettingsCubit>().updateRememberSession(value);
              context.read<SyncCubit>().updateRememberSession(value);
            },
          ),
          SizedBox(height: AppTokens.space.s12),
          Wrap(
            spacing: AppTokens.space.s8,
            runSpacing: AppTokens.space.s8,
            children: [
              AppButton(
                label: state.loginVisible ? 'Login open' : 'Start login',
                onPressed: state.loginVisible
                    ? null
                    : () => context.read<SyncCubit>().prepareLogin(
                        rememberSession: rememberSession,
                      ),
              ),
              AppButton(
                label: 'Continue',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.read<SyncCubit>().checkSession(
                  rememberSession: rememberSession,
                ),
              ),
              AppButton(
                label: 'Clear session',
                variant: AppButtonVariant.ghost,
                onPressed: () async {
                  await context.read<SyncCubit>().clearSession(
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
          if (state.loginVisible) ...[
            SizedBox(height: AppTokens.space.s12),
            Row(
              children: [
                Text(
                  'Login WebView',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                AppButton(
                  label: 'Close',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => context.read<SyncCubit>().hideLogin(),
                ),
              ],
            ),
            SizedBox(height: AppTokens.space.s8),
            SizedBox(
              height: 420,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radii.lg),
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri('https://old.reddit.com/login'),
                  ),
                ),
              ),
            ),
          ],
          if (state.errorMessage != null) ...[
            SizedBox(height: AppTokens.space.s12),
            _ErrorText(message: state.errorMessage!),
          ],
        ],
      ),
    );
  }

  Widget _buildValidateStep(BuildContext context) {
    final colors = context.appColors;
    final cookieStatus = state.sessionCookieCount > 0
        ? '${state.sessionCookieCount} cookies detected'
        : 'No session cookies detected';
    final savedAccess = switch (state.savedAccessOk) {
      true => 'Saved listing access OK',
      false => 'Saved listing access failed',
      null => 'Saved listing access not checked',
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2) Validate session',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: AppTokens.space.s12),
          Text(
            'Detected username: ${state.username ?? 'not detected'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: AppTokens.space.s4),
          Text(
            'Cookie status: $cookieStatus',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
          ),
          SizedBox(height: AppTokens.space.s4),
          Text(
            'Diagnostics: $savedAccess',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: state.savedAccessOk == false
                  ? colors.destructive
                  : colors.mutedForeground,
            ),
          ),
          SizedBox(height: AppTokens.space.s12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Username',
                  hint: 'u/username',
                  controller: usernameController,
                  onChanged: (value) =>
                      context.read<SyncCubit>().updateManualUsername(value),
                ),
              ),
              SizedBox(width: AppTokens.space.s12),
              Expanded(
                child: AppTextField(
                  label: 'Max items',
                  hint: 'Unlimited',
                  controller: maxItemsController,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTokens.space.s12),
          AppSelect<int?>(
            label: 'Timeframe',
            value: timeframeDays,
            options: const [
              AppSelectOption(label: 'All time', value: null),
              AppSelectOption(label: 'Last 7 days', value: 7),
              AppSelectOption(label: 'Last 30 days', value: 30),
              AppSelectOption(label: 'Last 90 days', value: 90),
              AppSelectOption(label: 'Last 365 days', value: 365),
            ],
            onChanged: onTimeframeChanged,
          ),
          SizedBox(height: AppTokens.space.s12),
          Wrap(
            spacing: AppTokens.space.s8,
            runSpacing: AppTokens.space.s8,
            children: [
              AppButton(
                label: 'Re-check session',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.read<SyncCubit>().checkSession(
                  rememberSession: rememberSession,
                ),
              ),
              AppButton(
                label: 'Continue to scan',
                onPressed: state.sessionValid
                    ? () => context.read<SyncCubit>().startSync(
                        rememberSession: rememberSession,
                        rateLimitPerMinute: rateLimitPerMinute,
                        maxItems: parseMaxItems(),
                        timeframeDays: timeframeDays,
                      )
                    : null,
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            SizedBox(height: AppTokens.space.s12),
            _ErrorText(message: state.errorMessage!),
          ],
        ],
      ),
    );
  }

  Widget _buildScanStep(BuildContext context) {
    final progress = state.progress;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3) Scan saved pages',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: AppTokens.space.s12),
          AppProgress(
            progress: 0,
            label: state.isCancelling
                ? 'Cancelling...'
                : 'Scanning listing pages',
          ),
          SizedBox(height: AppTokens.space.s12),
          Wrap(
            spacing: AppTokens.space.s12,
            runSpacing: AppTokens.space.s12,
            children: [
              _StatTile(
                label: 'Current page',
                value: progress.pagesScanned.toString(),
              ),
              _StatTile(
                label: 'Collected permalinks',
                value: progress.permalinksFound.toString(),
              ),
              _StatTile(
                label: 'Rate status',
                value: progress.retryAfterSeconds == null
                    ? 'normal'
                    : 'retry ${progress.retryAfterSeconds}s',
              ),
            ],
          ),
          SizedBox(height: AppTokens.space.s12),
          AppButton(
            label: state.isCancelling ? 'Stopping...' : 'Cancel',
            variant: AppButtonVariant.secondary,
            onPressed: state.isCancelling
                ? null
                : () => context.read<SyncCubit>().cancelSync(),
          ),
        ],
      ),
    );
  }

  Widget _buildResolveStep(BuildContext context) {
    final progress = state.progress;
    final total = progress.permalinksFound > 0
        ? progress.permalinksFound
        : (progress.resolved + progress.failures);
    final ratio = total > 0
        ? (progress.resolved / total).clamp(0, 1).toDouble()
        : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '4) Resolve JSON',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: AppTokens.space.s12),
          AppProgress(
            progress: ratio,
            label:
                '${progress.resolved} / ${total == 0 ? '?' : total} resolved',
          ),
          SizedBox(height: AppTokens.space.s12),
          Wrap(
            spacing: AppTokens.space.s12,
            runSpacing: AppTokens.space.s12,
            children: [
              _StatTile(label: 'Resolved', value: progress.resolved.toString()),
              _StatTile(label: 'Errors', value: progress.failures.toString()),
              _StatTile(label: 'Upserted', value: progress.upserted.toString()),
            ],
          ),
          SizedBox(height: AppTokens.space.s12),
          Wrap(
            spacing: AppTokens.space.s8,
            runSpacing: AppTokens.space.s8,
            children: [
              AppButton(
                label: state.isCancelling ? 'Stopping...' : 'Cancel',
                variant: AppButtonVariant.secondary,
                onPressed:
                    state.phase == SyncPhase.syncing && !state.isCancelling
                    ? () => context.read<SyncCubit>().cancelSync()
                    : null,
              ),
              AppButton(
                label: 'Retry failed',
                variant: AppButtonVariant.ghost,
                onPressed:
                    state.phase == SyncPhase.syncing ||
                        state.failedPermalinks.isEmpty
                    ? null
                    : () => context.read<SyncCubit>().retryFailedResolutions(
                        rememberSession: rememberSession,
                        rateLimitPerMinute: rateLimitPerMinute,
                      ),
              ),
            ],
          ),
          SizedBox(height: AppTokens.space.s12),
          _RecentErrors(errors: state.recentErrors),
        ],
      ),
    );
  }

  Widget _buildSummaryStep(BuildContext context) {
    final summary = state.summary;
    if (summary == null) {
      return AppCard(
        child: Text(
          'No summary available yet.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('5) Summary', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: AppTokens.space.s12),
          Wrap(
            spacing: AppTokens.space.s12,
            runSpacing: AppTokens.space.s12,
            children: [
              _StatTile(label: 'New items', value: summary.inserted.toString()),
              _StatTile(
                label: 'Updated items',
                value: summary.updated.toString(),
              ),
              _StatTile(label: 'Failures', value: summary.failures.toString()),
            ],
          ),
          SizedBox(height: AppTokens.space.s12),
          Wrap(
            spacing: AppTokens.space.s8,
            runSpacing: AppTokens.space.s8,
            children: [
              AppButton(
                label: 'Open Library filtered to new items',
                onPressed: () {
                  context.read<LibraryCubit>().focusOnItemIds(
                    summary.insertedItemIds,
                  );
                  context.read<NavigationCubit>().select(AppSection.library);
                },
              ),
              AppButton(
                label: 'Retry failed',
                variant: AppButtonVariant.ghost,
                onPressed: state.failedPermalinks.isEmpty
                    ? null
                    : () => context.read<SyncCubit>().retryFailedResolutions(
                        rememberSession: rememberSession,
                        rateLimitPerMinute: rateLimitPerMinute,
                      ),
              ),
            ],
          ),
          SizedBox(height: AppTokens.space.s12),
          _RecentErrors(errors: state.recentErrors),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: context.appColors.destructive),
    );
  }
}

class _RecentErrors extends StatelessWidget {
  const _RecentErrors({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (errors.isEmpty) {
      return Text(
        'No recent errors.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent errors', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: AppTokens.space.s6),
        ...errors.map(
          (error) => Padding(
            padding: EdgeInsets.only(bottom: AppTokens.space.s4),
            child: Text(
              error,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.destructive),
            ),
          ),
        ),
      ],
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _SyncStepDefinition {
  const _SyncStepDefinition({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final SyncUiStep step;
  final String title;
  final String subtitle;
}

const _stepDefinitions = [
  _SyncStepDefinition(
    step: SyncUiStep.login,
    title: 'Login',
    subtitle: 'Open WebView and authenticate.',
  ),
  _SyncStepDefinition(
    step: SyncUiStep.validateSession,
    title: 'Validate session',
    subtitle: 'Confirm username, cookies, and /saved access.',
  ),
  _SyncStepDefinition(
    step: SyncUiStep.scanSavedPages,
    title: 'Scan saved pages',
    subtitle: 'Collect permalinks and monitor rate status.',
  ),
  _SyncStepDefinition(
    step: SyncUiStep.resolveJson,
    title: 'Resolve JSON',
    subtitle: 'Resolve permalinks into normalized items.',
  ),
  _SyncStepDefinition(
    step: SyncUiStep.summary,
    title: 'Summary',
    subtitle: 'Review new/updated items and next actions.',
  ),
];
