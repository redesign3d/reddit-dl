import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/settings_repository.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_select.dart';
import '../../ui/components/app_switch.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import 'settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _downloadRootController;

  @override
  void initState() {
    super.initState();
    _downloadRootController = TextEditingController();
  }

  @override
  void dispose() {
    _downloadRootController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.settings.downloadRoot != current.settings.downloadRoot,
      listener: (context, state) {
        _downloadRootController.text = state.settings.downloadRoot;
      },
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = state.settings;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preferences',
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: AppTokens.space.s16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance',
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: AppTokens.space.s12),
                    AppSwitch(
                      label: 'Dark mode',
                      description: 'Match Claude-style dark palette.',
                      value: settings.themeMode == AppThemeMode.dark,
                      onChanged: (value) =>
                          context.read<SettingsCubit>().updateThemeMode(
                                value ? AppThemeMode.dark : AppThemeMode.light,
                              ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTokens.space.s16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Downloads',
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: AppTokens.space.s12),
                    AppTextField(
                      label: 'Download root',
                      hint: 'Select a folder',
                      controller: _downloadRootController,
                      onChanged: (value) =>
                          context.read<SettingsCubit>().updateDownloadRoot(value),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.folder_open_outlined),
                        onPressed: () => AppToast.show(
                          context,
                          'Folder picker coming next phase.',
                        ),
                      ),
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    AppSelect<OverwritePolicy>(
                      label: 'Overwrite policy',
                      value: settings.overwritePolicy,
                      options: const [
                        AppSelectOption(
                          label: 'Skip if exists',
                          value: OverwritePolicy.skipIfExists,
                        ),
                        AppSelectOption(
                          label: 'Overwrite if newer',
                          value: OverwritePolicy.overwriteIfNewer,
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        context.read<SettingsCubit>().updateOverwritePolicy(value);
                      },
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    AppSwitch(
                      label: 'Download NSFW',
                      description: 'Enabled only when explicitly allowed.',
                      value: settings.downloadNsfw,
                      onChanged: (value) =>
                          context.read<SettingsCubit>().updateDownloadNsfw(value),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTokens.space.s16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sessions',
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: AppTokens.space.s12),
                    AppSwitch(
                      label: 'Remember login session',
                      description: 'Persist cookies in app data (optional).',
                      value: settings.rememberSession,
                      onChanged: (value) => context
                          .read<SettingsCubit>()
                          .updateRememberSession(value),
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    Row(
                      children: [
                        AppButton(
                          label: 'Clear cookies',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => AppToast.show(
                            context,
                            'Cookie jar cleared (mock).',
                          ),
                        ),
                        SizedBox(width: AppTokens.space.s8),
                        AppButton(
                          label: 'Open cache folder',
                          variant: AppButtonVariant.ghost,
                          onPressed: () => AppToast.show(
                            context,
                            'Cache folder opened (mock).',
                          ),
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
                    Text('External tools',
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: AppTokens.space.s6),
                    Text(
                      'Detect gallery-dl and yt-dlp on PATH, or set manual overrides.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.mutedForeground),
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    Row(
                      children: [
                        Expanded(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('gallery-dl',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                SizedBox(height: AppTokens.space.s6),
                                Text(
                                  'Not detected',
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
                                Text('yt-dlp',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                SizedBox(height: AppTokens.space.s6),
                                Text(
                                  'Not detected',
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
                    SizedBox(height: AppTokens.space.s12),
                    Wrap(
                      spacing: AppTokens.space.s8,
                      runSpacing: AppTokens.space.s8,
                      children: [
                        AppButton(
                          label: 'Install commands',
                          onPressed: () => AppToast.show(
                            context,
                            'Commands copied (mock).',
                          ),
                        ),
                        AppButton(
                          label: 'Set tool paths',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => AppToast.show(
                            context,
                            'Override paths (mock).',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
