import 'package:flutter/material.dart';

import '../tokens.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: colors.muted,
      selectedColor: colors.secondary,
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: selected ? colors.secondaryForeground : colors.foreground,
          ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radii.lg),
        side: BorderSide(color: colors.border),
      ),
    );
  }
}
