import 'package:flutter/material.dart';

import 'tokens.dart';

class AppTheme {
  static ThemeData light() => _buildTheme(AppTokens.light, Brightness.light);

  static ThemeData dark() => _buildTheme(AppTokens.dark, Brightness.dark);

  static ThemeData _buildTheme(AppColorScheme colors, Brightness brightness) {
    final textTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: AppTokens.text.x2l,
        fontWeight: AppTokens.fontWeights.medium,
        height: 1.5,
      ),
      headlineMedium: TextStyle(
        fontSize: AppTokens.text.xl,
        fontWeight: AppTokens.fontWeights.medium,
        height: 1.5,
      ),
      titleLarge: TextStyle(
        fontSize: AppTokens.text.lg,
        fontWeight: AppTokens.fontWeights.medium,
        height: 1.5,
      ),
      bodyLarge: TextStyle(
        fontSize: AppTokens.text.base,
        fontWeight: AppTokens.fontWeights.normal,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: AppTokens.text.base,
        fontWeight: AppTokens.fontWeights.normal,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: AppTokens.text.sm,
        fontWeight: AppTokens.fontWeights.normal,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: AppTokens.text.base,
        fontWeight: AppTokens.fontWeights.medium,
        height: 1.5,
      ),
    ).apply(
      fontFamily: AppTokens.fontFamilySans,
      displayColor: colors.foreground,
      bodyColor: colors.foreground,
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.primaryForeground,
      secondary: colors.secondary,
      onSecondary: colors.secondaryForeground,
      error: colors.destructive,
      onError: colors.destructiveForeground,
      surface: colors.card,
      onSurface: colors.cardForeground,
      outline: colors.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      cardColor: colors.card,
      dividerColor: colors.border,
      textTheme: textTheme,
      fontFamily: AppTokens.fontFamilySans,
      focusColor: colors.ring,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.foreground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.background,
        ),
        actionTextColor: colors.background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radii.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputBackground,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: colors.mutedForeground,
        ),
        hintStyle: textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTokens.space.s12,
          vertical: AppTokens.space.s8,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radii.lg),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radii.lg),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radii.lg),
          borderSide: BorderSide(color: colors.ring, width: 1),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.radii.lg),
            borderSide: BorderSide(color: colors.border),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.muted,
        selectedColor: colors.secondary,
        labelStyle: textTheme.bodySmall?.copyWith(color: colors.foreground),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          color: colors.secondaryForeground,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radii.lg),
          side: BorderSide(color: colors.border),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }
          return colors.switchBackground;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primaryForeground;
          }
          return colors.background;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.muted,
        thumbColor: colors.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.muted,
      ),
      iconTheme: IconThemeData(color: colors.foreground),
    );
  }
}
