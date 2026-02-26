import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

void main() {
  final jsonFile = File('assets/tokens/claude-design-tokens.json');
  final cssFile = File('assets/tokens/claude-globals.css');

  if (!jsonFile.existsSync()) {
    stderr.writeln('Missing ${jsonFile.path}. Run tool/fetch_tokens.sh first.');
    exit(1);
  }

  if (!cssFile.existsSync()) {
    stderr.writeln('Missing ${cssFile.path}. Run tool/fetch_tokens.sh first.');
    exit(1);
  }

  final jsonData =
      jsonDecode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
  final cssText = cssFile.readAsStringSync();
  final lightVars = _parseCssVariables(cssText, ':root');
  final darkVars = _parseCssVariables(cssText, '.dark');

  final spacingScale = (jsonData['spacing']['scale'] as List<dynamic>)
      .map((value) => (value as num).toDouble())
      .toList();
  final baseFontSize = _parsePixels(
    jsonData['typography']['baseSize'] as String,
  );
  final fontWeights =
      jsonData['typography']['fontWeights'] as Map<String, dynamic>;

  final radiusBase = _parseLength(lightVars['radius'] ?? '0.625rem');

  final light = _buildColorScheme(lightVars, jsonData, 'light');
  final dark = _buildColorScheme(darkVars, jsonData, 'dark');

  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Source: assets/tokens/claude-design-tokens.json')
    ..writeln('// Source: assets/tokens/claude-globals.css')
    ..writeln()
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln()
    ..writeln('class AppTokens {')
    ..writeln("  static const String fontFamilySans = 'Space Grotesk';")
    ..writeln("  static const String fontFamilyMono = 'JetBrains Mono';")
    ..writeln()
    ..writeln('  static const AppFontWeights fontWeights = AppFontWeights(')
    ..writeln('    normal: FontWeight.w${fontWeights['normal']},')
    ..writeln('    medium: FontWeight.w${fontWeights['medium']},')
    ..writeln('  );')
    ..writeln()
    ..writeln('  static const AppTextScale text = AppTextScale(')
    ..writeln('    sm: ${_formatDouble(baseFontSize * 0.875)},')
    ..writeln('    base: ${_formatDouble(baseFontSize)},')
    ..writeln('    lg: ${_formatDouble(baseFontSize * 1.125)},')
    ..writeln('    xl: ${_formatDouble(baseFontSize * 1.25)},')
    ..writeln('    x2l: ${_formatDouble(baseFontSize * 1.5)},')
    ..writeln('  );')
    ..writeln()
    ..writeln('  static const AppSpacing space = AppSpacing(')
    ..writeln('    s2: ${_formatDouble(spacingScale[0])},')
    ..writeln('    s4: ${_formatDouble(spacingScale[1])},')
    ..writeln('    s6: ${_formatDouble(spacingScale[2])},')
    ..writeln('    s8: ${_formatDouble(spacingScale[3])},')
    ..writeln('    s12: ${_formatDouble(spacingScale[4])},')
    ..writeln('    s16: ${_formatDouble(spacingScale[5])},')
    ..writeln('    s20: ${_formatDouble(spacingScale[6])},')
    ..writeln('    s24: ${_formatDouble(spacingScale[7])},')
    ..writeln('  );')
    ..writeln()
    ..writeln('  static const AppRadii radii = AppRadii(')
    ..writeln('    sm: ${_formatDouble(radiusBase - 4)},')
    ..writeln('    md: ${_formatDouble(radiusBase - 2)},')
    ..writeln('    lg: ${_formatDouble(radiusBase)},')
    ..writeln('    xl: ${_formatDouble(radiusBase + 4)},')
    ..writeln('  );')
    ..writeln()
    ..writeln('  static const AppLayout layout = AppLayout(')
    ..writeln('    navWidth: 248,')
    ..writeln('    titleBarHeight: 56,')
    ..writeln('    contentMaxWidth: 1160,')
    ..writeln('  );')
    ..writeln()
    ..writeln('  static const AppMotion motion = AppMotion(')
    ..writeln('    fast: Duration(milliseconds: 120),')
    ..writeln('    medium: Duration(milliseconds: 200),')
    ..writeln('    slow: Duration(milliseconds: 320),')
    ..writeln('  );')
    ..writeln()
    ..writeln('  static const AppShadows shadows = AppShadows(')
    ..writeln('    sm: [')
    ..writeln('      BoxShadow(')
    ..writeln('        color: Color(0x0D000000),')
    ..writeln('        offset: Offset(0, 1),')
    ..writeln('        blurRadius: 2,')
    ..writeln('        spreadRadius: 0,')
    ..writeln('      ),')
    ..writeln('    ],')
    ..writeln('    md: [')
    ..writeln('      BoxShadow(')
    ..writeln('        color: Color(0x14000000),')
    ..writeln('        offset: Offset(0, 6),')
    ..writeln('        blurRadius: 16,')
    ..writeln('        spreadRadius: -4,')
    ..writeln('      ),')
    ..writeln('    ],')
    ..writeln('  );')
    ..writeln()
    ..writeln('  static const AppColorScheme light = AppColorScheme(')
    ..writeln(_renderColorScheme(light))
    ..writeln('  );')
    ..writeln()
    ..writeln('  static const AppColorScheme dark = AppColorScheme(')
    ..writeln(_renderColorScheme(dark))
    ..writeln('  );')
    ..writeln('}')
    ..writeln()
    ..writeln('class AppColorScheme {')
    ..writeln('  const AppColorScheme({')
    ..writeln('    required this.background,')
    ..writeln('    required this.foreground,')
    ..writeln('    required this.card,')
    ..writeln('    required this.cardForeground,')
    ..writeln('    required this.popover,')
    ..writeln('    required this.popoverForeground,')
    ..writeln('    required this.primary,')
    ..writeln('    required this.primaryForeground,')
    ..writeln('    required this.secondary,')
    ..writeln('    required this.secondaryForeground,')
    ..writeln('    required this.muted,')
    ..writeln('    required this.mutedForeground,')
    ..writeln('    required this.accent,')
    ..writeln('    required this.accentForeground,')
    ..writeln('    required this.destructive,')
    ..writeln('    required this.destructiveForeground,')
    ..writeln('    required this.border,')
    ..writeln('    required this.input,')
    ..writeln('    required this.inputBackground,')
    ..writeln('    required this.switchBackground,')
    ..writeln('    required this.ring,')
    ..writeln('    required this.sidebar,')
    ..writeln('    required this.sidebarForeground,')
    ..writeln('    required this.sidebarPrimary,')
    ..writeln('    required this.sidebarPrimaryForeground,')
    ..writeln('    required this.sidebarAccent,')
    ..writeln('    required this.sidebarAccentForeground,')
    ..writeln('    required this.sidebarBorder,')
    ..writeln('    required this.sidebarRing,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final Color background;')
    ..writeln('  final Color foreground;')
    ..writeln('  final Color card;')
    ..writeln('  final Color cardForeground;')
    ..writeln('  final Color popover;')
    ..writeln('  final Color popoverForeground;')
    ..writeln('  final Color primary;')
    ..writeln('  final Color primaryForeground;')
    ..writeln('  final Color secondary;')
    ..writeln('  final Color secondaryForeground;')
    ..writeln('  final Color muted;')
    ..writeln('  final Color mutedForeground;')
    ..writeln('  final Color accent;')
    ..writeln('  final Color accentForeground;')
    ..writeln('  final Color destructive;')
    ..writeln('  final Color destructiveForeground;')
    ..writeln('  final Color border;')
    ..writeln('  final Color input;')
    ..writeln('  final Color inputBackground;')
    ..writeln('  final Color switchBackground;')
    ..writeln('  final Color ring;')
    ..writeln('  final Color sidebar;')
    ..writeln('  final Color sidebarForeground;')
    ..writeln('  final Color sidebarPrimary;')
    ..writeln('  final Color sidebarPrimaryForeground;')
    ..writeln('  final Color sidebarAccent;')
    ..writeln('  final Color sidebarAccentForeground;')
    ..writeln('  final Color sidebarBorder;')
    ..writeln('  final Color sidebarRing;')
    ..writeln('}')
    ..writeln()
    ..writeln('class AppSpacing {')
    ..writeln('  const AppSpacing({')
    ..writeln('    required this.s2,')
    ..writeln('    required this.s4,')
    ..writeln('    required this.s6,')
    ..writeln('    required this.s8,')
    ..writeln('    required this.s12,')
    ..writeln('    required this.s16,')
    ..writeln('    required this.s20,')
    ..writeln('    required this.s24,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final double s2;')
    ..writeln('  final double s4;')
    ..writeln('  final double s6;')
    ..writeln('  final double s8;')
    ..writeln('  final double s12;')
    ..writeln('  final double s16;')
    ..writeln('  final double s20;')
    ..writeln('  final double s24;')
    ..writeln('}')
    ..writeln()
    ..writeln('class AppRadii {')
    ..writeln('  const AppRadii({')
    ..writeln('    required this.sm,')
    ..writeln('    required this.md,')
    ..writeln('    required this.lg,')
    ..writeln('    required this.xl,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final double sm;')
    ..writeln('  final double md;')
    ..writeln('  final double lg;')
    ..writeln('  final double xl;')
    ..writeln('}')
    ..writeln()
    ..writeln('class AppTextScale {')
    ..writeln('  const AppTextScale({')
    ..writeln('    required this.sm,')
    ..writeln('    required this.base,')
    ..writeln('    required this.lg,')
    ..writeln('    required this.xl,')
    ..writeln('    required this.x2l,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final double sm;')
    ..writeln('  final double base;')
    ..writeln('  final double lg;')
    ..writeln('  final double xl;')
    ..writeln('  final double x2l;')
    ..writeln('}')
    ..writeln()
    ..writeln('class AppFontWeights {')
    ..writeln('  const AppFontWeights({')
    ..writeln('    required this.normal,')
    ..writeln('    required this.medium,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final FontWeight normal;')
    ..writeln('  final FontWeight medium;')
    ..writeln('}')
    ..writeln()
    ..writeln('class AppLayout {')
    ..writeln('  const AppLayout({')
    ..writeln('    required this.navWidth,')
    ..writeln('    required this.titleBarHeight,')
    ..writeln('    required this.contentMaxWidth,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final double navWidth;')
    ..writeln('  final double titleBarHeight;')
    ..writeln('  final double contentMaxWidth;')
    ..writeln('}')
    ..writeln()
    ..writeln('class AppMotion {')
    ..writeln('  const AppMotion({')
    ..writeln('    required this.fast,')
    ..writeln('    required this.medium,')
    ..writeln('    required this.slow,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final Duration fast;')
    ..writeln('  final Duration medium;')
    ..writeln('  final Duration slow;')
    ..writeln('}')
    ..writeln()
    ..writeln('class AppShadows {')
    ..writeln('  const AppShadows({')
    ..writeln('    required this.sm,')
    ..writeln('    required this.md,')
    ..writeln('  });')
    ..writeln()
    ..writeln('  final List<BoxShadow> sm;')
    ..writeln('  final List<BoxShadow> md;')
    ..writeln('}')
    ..writeln();

  File('lib/ui/tokens_generated.dart').writeAsStringSync(buffer.toString());
}

