import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_database.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_chip.dart';
import '../../ui/components/app_select.dart';
import '../../ui/components/app_switch.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import '../../utils/reveal_in_file_manager.dart';
import '../queue/queue_cubit.dart';
import 'library_cubit.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final colors = context.appColors;
        final canFilter = state.hasIndexed && state.subreddits.isNotEmpty;
        final includeValue = state.includeSubreddit != null &&
                state.subreddits.contains(state.includeSubreddit)
            ? state.includeSubreddit!
            : '_all';
        final excludeValue = state.excludeSubreddit != null &&
                state.subreddits.contains(state.excludeSubreddit)
            ? state.excludeSubreddit!
            : '_none';

        final subredditOptions = [
          const AppSelectOption(label: 'All', value: '_all'),
          ...state.subreddits.map(
            (subreddit) => AppSelectOption(
              label: 'r/$subreddit',
              value: subreddit,
            ),
          ),
        ];
        final excludeOptions = [
          const AppSelectOption(label: 'None', value: '_none'),
          ...state.subreddits.map(
            (subreddit) => AppSelectOption(
              label: 'r/$subreddit',
              value: subreddit,
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Search saved items',
                    hint: 'Filter by title, author, permalink, or subreddit',
                    onChanged: context.read<LibraryCubit>().updateSearch,
                  ),
                ),
                SizedBox(width: AppTokens.space.s12),
                AppButton(
                  label: 'Export selection',
                  variant: AppButtonVariant.secondary,
                  onPressed: state.items.isEmpty
                      ? null
                      : () => AppToast.show(
                            context,
                            'Export queued (mock).',
                          ),
                ),
              ],
            ),
            SizedBox(height: AppTokens.space.s16),
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saved items',
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(height: AppTokens.space.s8),
                        Text(
                          '${state.items.length} visible • ${state.items.where((item) => item.over18).length} NSFW',
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
                        Text('Sources',
                            style: Theme.of(context).textTheme.titleLarge),
                        SizedBox(height: AppTokens.space.s8),
                        Text(
                          '${state.items.where((item) => item.source == 'zip').length} ZIP • '
                          '${state.items.where((item) => item.source == 'sync').length} Sync',
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
            SizedBox(height: AppTokens.space.s16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters',
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: AppTokens.space.s6),
                  Text(
                    canFilter
                        ? 'Subreddit filters are populated from indexed items.'
                        : 'Import ZIP or Sync to populate subreddit filters.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.mutedForeground),
                  ),
                  SizedBox(height: AppTokens.space.s12),
                  Row(
                    children: [
                      Expanded(
                        child: AppSelect<LibraryKindFilter>(
                          label: 'Type',
                          value: state.kindFilter,
                          options: const [
                            AppSelectOption(
                              label: 'All',
                              value: LibraryKindFilter.all,
                            ),
                            AppSelectOption(
                              label: 'Posts only',
                              value: LibraryKindFilter.post,
                            ),
                            AppSelectOption(
                              label: 'Comments only',
                              value: LibraryKindFilter.comment,
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            context.read<LibraryCubit>().updateKindFilter(value);
                          },
                        ),
                      ),
                      SizedBox(width: AppTokens.space.s12),
                      Expanded(
                        child: AppSwitch(
                          label: 'Show NSFW',
                          description: 'Toggle visibility only (downloads are separate).',
                          value: state.showNsfw,
                          onChanged: (value) =>
                              context.read<LibraryCubit>().toggleShowNsfw(value),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTokens.space.s12),
                  Opacity(
                    opacity: canFilter ? 1 : 0.5,
                    child: AbsorbPointer(
                      absorbing: !canFilter,
                      child: Row(
                        children: [
                          Expanded(
                            child: AppSelect<String>(
                              label: 'Include subreddit',
                              value: includeValue,
                              options: subredditOptions,
                              onChanged: (value) {
                                final selected = value == '_all' ? null : value;
                                context
                                    .read<LibraryCubit>()
                                    .updateIncludeSubreddit(selected);
                              },
                            ),
                          ),
                          SizedBox(width: AppTokens.space.s12),
                          Expanded(
                            child: AppSelect<String>(
                              label: 'Exclude subreddit',
                              value: excludeValue,
                              options: excludeOptions,
                              onChanged: (value) {
                                final selected = value == '_none' ? null : value;
                                context
                                    .read<LibraryCubit>()
                                    .updateExcludeSubreddit(selected);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppTokens.space.s16),
            if (state.items.isEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No items indexed yet',
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: AppTokens.space.s6),
                    Text(
                      'Run a ZIP import or sync to populate your library.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: state.items
                    .map(
                      (item) => Padding(
                        padding: EdgeInsets.only(bottom: AppTokens.space.s12),
                        child: _LibraryItemCard(item: item),
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

class _LibraryItemCard extends StatelessWidget {
  const _LibraryItemCard({required this.item});

  final SavedItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final createdDate = _formatDate(item.createdUtc);
    final importedDate = item.importedAt?.toLocal();

    return GestureDetector(
      onSecondaryTapDown: (details) async {
        final selection = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: const [
            PopupMenuItem(value: 'copy', child: Text('Copy permalink')),
            PopupMenuItem(value: 'reveal', child: Text('Reveal in Finder/Explorer')),
          ],
        );
        if (selection == 'copy') {
          Clipboard.setData(ClipboardData(text: item.permalink));
          if (context.mounted) {
            AppToast.show(context, 'Permalink copied.');
          }
        }
        if (selection == 'reveal') {
          final success =
              await revealInFileManager(Directory.systemTemp.path);
          if (context.mounted) {
            AppToast.show(
              context,
              success
                  ? 'Opened file manager (mock path).'
                  : 'Unable to reveal path.',
            );
          }
        }
      },
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isEmpty ? 'Untitled' : item.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: AppTokens.space.s6),
                      Text(
                        'r/${item.subreddit} • u/${item.author}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  label: 'Enqueue download',
                  variant: AppButtonVariant.secondary,
                  onPressed: () async {
                    final created = await context
                        .read<QueueCubit>()
                        .enqueueSavedItem(item);
                    if (!context.mounted) {
                      return;
                    }
                    AppToast.show(
                      context,
                      created ? 'Download queued.' : 'Download already queued.',
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: AppTokens.space.s12),
            Wrap(
              spacing: AppTokens.space.s8,
              runSpacing: AppTokens.space.s6,
              children: [
                AppChip(
                  label: item.kind.toUpperCase(),
                  selected: false,
                  onSelected: (_) {},
                ),
                AppChip(
                  label: item.source.toUpperCase(),
                  selected: false,
                  onSelected: (_) {},
                ),
                if (item.over18)
                  AppChip(
                    label: 'NSFW',
                    selected: true,
                    onSelected: (_) {},
                  ),
              ],
            ),
            SizedBox(height: AppTokens.space.s12),
            Text(
              'Created: $createdDate • Imported: ${_formatOptionalDate(importedDate)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.mutedForeground),
            ),
            SizedBox(height: AppTokens.space.s6),
            Text(
              item.permalink,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(int createdUtc) {
  if (createdUtc <= 0) {
    return 'Unknown';
  }
  final date = DateTime.fromMillisecondsSinceEpoch(createdUtc * 1000, isUtc: true)
      .toLocal();
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatOptionalDate(DateTime? date) {
  if (date == null) {
    return 'Unknown';
  }
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
