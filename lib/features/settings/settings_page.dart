import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme_cubit.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_select.dart';
import '../../ui/components/app_switch.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _downloadNsfw = false;
  bool _rememberSession = false;
  String _overwritePolicy = 'Skip if exists';
  final TextEditingController _downloadRootController =
      TextEditingController(text: '/Users/you/Downloads/reddit');

  @override
  void dispose() {
    _downloadRootController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = context.watch<ThemeCubit>().state == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
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
                value: isDark,
                onChanged: (value) =>
                    context.read<ThemeCubit>().setDarkMode(value),
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.folder_open_outlined),
                  onPressed: () => AppToast.show(
                    context,
                    'Folder picker coming next phase.',
                  ),
                ),
              ),
              SizedBox(height: AppTokens.space.s12),
              AppSelect<String>(
                label: 'Overwrite policy',
                value: _overwritePolicy,
                options: const [
                  AppSelectOption(label: 'Skip if exists', value: 'Skip if exists'),
                  AppSelectOption(
                      label: 'Overwrite if newer', value: 'Overwrite if newer'),
                ],
                onChanged: (value) {
                  setState(() {
                    _overwritePolicy = value ?? 'Skip if exists';
                  });
                },
              ),
              SizedBox(height: AppTokens.space.s12),
              AppSwitch(
                label: 'Download NSFW',
                description: 'Enabled only when explicitly allowed.',
                value: _downloadNsfw,
                onChanged: (value) {
                  setState(() {
                    _downloadNsfw = value;
                  });
                },
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
                value: _rememberSession,
                onChanged: (value) {
                  setState(() {
                    _rememberSession = value;
                  });
                },
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
                              style: Theme.of(context).textTheme.titleLarge),
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
                              style: Theme.of(context).textTheme.titleLarge),
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
  }
}
