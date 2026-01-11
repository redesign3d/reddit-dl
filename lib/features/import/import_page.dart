import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../navigation/navigation_cubit.dart';
import '../../navigation/app_section.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/tokens.dart';
import 'import_cubit.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  Future<void> _pickZip(BuildContext context) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'ZIP', extensions: ['zip']),
      ],
    );
    if (file == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    await _importFile(context, file.path, file.name);
  }

  Future<void> _importFile(
    BuildContext context,
    String path,
    String filename,
  ) async {
    try {
      final bytes = await File(path).readAsBytes();
      if (!context.mounted) {
        return;
      }
      await context.read<ImportCubit>().importZipBytes(
        bytes,
        filename: filename,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      await context.read<ImportCubit>().setError(
        'Failed to read ZIP file: $error',
      );
    }
  }

  Future<void> _handleDrop(
    BuildContext context,
    DropDoneDetails details,
  ) async {
    if (details.files.isEmpty) {
      return;
    }
    final file = details.files.first;
    if (!file.path.toLowerCase().endsWith('.zip')) {
      context.read<ImportCubit>().setDragging(false);
      await context.read<ImportCubit>().setError(
        'Please drop a .zip file exported from Reddit.',
      );
      return;
    }
    await _importFile(context, file.path, file.name);
    if (!context.mounted) {
      return;
    }
    context.read<ImportCubit>().setDragging(false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ImportCubit, ImportState>(
      builder: (context, state) {
        final colors = context.appColors;
        final isImporting = state.status == ImportStatus.importing;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backfill from Reddit ZIP',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: AppTokens.space.s6),
            Text(
              'Drag and drop your Reddit data request ZIP to index saved posts and comments.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
            SizedBox(height: AppTokens.space.s16),
            DropTarget(
              onDragEntered:
                  (_) => context.read<ImportCubit>().setDragging(true),
              onDragExited:
                  (_) => context.read<ImportCubit>().setDragging(false),
              onDragDone: (details) => _handleDrop(context, details),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: AppTokens.motion.fast,
                      width: double.infinity,
                      padding: EdgeInsets.all(AppTokens.space.s16),
                      decoration: BoxDecoration(
                        color: state.isDragging ? colors.accent : colors.muted,
                        borderRadius: BorderRadius.circular(AppTokens.radii.lg),
                        border: Border.all(
                          color: state.isDragging ? colors.ring : colors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drop ZIP here',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: AppTokens.space.s6),
                          Text(
                            'Includes saved_posts.csv and saved_comments.csv.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.mutedForeground),
                          ),
                          SizedBox(height: AppTokens.space.s12),
                          Wrap(
                            spacing: AppTokens.space.s8,
                            runSpacing: AppTokens.space.s8,
                            children: [
                              AppButton(
                                label: 'Select ZIP',
                                onPressed:
                                    isImporting
                                        ? null
                                        : () => _pickZip(context),
                              ),
                              AppButton(
                                label: 'Reset',
                                variant: AppButtonVariant.ghost,
                                onPressed:
                                    isImporting
                                        ? null
                                        : () =>
                                            context.read<ImportCubit>().reset(),
                              ),
                            ],
                          ),
                          if (state.filename != null) ...[
                            SizedBox(height: AppTokens.space.s12),
                            Text(
                              'Selected: ${state.filename}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.mutedForeground),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isImporting) ...[
                      SizedBox(height: AppTokens.space.s12),
                      Row(
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: AppTokens.space.s8),
                          Text(
                            'Importing ZIP...',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                    if (state.status == ImportStatus.error &&
                        state.errorMessage != null) ...[
                      SizedBox(height: AppTokens.space.s12),
                      AppCard(
                        child: Text(
                          state.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.destructive),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (state.status == ImportStatus.success &&
                state.result != null) ...[
              SizedBox(height: AppTokens.space.s16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    Wrap(
                      spacing: AppTokens.space.s12,
                      runSpacing: AppTokens.space.s12,
                      children: [
                        _SummaryTile(
                          label: 'Posts',
                          value: state.result!.posts.toString(),
                        ),
                        _SummaryTile(
                          label: 'Comments',
                          value: state.result!.comments.toString(),
                        ),
                        _SummaryTile(
                          label: 'Inserted',
                          value: state.result!.inserted.toString(),
                        ),
                        _SummaryTile(
                          label: 'Updated',
                          value: state.result!.updated.toString(),
                        ),
                        _SummaryTile(
                          label: 'Skipped',
                          value: state.result!.skipped.toString(),
                        ),
                        _SummaryTile(
                          label: 'Failures',
                          value: state.result!.failures.toString(),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTokens.space.s12),
                    AppButton(
                      label: 'View in library',
                      variant: AppButtonVariant.secondary,
                      onPressed:
                          () => context.read<NavigationCubit>().select(
                            AppSection.library,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 140,
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
