import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_chip.dart';
import '../../ui/components/app_select.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/components/app_text_field.dart';
import '../../ui/tokens.dart';
import '../../utils/reveal_in_file_manager.dart';
import 'library_cubit.dart';
import 'sample_data.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _includeSubreddit = 'All';
  String _excludeSubreddit = 'None';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) {
        final colors = context.appColors;
        final sortedSubreddits = state.subreddits.toList()..sort();
        final subredditOptions = [
          const AppSelectOption(label: 'All', value: 'All'),
          ...sortedSubreddits.map(
            (subreddit) => AppSelectOption(
              label: 'r/$subreddit',
              value: subreddit,
            ),
          ),
        ];
        final excludeOptions = [
          const AppSelectOption(label: 'None', value: 'None'),
          ...sortedSubreddits.map(
            (subreddit) => AppSelectOption(
              label: 'r/$subreddit',
              value: subreddit,
            ),
          ),
        ];
        final canFilter = state.hasIndexed && state.subreddits.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Search saved items',
                    hint: 'Filter by title, author, or subreddit',
                    onChanged: (_) {},
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
                          '${state.items.length} total • ${state.items.where((item) => item.isNsfw).length} NSFW',
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
                          '${state.items.where((item) => item.source == LibrarySource.zip).length} ZIP • '
                          '${state.items.where((item) => item.source == LibrarySource.sync).length} Sync',
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
                  Text('Subreddit filters',
                      style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: AppTokens.space.s6),
                  Text(
                    canFilter
                        ? 'Filter using indexed subreddits only.'
                        : 'Import or sync first to unlock filters.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.mutedForeground),
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
                              value: _includeSubreddit,
                              options: subredditOptions,
                              onChanged: (value) {
                                setState(() {
                                  _includeSubreddit = value ?? 'All';
                                });
                              },
                            ),
                          ),
                          SizedBox(width: AppTokens.space.s12),
                          Expanded(
                            child: AppSelect<String>(
                              label: 'Exclude subreddit',
                              value: _excludeSubreddit,
                              options: excludeOptions,
                              onChanged: (value) {
                                setState(() {
                                  _excludeSubreddit = value ?? 'None';
                                });
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
                    SizedBox(height: AppTokens.space.s12),
                    Wrap(
                      spacing: AppTokens.space.s8,
                      runSpacing: AppTokens.space.s8,
                      children: [
                        AppButton(
                          label: 'Load sample ZIP import',
                          onPressed: () {
                            context
                                .read<LibraryCubit>()
                                .addItems(sampleImportItems(DateTime.now()));
                            AppToast.show(context, 'Sample ZIP import added.');
                          },
                        ),
                        AppButton(
                          label: 'Load sample sync',
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            context
                                .read<LibraryCubit>()
                                .addItems(sampleSyncItems(DateTime.now()));
                            AppToast.show(context, 'Sample sync added.');
                          },
                        ),
                      ],
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
                        child: _LibraryItemCard(
                          item: item,
                          onReveal: () async {
                            final success =
                                await revealInFileManager(Directory.systemTemp.path);
                            if (!context.mounted) {
                              return;
                            }
                            AppToast.show(
                              context,
                              success
                                  ? 'Opened file manager (mock path).'
                                  : 'Unable to reveal path.',
                            );
                          },
                        ),
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
  const _LibraryItemCard({
    required this.item,
    required this.onReveal,
  });

  final LibraryItem item;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
          onReveal();
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
                        item.title,
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
                  label: 'Queue download',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => AppToast.show(
                    context,
                    'Queued download (mock).',
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTokens.space.s12),
            Wrap(
              spacing: AppTokens.space.s8,
              runSpacing: AppTokens.space.s6,
              children: [
                AppChip(
                  label: item.kind == SavedKind.post ? 'POST' : 'COMMENT',
                  selected: false,
                  onSelected: (_) {},
                ),
                AppChip(
                  label: item.source == LibrarySource.zip ? 'ZIP' : 'SYNC',
                  selected: false,
                  onSelected: (_) {},
                ),
                if (item.isNsfw)
                  AppChip(
                    label: 'NSFW',
                    selected: true,
                    onSelected: (_) {},
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
