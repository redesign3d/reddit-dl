import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/logs/log_record.dart';
import '../tokens.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_chip.dart';
import 'app_text_field.dart';

class LogViewer extends StatefulWidget {
  const LogViewer({
    super.key,
    required this.entries,
  });

  final List<LogRecord> entries;

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final TextEditingController _filterController = TextEditingController();
  final Set<String> _levels = {'info', 'warn', 'error'};

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final filter = _filterController.text.toLowerCase();
    final entries = widget.entries.where((entry) {
      final matchesFilter = filter.isEmpty ||
          entry.message.toLowerCase().contains(filter) ||
          entry.scope.toLowerCase().contains(filter);
      final matchesLevel = _levels.contains(entry.level.toLowerCase());
      return matchesFilter && matchesLevel;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Filter logs',
                hint: 'Search by scope or message',
                controller: _filterController,
                onChanged: (_) => setState(() {}),
              ),
            ),
            SizedBox(width: AppTokens.space.s12),
            AppButton(
              label: 'Copy visible',
              variant: AppButtonVariant.secondary,
              onPressed: entries.isEmpty
                  ? null
                  : () {
                      final text = entries
                          .map((entry) =>
                              '[${entry.timestamp.toIso8601String()}] '
                              '${entry.level.toUpperCase()} '
                              '${entry.scope} - ${entry.message}')
                          .join('\n');
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs copied')),
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
            _buildLevelChip('info'),
            _buildLevelChip('warn'),
            _buildLevelChip('error'),
          ],
        ),
        SizedBox(height: AppTokens.space.s12),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTokens.space.s12,
                  vertical: AppTokens.space.s8,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.border),
                  ),
                ),
                child: Text(
                  '${entries.length} entries',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colors.mutedForeground),
                ),
              ),
              SizedBox(
                height: AppTokens.space.s24 * 8,
                child: ListView.separated(
                  itemCount: entries.length,
                  padding: EdgeInsets.all(AppTokens.space.s12),
                  separatorBuilder: (_, __) => Divider(color: colors.border),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _LogRow(entry: entry);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelChip(String level) {
    final selected = _levels.contains(level);
    return AppChip(
      label: level.toUpperCase(),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _levels.add(level);
          } else {
            _levels.remove(level);
          }
        });
      },
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});

  final LogRecord entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppTokens.space.s24 * 2,
          child: Text(
            entry.level.toUpperCase(),
            style: textTheme.bodySmall?.copyWith(
              color: _levelColor(colors, entry.level),
              fontWeight: AppTokens.fontWeights.medium,
            ),
          ),
        ),
        SizedBox(width: AppTokens.space.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.message,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: AppTokens.fontFamilyMono,
                ),
              ),
              SizedBox(height: AppTokens.space.s4),
              Text(
                '${entry.scope} • ${entry.timestamp.toIso8601String()}',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _levelColor(AppColorScheme colors, String level) {
    switch (level.toLowerCase()) {
      case 'error':
        return colors.destructive;
      case 'warn':
        return colors.accentForeground;
      default:
        return colors.mutedForeground;
    }
  }
}
