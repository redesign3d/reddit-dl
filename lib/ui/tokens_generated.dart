// GENERATED CODE - DO NOT MODIFY BY HAND.
// Source: assets/tokens/claude-design-tokens.json
// Source: assets/tokens/claude-globals.css

import 'package:flutter/material.dart';

class AppTokens {
  static const String fontFamilySans = 'Space Grotesk';
  static const String fontFamilyMono = 'JetBrains Mono';

  static const AppFontWeights fontWeights = AppFontWeights(
    normal: FontWeight.w400,
    medium: FontWeight.w500,
  );

  static const AppTextScale text = AppTextScale(
    sm: 14,
    base: 16,
    lg: 18,
    xl: 20,
    x2l: 24,
  );

  static const AppSpacing space = AppSpacing(
    s2: 2,
    s4: 4,
    s6: 6,
    s8: 8,
    s12: 12,
    s16: 16,
    s20: 20,
    s24: 24,
  );

  static const AppRadii radii = AppRadii(sm: 6, md: 8, lg: 10, xl: 14);

  static const AppLayout layout = AppLayout(
    navWidth: 248,
    titleBarHeight: 56,
    contentMaxWidth: 1160,
  );

  static const AppMotion motion = AppMotion(
    fast: Duration(milliseconds: 120),
    medium: Duration(milliseconds: 200),
    slow: Duration(milliseconds: 320),
  );

  static const AppShadows shadows = AppShadows(
    sm: [
      BoxShadow(
        color: Color(0x0D000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
    ],
    md: [
      BoxShadow(
        color: Color(0x14000000),
        offset: Offset(0, 6),
        blurRadius: 16,
        spreadRadius: -4,
      ),
    ],
  );

  static const AppColorScheme light = AppColorScheme(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF0A0A0A),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF0A0A0A),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF0A0A0A),
    primary: Color(0xFF030213),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFECEEF2),
    secondaryForeground: Color(0xFF030213),
    muted: Color(0xFFECECF0),
    mutedForeground: Color(0xFF717182),
    accent: Color(0xFFE9EBEF),
    accentForeground: Color(0xFF030213),
    destructive: Color(0xFFD4183D),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0x1A000000),
    input: Color(0x00000000),
    inputBackground: Color(0xFFF3F3F5),
    switchBackground: Color(0xFFCBCED4),
    ring: Color(0xFFA1A1A1),
    sidebar: Color(0xFFFAFAFA),
    sidebarForeground: Color(0xFF0A0A0A),
    sidebarPrimary: Color(0xFF030213),
    sidebarPrimaryForeground: Color(0xFFFAFAFA),
    sidebarAccent: Color(0xFFF5F5F5),
    sidebarAccentForeground: Color(0xFF171717),
    sidebarBorder: Color(0xFFE5E5E5),
    sidebarRing: Color(0xFFA1A1A1),
  );

  static const AppColorScheme dark = AppColorScheme(
    background: Color(0xFF0A0A0A),
    foreground: Color(0xFFFAFAFA),
    card: Color(0xFF0A0A0A),
    cardForeground: Color(0xFFFAFAFA),
    popover: Color(0xFF0A0A0A),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFFFAFAFA),
    primaryForeground: Color(0xFF171717),
    secondary: Color(0xFF262626),
    secondaryForeground: Color(0xFFFAFAFA),
    muted: Color(0xFF262626),
    mutedForeground: Color(0xFFA1A1A1),
    accent: Color(0xFF262626),
    accentForeground: Color(0xFFFAFAFA),
    destructive: Color(0xFF82181A),
    destructiveForeground: Color(0xFFFB2C36),
    border: Color(0xFF262626),
    input: Color(0xFF262626),
    inputBackground: Color(0xFF262626),
    switchBackground: Color(0xFF262626),
    ring: Color(0xFF525252),
    sidebar: Color(0xFF171717),
    sidebarForeground: Color(0xFFFAFAFA),
    sidebarPrimary: Color(0xFF1447E6),
    sidebarPrimaryForeground: Color(0xFFFAFAFA),
    sidebarAccent: Color(0xFF262626),
    sidebarAccentForeground: Color(0xFFFAFAFA),
    sidebarBorder: Color(0xFF262626),
    sidebarRing: Color(0xFF525252),
  );
}

class AppColorScheme {
  const AppColorScheme({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.inputBackground,
    required this.switchBackground,
    required this.ring,
    required this.sidebar,
    required this.sidebarForeground,
    required this.sidebarPrimary,
    required this.sidebarPrimaryForeground,
    required this.sidebarAccent,
    required this.sidebarAccentForeground,
    required this.sidebarBorder,
    required this.sidebarRing,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color popover;
  final Color popoverForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color inputBackground;
  final Color switchBackground;
  final Color ring;
  final Color sidebar;
  final Color sidebarForeground;
  final Color sidebarPrimary;
  final Color sidebarPrimaryForeground;
  final Color sidebarAccent;
  final Color sidebarAccentForeground;
  final Color sidebarBorder;
  final Color sidebarRing;
}

class AppSpacing {
  const AppSpacing({
    required this.s2,
    required this.s4,
    required this.s6,
    required this.s8,
    required this.s12,
    required this.s16,
    required this.s20,
    required this.s24,
  });

  final double s2;
  final double s4;
  final double s6;
  final double s8;
  final double s12;
  final double s16;
  final double s20;
  final double s24;
}

class AppRadii {
  const AppRadii({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  final double sm;
  final double md;
  final double lg;
  final double xl;
}

class AppTextScale {
  const AppTextScale({
    required this.sm,
    required this.base,
    required this.lg,
    required this.xl,
    required this.x2l,
  });

  final double sm;
  final double base;
  final double lg;
  final double xl;
  final double x2l;
}

class AppFontWeights {
  const AppFontWeights({required this.normal, required this.medium});

  final FontWeight normal;
  final FontWeight medium;
}

class AppLayout {
  const AppLayout({
    required this.navWidth,
    required this.titleBarHeight,
    required this.contentMaxWidth,
  });

  final double navWidth;
  final double titleBarHeight;
  final double contentMaxWidth;
}

class AppMotion {
  const AppMotion({
    required this.fast,
    required this.medium,
    required this.slow,
  });

  final Duration fast;
  final Duration medium;
  final Duration slow;
}

class AppShadows {
  const AppShadows({required this.sm, required this.md});

  final List<BoxShadow> sm;
  final List<BoxShadow> md;
}