Map<String, String> _parseCssVariables(String css, String selector) {
  final blockMatch = RegExp(
    '${RegExp.escape(selector)}\\s*\\{([\\s\\S]*?)\\}',
  ).firstMatch(css);
  if (blockMatch == null) {
    return {};
  }
  final block = blockMatch.group(1) ?? '';
  final regex = RegExp(r'--([a-zA-Z0-9\-]+)\s*:\s*([^;]+);');
  final vars = <String, String>{};
  for (final match in regex.allMatches(block)) {
    vars[match.group(1)!] = match.group(2)!.trim();
  }
  return vars;
}

Map<String, String> _buildColorScheme(
  Map<String, String> cssVars,
  Map<String, dynamic> jsonData,
  String tone,
) {
  final semantic = jsonData['colors']['semantic'] as Map<String, dynamic>;

  String resolveJson(String key) {
    final entry = semantic[key] as Map<String, dynamic>;
    return entry[tone] as String;
  }

  String resolve(String key, {String? jsonKey}) {
    final cssValue = cssVars[key];
    if (cssValue != null) {
      return cssValue;
    }
    if (jsonKey != null) {
      return resolveJson(jsonKey);
    }
    return resolveJson(key);
  }

  return {
    'background': resolve('background'),
    'foreground': resolve('foreground'),
    'card': resolve('card', jsonKey: 'background'),
    'cardForeground': resolve('card-foreground', jsonKey: 'foreground'),
    'popover': resolve('popover', jsonKey: 'background'),
    'popoverForeground': resolve('popover-foreground', jsonKey: 'foreground'),
    'primary': resolve('primary'),
    'primaryForeground': resolve('primary-foreground', jsonKey: 'foreground'),
    'secondary': resolve('secondary'),
    'secondaryForeground': resolve(
      'secondary-foreground',
      jsonKey: 'foreground',
    ),
    'muted': resolve('muted'),
    'mutedForeground': resolve('muted-foreground'),
    'accent': resolve('accent', jsonKey: 'secondary'),
    'accentForeground': resolve('accent-foreground', jsonKey: 'foreground'),
    'destructive': resolve('destructive'),
    'destructiveForeground': resolve(
      'destructive-foreground',
      jsonKey: 'foreground',
    ),
    'border': resolve('border'),
    'input': resolve('input', jsonKey: 'border'),
    'inputBackground': resolve('input-background', jsonKey: 'muted'),
    'switchBackground': resolve('switch-background', jsonKey: 'muted'),
    'ring': resolve('ring', jsonKey: 'muted-foreground'),
    'sidebar': resolve('sidebar', jsonKey: 'background'),
    'sidebarForeground': resolve('sidebar-foreground', jsonKey: 'foreground'),
    'sidebarPrimary': resolve('sidebar-primary', jsonKey: 'primary'),
    'sidebarPrimaryForeground': resolve(
      'sidebar-primary-foreground',
      jsonKey: 'foreground',
    ),
    'sidebarAccent': resolve('sidebar-accent', jsonKey: 'secondary'),
    'sidebarAccentForeground': resolve(
      'sidebar-accent-foreground',
      jsonKey: 'foreground',
    ),
    'sidebarBorder': resolve('sidebar-border', jsonKey: 'border'),
    'sidebarRing': resolve('sidebar-ring', jsonKey: 'ring'),
  };
}

