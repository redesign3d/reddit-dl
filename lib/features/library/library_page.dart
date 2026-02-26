import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_database.dart';
import '../../data/library_repository.dart';
import '../../data/queue_repository.dart';
import '../../data/settings_repository.dart';
import '../../services/export/saved_comment_markdown_exporter.dart';
import '../../services/export/text_post_markdown_exporter.dart';
import '../../services/path_template_engine.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_chip.dart';
import '../../ui/components/app_select.dart';
import '../../ui/components/app_switch.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import '../../utils/reveal_in_file_manager.dart';
import '../../utils/reveal_path_resolver.dart';
import '../queue/queue_cubit.dart';
import 'library_cubit.dart';

const _wideLibraryBreakpoint = 1080.0;

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final selectedItem = state.selectedItem;
        final contentHeight = _contentHeight(context);
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _wideLibraryBreakpoint;
            if (isWide) {
              return SizedBox(
                height: contentHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 300,
                      child: _LibraryFiltersPanel(state: state),
                    ),
                    SizedBox(width: AppTokens.space.s12),
                    Expanded(
                      child: _LibraryListPanel(
                        state: state,
                        onItemTap: (item) =>
                            context.read<LibraryCubit>().selectItem(item.id),
                      ),
                    ),
                    SizedBox(width: AppTokens.space.s12),
                    SizedBox(
                      width: 340,
                      child: _LibraryDetailsPanel(item: selectedItem),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: contentHeight,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _pageSummary(state),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.appColors.mutedForeground,
                              ),
                        ),
                      ),
                      AppButton(
                        label: 'Filters',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _showFiltersOverlay(context, state),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTokens.space.s12),
                  Expanded(
                    child: _LibraryListPanel(
                      state: state,
                      onItemTap: (item) async {
                        context.read<LibraryCubit>().selectItem(item.id);
                        await _showDetailsOverlay(context, item);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LibraryFiltersPanel extends StatelessWidget {
  const _LibraryFiltersPanel({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final canFilter = state.hasIndexed && state.subreddits.isNotEmpty;
    final includeValue =
        state.includeSubreddit != null &&
            state.subreddits.contains(state.includeSubreddit)
        ? state.includeSubreddit!
        : '_all';
    final excludeValue =
        state.excludeSubreddit != null &&
            state.subreddits.contains(state.excludeSubreddit)
        ? state.excludeSubreddit!
        : '_none';

    final subredditOptions = [
      const AppSelectOption(label: 'All', value: '_all'),
      ...state.subreddits.map(
        (subreddit) => AppSelectOption(label: 'r/$subreddit', value: subreddit),
      ),
    ];
    final excludeOptions = [
      const AppSelectOption(label: 'None', value: '_none'),
      ...state.subreddits.map(
        (subreddit) => AppSelectOption(label: 'r/$subreddit', value: subreddit),
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.titleLarge),
          if (state.hasFocusedItemIds) ...[
            SizedBox(height: AppTokens.space.s8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing only newly synced items.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appColors.mutedForeground,
                    ),
                  ),
                ),
                AppButton(
                  label: 'Clear',
                  variant: AppButtonVariant.ghost,
                  onPressed: () =>
                      context.read<LibraryCubit>().clearFocusedItemIds(),
                ),
              ],
            ),
          ],
          SizedBox(height: AppTokens.space.s12),
          AppTextField(
            label: 'Search',
            hint: 'Title, body, author, subreddit',
            onChanged: context.read<LibraryCubit>().updateSearch,
          ),
          SizedBox(height: AppTokens.space.s12),
          AppSelect<LibraryItemKind>(
            label: 'Type',
            value: state.kindFilter,
            options: const [
              AppSelectOption(label: 'All', value: LibraryItemKind.all),
              AppSelectOption(label: 'Posts only', value: LibraryItemKind.post),
              AppSelectOption(
                label: 'Comments only',
                value: LibraryItemKind.comment,
              ),
              AppSelectOption(
                label: 'Media items',
                value: LibraryItemKind.media,
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              context.read<LibraryCubit>().updateKindFilter(value);
            },
          ),
          SizedBox(height: AppTokens.space.s12),
          AppSelect<LibraryResolutionFilter>(
            label: 'Resolution',
            value: state.resolutionFilter,
            options: const [
              AppSelectOption(label: 'All', value: LibraryResolutionFilter.all),
              AppSelectOption(
                label: 'Resolved',
                value: LibraryResolutionFilter.ok,
              ),
              AppSelectOption(
                label: 'Partial',
                value: LibraryResolutionFilter.partial,
              ),
              AppSelectOption(
                label: 'Failed',
                value: LibraryResolutionFilter.failed,
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              context.read<LibraryCubit>().updateResolutionFilter(value);
            },
          ),
          SizedBox(height: AppTokens.space.s12),
          AppSwitch(
            label: 'Show NSFW',
            description: 'Toggle visibility only.',
            value: state.showNsfw,
            onChanged: (value) =>
                context.read<LibraryCubit>().toggleShowNsfw(value),
          ),
          SizedBox(height: AppTokens.space.s12),
          Opacity(
            opacity: canFilter ? 1 : 0.5,
            child: AbsorbPointer(
              absorbing: !canFilter,
              child: Column(
                children: [
                  AppSelect<String>(
                    label: 'Include subreddit',
                    value: includeValue,
                    options: subredditOptions,
                    onChanged: (value) {
                      final selected = value == '_all' ? null : value;
                      context.read<LibraryCubit>().updateIncludeSubreddit(
                        selected,
                      );
                    },
                  ),
                  SizedBox(height: AppTokens.space.s12),
                  AppSelect<String>(
                    label: 'Exclude subreddit',
                    value: excludeValue,
                    options: excludeOptions,
                    onChanged: (value) {
                      final selected = value == '_none' ? null : value;
                      context.read<LibraryCubit>().updateExcludeSubreddit(
                        selected,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryListPanel extends StatelessWidget {
  const _LibraryListPanel({required this.state, required this.onItemTap});

  final LibraryState state;
  final ValueChanged<SavedItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Row(
            children: [
              Checkbox(
                value: state.items.isEmpty
                    ? false
                    : state.selectedItemIds.isEmpty
                    ? false
                    : state.selectedItemIds.length == state.items.length
                    ? true
                    : null,
                tristate: true,
                onChanged: state.items.isEmpty
                    ? null
                    : (value) {
                        if (value == true) {
                          context.read<LibraryCubit>().selectAllVisible();
                        } else {
                          context.read<LibraryCubit>().clearSelection();
                        }
                      },
              ),
              Expanded(
                child: Text(
                  _pageSummary(state),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ),
              AppButton(
                label: 'Previous',
                variant: AppButtonVariant.ghost,
                onPressed: state.hasPreviousPage && !state.isPageLoading
                    ? () => context.read<LibraryCubit>().goToPreviousPage()
                    : null,
              ),
              SizedBox(width: AppTokens.space.s8),
              AppButton(
                label: 'Next',
                variant: AppButtonVariant.secondary,
                onPressed: state.hasNextPage && !state.isPageLoading
                    ? () => context.read<LibraryCubit>().goToNextPage()
                    : null,
              ),
            ],
          ),
        ),
        if (state.hasSelection) ...[
          SizedBox(height: AppTokens.space.s12),
          _LibraryBulkActionsBar(state: state),
        ],
        SizedBox(height: AppTokens.space.s12),
        Expanded(
          child: AppCard(
            padding: EdgeInsets.zero,
            child: state.items.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTokens.space.s20),
                      child: Text(
                        state.hasIndexed
                            ? 'No items match current filters.'
                            : 'No items indexed yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      final selected = item.id == state.selectedItemId;
                      final bulkSelected = state.selectedItemIds.contains(
                        item.id,
                      );
                      return _LibraryListRow(
                        key: ValueKey<int>(item.id),
                        item: item,
                        mediaCount: state.mediaCountByItemId[item.id] ?? 0,
                        downloadStatus:
                            state.latestDownloadStatusByItemId[item.id],
                        selected: selected,
                        bulkSelected: bulkSelected,
                        onSelectChanged: (value) => context
                            .read<LibraryCubit>()
                            .toggleItemSelection(item.id, value),
                        onTap: () => onItemTap(item),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _LibraryBulkActionsBar extends StatelessWidget {
  const _LibraryBulkActionsBar({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final selectedItems = state.items
        .where((item) => state.selectedItemIds.contains(item.id))
        .toList(growable: false);
    return AppCard(
      child: Wrap(
        spacing: AppTokens.space.s8,
        runSpacing: AppTokens.space.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${state.selectedItemIds.length} selected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          AppButton(
            label: 'Clear',
            variant: AppButtonVariant.ghost,
            onPressed: () => context.read<LibraryCubit>().clearSelection(),
          ),
          AppButton(
            label: 'Select visible',
            variant: AppButtonVariant.ghost,
            onPressed: state.items.isEmpty
                ? null
                : () => context.read<LibraryCubit>().selectAllVisible(),
          ),
          AppButton(
            label: 'Enqueue selected',
            variant: AppButtonVariant.secondary,
            onPressed: selectedItems.isEmpty
                ? null
                : () => _bulkEnqueue(context, selectedItems),
          ),
          AppButton(
            label: 'Enqueue visible',
            variant: AppButtonVariant.secondary,
            onPressed: state.items.isEmpty
                ? null
                : () => _bulkEnqueue(context, state.items),
          ),
          AppButton(
            label: 'Retry failed (selected)',
            variant: AppButtonVariant.ghost,
            onPressed: selectedItems.isEmpty
                ? null
                : () => _bulkRetryFailed(
                    context,
                    selectedItems.map((item) => item.id),
                  ),
          ),
          AppButton(
            label: 'Retry failed (visible)',
            variant: AppButtonVariant.ghost,
            onPressed: state.items.isEmpty
                ? null
                : () => _bulkRetryFailed(
                    context,
                    state.items.map((item) => item.id),
                  ),
          ),
          AppButton(
            label: 'Export markdown',
            variant: AppButtonVariant.ghost,
            onPressed: selectedItems.isEmpty
                ? null
                : () => _exportMarkdownForItems(context, selectedItems),
          ),
        ],
      ),
    );
  }
}

class _LibraryListRow extends StatelessWidget {
  const _LibraryListRow({
    super.key,
    required this.item,
    required this.mediaCount,
    required this.downloadStatus,
    required this.selected,
    required this.bulkSelected,
    required this.onSelectChanged,
    required this.onTap,
  });

  final SavedItem item;
  final int mediaCount;
  final String? downloadStatus;
  final bool selected;
  final bool bulkSelected;
  final ValueChanged<bool> onSelectChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: selected
          ? colors.sidebarAccent.withValues(alpha: 0.18)
          : colors.card,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppTokens.space.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: bulkSelected,
                onChanged: (value) => onSelectChanged(value ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isEmpty ? 'Untitled' : item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: AppTokens.space.s4),
                    Text(
                      'r/${item.subreddit} • u/${item.author}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                    SizedBox(height: AppTokens.space.s4),
                    Text(
                      '${item.kind.toUpperCase()} • ${_formatDate(item.createdUtc)} • $mediaCount media • ${_listStatusLabel(downloadStatus)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppTokens.space.s8),
              Wrap(
                spacing: AppTokens.space.s6,
                children: [
                  AppChip(
                    label: _listStatusLabel(downloadStatus),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  if (item.over18)
                    AppChip(label: 'NSFW', selected: true, onSelected: (_) {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryDetailsPanel extends StatelessWidget {
  const _LibraryDetailsPanel({required this.item});

  final SavedItem? item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (item == null) {
      return AppCard(
        child: Text(
          'Select an item to view details.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
        ),
      );
    }

    return AppCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item!.title.isEmpty ? 'Untitled' : item!.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: AppTokens.space.s8),
            Text(
              'r/${item!.subreddit} • u/${item!.author}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
            SizedBox(height: AppTokens.space.s4),
            Text(
              '${item!.kind.toUpperCase()} • ${item!.resolutionStatus.toUpperCase()} • ${item!.over18 ? 'NSFW' : 'SFW'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
            SizedBox(height: AppTokens.space.s4),
            Text(
              'Created: ${_formatDate(item!.createdUtc)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: AppTokens.space.s12),
            Text(
              item!.permalink,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
            SizedBox(height: AppTokens.space.s12),
            StreamBuilder<DownloadJob?>(
              stream: _watchLatestJobForItem(context, item!.id),
              builder: (context, snapshot) {
                final job = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download status: ${_statusLabel(job)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                    SizedBox(height: AppTokens.space.s8),
                    Wrap(
                      spacing: AppTokens.space.s8,
                      runSpacing: AppTokens.space.s8,
                      children: [
                        AppButton(
                          label: 'Enqueue download',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => _enqueueDownload(context, item!),
                        ),
                        if (job != null &&
                            (job.status == 'failed' || job.status == 'skipped'))
                          AppButton(
                            label: 'Retry',
                            variant: AppButtonVariant.ghost,
                            onPressed: () => _retryJob(context, job.id),
                          ),
                        AppButton(
                          label: 'Export markdown',
                          variant: AppButtonVariant.secondary,
                          onPressed: () =>
                              _exportMarkdownForItems(context, [item!]),
                        ),
                        AppButton(
                          label: 'Reveal output',
                          variant: AppButtonVariant.ghost,
                          onPressed: () => _revealOutput(context, item!, job),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: AppTokens.space.s12),
            Wrap(
              spacing: AppTokens.space.s8,
              runSpacing: AppTokens.space.s8,
              children: [
                AppButton(
                  label: 'Open permalink',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _openPermalink(context, item!.permalink),
                ),
                AppButton(
                  label: 'Copy permalink',
                  variant: AppButtonVariant.ghost,
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: item!.permalink),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    AppToast.show(context, 'Permalink copied.');
                  },
                ),
              ],
            ),
            if (item!.bodyMarkdown != null &&
                item!.bodyMarkdown!.trim().isNotEmpty) ...[
              SizedBox(height: AppTokens.space.s12),
              Text('Preview', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: AppTokens.space.s6),
              SelectableText(
                item!.bodyMarkdown!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Stream<DownloadJob?> _watchLatestJobForItem(
  BuildContext context,
  int savedItemId,
) {
  final queueRepository = context.read<QueueRepository>();
  return queueRepository.watchQueue().map((records) {
    final matches =
        records
            .where((record) => record.item.id == savedItemId)
            .map((record) => record.job)
            .toList()
          ..sort((a, b) => b.id.compareTo(a.id));
    return matches.isEmpty ? null : matches.first;
  });
}

String _statusLabel(DownloadJob? job) {
  if (job == null) {
    return 'Not queued';
  }
  return job.status.toUpperCase();
}

String _listStatusLabel(String? status) {
  if (status == null || status.isEmpty) {
    return 'NOT QUEUED';
  }
  return status.toUpperCase();
}

Future<void> _enqueueDownload(BuildContext context, SavedItem item) async {
  final created = await context.read<QueueCubit>().enqueueSavedItem(item);
  if (!context.mounted) {
    return;
  }
  AppToast.show(
    context,
    created ? 'Download queued.' : 'Download already queued.',
  );
}

Future<void> _bulkEnqueue(BuildContext context, List<SavedItem> items) async {
  final result = await context.read<QueueCubit>().enqueueSavedItems(items);
  if (!context.mounted) {
    return;
  }
  AppToast.show(
    context,
    '${result.createdCount} queued, ${result.skippedCount} already active.',
  );
}

Future<void> _bulkRetryFailed(
  BuildContext context,
  Iterable<int> savedItemIds,
) async {
  final retried = await context.read<QueueCubit>().retryFailedForSavedItemIds(
    savedItemIds,
  );
  if (!context.mounted) {
    return;
  }
  AppToast.show(context, 'Retry queued for $retried failed/skipped job(s).');
}

Future<void> _exportMarkdownForItems(
  BuildContext context,
  List<SavedItem> items,
) async {
  if (items.isEmpty) {
    return;
  }
  final settings = await context.read<SettingsRepository>().load();
  final engine = PathTemplateEngine(settings);
  final policy = settings.overwritePolicy;
  final textExporter = TextPostMarkdownExporter();
  final commentExporter = SavedCommentMarkdownExporter();

  var exported = 0;
  var skipped = 0;
  for (final item in items) {
    final result = item.kind == 'comment'
        ? await commentExporter.export(
            item: item,
            engine: engine,
            policy: policy,
          )
        : await textExporter.export(item: item, engine: engine, policy: policy);
    if (result.isCompleted) {
      exported += 1;
    } else {
      skipped += 1;
    }
  }

  if (!context.mounted) {
    return;
  }
  AppToast.show(
    context,
    'Markdown export: $exported written, $skipped skipped.',
  );
}

Future<void> _retryJob(BuildContext context, int jobId) async {
  await context.read<QueueCubit>().retryJob(jobId);
  if (!context.mounted) {
    return;
  }
  AppToast.show(context, 'Retry queued.');
}

Future<void> _revealOutput(
  BuildContext context,
  SavedItem item,
  DownloadJob? job,
) async {
  final path = await resolveRevealPath(
    queueRepository: context.read<QueueRepository>(),
    settingsRepository: context.read<SettingsRepository>(),
    jobId: job?.id,
    savedItemId: item.id,
    legacyOutputPath: job?.outputPath,
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
  AppToast.show(
    context,
    success ? 'Opened file manager.' : 'Unable to reveal path.',
  );
}

Future<void> _openPermalink(BuildContext context, String permalink) async {
  final success = await _openExternal(permalink);
  if (!context.mounted) {
    return;
  }
  AppToast.show(
    context,
    success ? 'Opened permalink.' : 'Unable to open permalink.',
  );
}

Future<bool> _openExternal(String target) async {
  try {
    if (Platform.isMacOS) {
      final result = await Process.run('open', [target]);
      return result.exitCode == 0;
    }
    if (Platform.isWindows) {
      final result = await Process.run('explorer', [target]);
      return result.exitCode == 0;
    }
    if (Platform.isLinux) {
      final result = await Process.run('xdg-open', [target]);
      return result.exitCode == 0;
    }
  } catch (_) {
    return false;
  }
  return false;
}

Future<void> _showFiltersOverlay(
  BuildContext context,
  LibraryState state,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final height = math.min(MediaQuery.sizeOf(context).height * 0.9, 700.0);
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.space.s16),
          child: SizedBox(
            height: height,
            child: _LibraryFiltersPanel(state: state),
          ),
        ),
      );
    },
  );
}

Future<void> _showDetailsOverlay(BuildContext context, SavedItem item) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        child: SizedBox(
          width: 680,
          height: 560,
          child: Padding(
            padding: EdgeInsets.all(AppTokens.space.s16),
            child: _LibraryDetailsPanel(item: item),
          ),
        ),
      );
    },
  );
}

double _contentHeight(BuildContext context) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  final reserved =
      AppTokens.layout.titleBarHeight +
      AppTokens.space.s20 * 2 +
      AppTokens.space.s16;
  return math.max(520, screenHeight - reserved);
}

String _pageSummary(LibraryState state) {
  if (state.totalCount == 0) {
    return state.isPageLoading ? 'Loading...' : 'No results';
  }
  final start = state.pageIndex * state.pageSize + 1;
  final end = math.min(
    (state.pageIndex + 1) * state.pageSize,
    state.totalCount,
  );
  return 'Showing $start-$end of ${state.totalCount} • Page ${state.pageIndex + 1}/${state.pageCount}';
}

String _formatDate(int createdUtc) {
  if (createdUtc <= 0) {
    return 'Unknown';
  }
  final date = DateTime.fromMillisecondsSinceEpoch(
    createdUtc * 1000,
    isUtc: true,
  ).toLocal();
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
