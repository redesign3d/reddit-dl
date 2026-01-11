import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import '../library/library_cubit.dart';
import '../library/sample_data.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  int? _lastImported;

  void _runMockImport(BuildContext context) {
    final items = sampleImportItems(DateTime.now());
    context.read<LibraryCubit>().addItems(items);
    setState(() {
      _lastImported = items.length;
    });
    AppToast.show(context, 'Imported ${items.length} items from ZIP.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Backfill from Reddit ZIP',
            style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: AppTokens.space.s6),
        Text(
          'Drag and drop your Reddit data request ZIP to index saved posts and comments.',
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
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppTokens.space.s16),
                decoration: BoxDecoration(
                  color: colors.muted,
                  borderRadius: BorderRadius.circular(AppTokens.radii.lg),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Drop ZIP here',
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: AppTokens.space.s6),
                    Text(
                      'Includes saved_posts.csv and saved_comments.csv.',
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
                          label: 'Select ZIP',
                          onPressed: () => _runMockImport(context),
                        ),
                        AppButton(
                          label: 'Use sample ZIP',
                          variant: AppButtonVariant.secondary,
                          onPressed: () => _runMockImport(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTokens.space.s12),
              if (_lastImported != null)
                Text(
                  'Last import: $_lastImported items indexed.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.mutedForeground),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