String _renderColorScheme(Map<String, String> values) {
  final buffer = StringBuffer();
  for (final entry in values.entries) {
    buffer.writeln('    ${entry.key}: Color(${_colorToHex(entry.value)}),');
  }
  return buffer.toString();
}

String _colorToHex(String input) {
  final value = input.trim();
  if (value == 'transparent') {
    return '0x00000000';
  }
  if (value.startsWith('#')) {
    return _hexToArgb(value);
  }
  if (value.startsWith('rgba')) {
    return _rgbaToArgb(value);
  }
  if (value.startsWith('oklch')) {
    return _oklchToArgb(value);
  }
  return '0xFF000000';
}

String _hexToArgb(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 3) {
    final r = (cleaned[0] * 2).toUpperCase();
    final g = (cleaned[1] * 2).toUpperCase();
    final b = (cleaned[2] * 2).toUpperCase();
    return '0xFF$r$g$b';
  }
  if (cleaned.length == 6) {
    return '0xFF${cleaned.toUpperCase()}';
  }
  if (cleaned.length == 8) {
    return '0x${cleaned.toUpperCase()}';
  }
  return '0xFF000000';
}

String _rgbaToArgb(String rgba) {
  final match = RegExp(r'rgba\(([^)]+)\)').firstMatch(rgba);
  if (match == null) {
    return '0xFF000000';
  }
  final parts = match.group(1)!.split(',').map((part) => part.trim()).toList();
  if (parts.length < 4) {
    return '0xFF000000';
  }
  final r = int.parse(parts[0]);
  final g = int.parse(parts[1]);
  final b = int.parse(parts[2]);
  final a = (double.parse(parts[3]) * 255).round();
  return _argbToHex(a, r, g, b);
}

