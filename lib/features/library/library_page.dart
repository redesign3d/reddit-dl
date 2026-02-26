import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_database.dart';
import '../../data/library_repository.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_chip.dart';
import '../../ui/components/app_select.dart';
import '../../ui/components/app_switch.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/tokens.dart';
import 'library_cubit.dart';

const _wideLibraryBreakpoint = 1080.0;

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final selectedItem = _findSelectedItem(
          state.items,
          state.selectedItemId,
        );
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
                      return _LibraryListRow(
                        item: item,
                        selected: selected,
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

class _LibraryListRow extends StatelessWidget {
  const _LibraryListRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SavedItem item;
  final bool selected;
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
                  ],
                ),
              ),
              SizedBox(width: AppTokens.space.s8),
              Wrap(
                spacing: AppTokens.space.s6,
                children: [
                  AppChip(
                    label: item.kind.toUpperCase(),
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

SavedItem? _findSelectedItem(List<SavedItem> items, int? selectedItemId) {
  if (selectedItemId == null) {
    return items.isEmpty ? null : items.first;
  }
  for (final item in items) {
    if (item.id == selectedItemId) {
      return item;
    }
  }
  return items.isEmpty ? null : items.first;
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
