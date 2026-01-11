import 'package:flutter/material.dart';

import '../tokens.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final child = isLoading
        ? SizedBox(
            height: AppTokens.text.base,
            width: AppTokens.text.base,
            child: CircularProgressIndicator(
              strokeWidth: AppTokens.space.s2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _foregroundColor(colors),
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppTokens.text.lg),
                SizedBox(width: AppTokens.space.s6),
              ],
              Text(label),
            ],
          );

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(theme.textTheme.labelLarge),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppTokens.space.s16,
            vertical: AppTokens.space.s8,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radii.lg),
            side: BorderSide(
              color: _borderColor(colors),
            ),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.muted;
          }
          return _backgroundColor(colors);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.mutedForeground;
          }
          return _foregroundColor(colors);
        }),
      ),
      child: child,
    );
  }

  Color _backgroundColor(AppColorScheme colors) {
    switch (variant) {
      case AppButtonVariant.primary:
        return colors.primary;
      case AppButtonVariant.secondary:
        return colors.secondary;
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.destructive:
        return colors.destructive;
    }
  }

  Color _foregroundColor(AppColorScheme colors) {
    switch (variant) {
      case AppButtonVariant.primary:
        return colors.primaryForeground;
      case AppButtonVariant.secondary:
        return colors.secondaryForeground;
      case AppButtonVariant.ghost:
        return colors.foreground;
      case AppButtonVariant.destructive:
        return colors.destructiveForeground;
    }
  }

  Color _borderColor(AppColorScheme colors) {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        return Colors.transparent;
      case AppButtonVariant.secondary:
      case AppButtonVariant.ghost:
        return colors.border;
    }
  }
}
