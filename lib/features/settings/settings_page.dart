import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/settings_repository.dart';
import '../../services/path_template_engine.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_select.dart';
import '../../ui/components/app_switch.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import '../../utils/reveal_in_file_manager.dart';
import '../library/library_cubit.dart';
import '../sync/sync_cubit.dart';
import 'settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _downloadRootController;
  late final TextEditingController _templateController;
  late final TextEditingController _textRootController;
  late final TextEditingController _commentsRootController;
  late final TextEditingController _concurrencyController;
  late final TextEditingController _rateLimitController;
  late final TextEditingController _attemptsController;
  late final TextEditingController _galleryDlController;
  late final TextEditingController _ytDlpController;

  int? _previewItemId;

  @override
  void initState() {
    super.initState();
    _downloadRootController = TextEditingController();
    _templateController = TextEditingController();
    _textRootController = TextEditingController();
    _commentsRootController = TextEditingController();
    _concurrencyController = TextEditingController();
    _rateLimitController = TextEditingController();
    _attemptsController = TextEditingController();
    _galleryDlController = TextEditingController();
    _ytDlpController = TextEditingController();
  }

  @override
  void dispose() {
    _downloadRootController.dispose();
    _templateController.dispose();
    _textRootController.dispose();
    _commentsRootController.dispose();
    _concurrencyController.dispose();
    _rateLimitController.dispose();
    _attemptsController.dispose();
    _galleryDlController.dispose();
    _ytDlpController.dispose();
    super.dispose();
  }

  Future<void> _pickDownloadRoot(BuildContext context) async {
    final path = await getDirectoryPath();
    if (path == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    context.read<SettingsCubit>().updateDownloadRoot(path);
  }

  Future<void> _openCacheFolder(BuildContext context) async {
    final directory = await getApplicationSupportDirectory();
    final success = await revealInFileManager(directory.path);
    if (!context.mounted) {
      return;
    }
    AppToast.show(
      context,
      success ? 'Opened cache folder.' : 'Unable to open cache folder.',
    );
  }

  int _parseInt(TextEditingController controller, int fallback) {
    final value = int.tryParse(controller.text.trim());
    if (value == null || value <= 0) {
      return fallback;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) => previous.settings != current.settings,
      listener: (context, state) {
        final settings = state.settings;
        _downloadRootController.text = settings.downloadRoot;
        _templateController.text = settings.mediaPathTemplate;
        _textRootController.text = settings.textRoot;
        _commentsRootController.text = settings.commentsRoot;
        _concurrencyController.text = settings.concurrency.toString();
        _rateLimitController.text = settings.rateLimitPerMinute.toString();
        _attemptsController.text = settings.maxDownloadAttempts.toString();
        _galleryDlController.text = settings.galleryDlPathOverride;
        _ytDlpController.text = settings.ytDlpPathOverride;
      },
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = state.settings;
          final libraryState = context.watch<LibraryCubit>().state;
          final previewItems = libraryState.items;
          if (_previewItemId != null &&
              previewItems.every((item) => item.id != _previewItemId)) {
            _previewItemId = null;
          }
          if (_previewItemId == null && previewItems.isNotEmpty) {
            _previewItemId = previewItems.first.id;
          }
          final previewItem = _previewItemId == null
              ? null
              : previewItems
                  .firstWhere((item) => item.id == _previewItemId);
          final preview = previewItem == null
              ? null
              : PathTemplateEngine(settings).previewForItem(previewItem);

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
                        onPressed: () => _pickDownloadRoot(context),
                      ),
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Concurrency',
                            hint: '2',
                            controller: _concurrencyController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) {
                              final value = _parseInt(
                                _concurrencyController,
                                settings.concurrency,
                              );
                              context
                                  .read<SettingsCubit>()
                                  .updateConcurrency(value);
                            },
                          ),
                        ),
                        SizedBox(width: AppTokens.space.s12),
                        Expanded(
                          child: AppTextField(
                            label: 'Rate limit (per minute)',
                            hint: '30',
                            controller: _rateLimitController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) {
                              final value = _parseInt(
                                _rateLimitController,
                                settings.rateLimitPerMinute,
                              );
                              context.read<SettingsCubit>().updateRateLimit(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    AppTextField(
                      label: 'Max download attempts',
                      hint: '5',
                      controller: _attemptsController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        final value = _parseInt(
                          _attemptsController,
                          settings.maxDownloadAttempts,
                        );
                        context
                            .read<SettingsCubit>()
                            .updateMaxDownloadAttempts(value);
                      },
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
                    Text('Organization',
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: AppTokens.space.s12),
                    AppSelect<MediaLayoutMode>(
                      label: 'Media layout',
                      value: settings.mediaLayoutMode,
                      options: const [
                        AppSelectOption(
                          label: 'Flat files in post folder',
                          value: MediaLayoutMode.flat,
                        ),
                        AppSelectOption(
                          label: 'Folder per media',
                          value: MediaLayoutMode.folderPerMedia,
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        context
                            .read<SettingsCubit>()
                            .updateMediaLayoutMode(value);
                      },
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    AppTextField(
                      label: 'Media path template',
                      hint: '{type}/{subreddit}/{yyyy}/{mm}/{title_slug}-{id}',
                      controller: _templateController,
                      onChanged: (value) => context
                          .read<SettingsCubit>()
                          .updateMediaPathTemplate(value),
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Text root (relative to download root)',
                            hint: 'text',
                            controller: _textRootController,
                            onChanged: (value) => context
                                .read<SettingsCubit>()
                                .updateTextRoot(value),
                          ),
                        ),
                        SizedBox(width: AppTokens.space.s12),
                        Expanded(
                          child: AppTextField(
                            label: 'Comments root (relative to download root)',
                            hint: 'comments',
                            controller: _commentsRootController,
                            onChanged: (value) => context
                                .read<SettingsCubit>()
                                .updateCommentsRoot(value),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    if (previewItem == null)
                      Text(
                        'Import ZIP or Sync to preview templates.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.mutedForeground),
                      )
                    else ...[
                      AppSelect<int>(
                        label: 'Preview item',
                        value: previewItem.id,
                        options: previewItems
                            .map(
                              (item) => AppSelectOption(
                                label:
                                    '${item.title.isEmpty ? 'Untitled' : item.title} • r/${item.subreddit}',
                                value: item.id,
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _previewItemId = value;
                          });
                        },
                      ),
                      if (preview != null) ...[
                        SizedBox(height: AppTokens.space.s12),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Preview',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              SizedBox(height: AppTokens.space.s6),
                              Text(
                                preview.directoryPath.isEmpty
                                    ? 'Directory: not available'
                                    : 'Directory: ${preview.directoryPath}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.mutedForeground),
                              ),
                              SizedBox(height: AppTokens.space.s6),
                              Text(
                                preview.filePath.isEmpty
                                    ? 'File: not available'
                                    : 'File: ${preview.filePath}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.mutedForeground),
                              ),
                              if (preview.warnings.isNotEmpty) ...[
                                SizedBox(height: AppTokens.space.s8),
                                Text(
                                  preview.warnings.join(' • '),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: colors.destructive),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
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
                          onPressed: () async {
                            await context.read<SyncCubit>().clearSession(
                                  rememberSession: settings.rememberSession,
                                );
                            if (!context.mounted) {
                              return;
                            }
                            AppToast.show(context, 'Cookies cleared.');
                          },
                        ),
                        SizedBox(width: AppTokens.space.s8),
                        AppButton(
                          label: 'Open cache folder',
                          variant: AppButtonVariant.ghost,
                          onPressed: () => _openCacheFolder(context),
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
                      'Set manual overrides for gallery-dl and yt-dlp. Auto-detection lands next.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.mutedForeground),
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    AppTextField(
                      label: 'gallery-dl path override',
                      hint: '/usr/local/bin/gallery-dl',
                      controller: _galleryDlController,
                      onChanged: (value) => context
                          .read<SettingsCubit>()
                          .updateGalleryDlPathOverride(value),
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    AppTextField(
                      label: 'yt-dlp path override',
                      hint: '/usr/local/bin/yt-dlp',
                      controller: _ytDlpController,
                      onChanged: (value) =>
                          context.read<SettingsCubit>().updateYtDlpPathOverride(
                                value,
                              ),
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    AppButton(
                      label: 'Copy install commands',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(
                            text: 'brew install gallery-dl yt-dlp',
                          ),
                        );
                        AppToast.show(context, 'Install commands copied.');
                      },
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
