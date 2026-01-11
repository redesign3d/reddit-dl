import 'package:flutter/material.dart';

import '../tokens.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTokens.radii.lg),
        border: Border.all(color: colors.border),
        boxShadow: AppTokens.shadows.sm,
      ),
      padding: padding ?? EdgeInsets.all(AppTokens.space.s16),
      child: child,
    );
  }
}
