import 'package:flutter/material.dart';

import '../tokens.dart';

class AppProgress extends StatelessWidget {
  const AppProgress({
    super.key,
    required this.progress,
    this.label,
  });

  final double progress;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.mutedForeground),
          ),
        SizedBox(height: AppTokens.space.s6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radii.lg),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: AppTokens.space.s6,
          ),
        ),
        SizedBox(height: AppTokens.space.s6),
        Text('$percent% complete', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