String _oklchToArgb(String value) {
  final match = RegExp(r'oklch\(([^)]+)\)').firstMatch(value);
  if (match == null) {
    return '0xFF000000';
  }
  final parts = match.group(1)!.split(RegExp(r'\s+')).toList();
  if (parts.length < 3) {
    return '0xFF000000';
  }
  final l = double.parse(parts[0]);
  final c = double.parse(parts[1]);
  final h = double.parse(parts[2]);
  final a = c * math.cos(h * math.pi / 180.0);
  final b = c * math.sin(h * math.pi / 180.0);

  final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  final s_ = l - 0.0894841775 * a - 1.2914855480 * b;

  final l3 = l_ * l_ * l_;
  final m3 = m_ * m_ * m_;
  final s3 = s_ * s_ * s_;

  var r = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3;
  var g = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3;
  var b2 = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3;

  r = _linearToSrgb(r);
  g = _linearToSrgb(g);
  b2 = _linearToSrgb(b2);

  return _argbToHex(
    255,
    (r * 255).round(),
    (g * 255).round(),
    (b2 * 255).round(),
  );
}

double _linearToSrgb(double value) {
  final clamped = value.clamp(0.0, 1.0);
  if (clamped <= 0.0031308) {
    return 12.92 * clamped;
  }
  return 1.055 * math.pow(clamped, 1 / 2.4) - 0.055;
}

String _argbToHex(int a, int r, int g, int b) {
  String toHex(int value) =>
      value.toRadixString(16).padLeft(2, '0').toUpperCase();
  return '0x${toHex(a)}${toHex(r)}${toHex(g)}${toHex(b)}';
}

double _parsePixels(String value) {
  final cleaned = value.trim().replaceAll('px', '');
  return double.parse(cleaned);
}

double _parseLength(String value) {
  final trimmed = value.trim();
  if (trimmed.endsWith('rem')) {
    final number = double.parse(trimmed.replaceAll('rem', ''));
    return number * 16;
  }
  if (trimmed.endsWith('px')) {
    return double.parse(trimmed.replaceAll('px', ''));
  }
  return double.parse(trimmed);
}

String _formatDouble(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}
