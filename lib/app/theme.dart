import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens from docs/design-guide.html (v1.1).
class JmColors {
  static const cobalt = Color(0xFF1E5EFF);
  static const azure = Color(0xFF2EA8FF);
  static const match = Color(0xFF16C172);
  static const volt = Color(0xFFFFE600);
  static const cobaltDeep = Color(0xFF163FB8);
  static const azureDeep = Color(0xFF0B6FD1);
  static const matchDeep = Color(0xFF0A7F45);
  static const voltDeep = Color(0xFF7A6200);
  static const danger = Color(0xFFE03131);
  static const ink = Color(0xFF0B1F3A);
  static const text = Color(0xFF22354F);
  static const muted = Color(0xFF5A6B82);
  static const line = Color(0xFFD3DCEA);
  static const surface = Color(0xFFF2F5FB);
}

/// Tier colours are not ColorScheme slots — exposed as a ThemeExtension.
class JmTierColors extends ThemeExtension<JmTierColors> {
  const JmTierColors({
    required this.strongBg, required this.strongFg,
    required this.goodBg, required this.goodFg,
    required this.skipBg, required this.skipFg,
    required this.highlight,
  });
  final Color strongBg, strongFg, goodBg, goodFg, skipBg, skipFg, highlight;

  static const light = JmTierColors(
    strongBg: Color(0xFFDCF9EA), strongFg: JmColors.matchDeep,
    goodBg: Color(0xFFFFF9C2), goodFg: JmColors.voltDeep,
    skipBg: Color(0xFFE6EBF5), skipFg: JmColors.muted,
    highlight: JmColors.volt,
  );
  static const dark = JmTierColors(
    strongBg: Color(0xFF0C3A26), strongFg: Color(0xFF5EE6A0),
    goodBg: Color(0xFF3D3600), goodFg: Color(0xFFFFE84D),
    skipBg: Color(0xFF16233D), skipFg: Color(0xFF8C9BB0),
    highlight: JmColors.volt,
  );

  @override
  JmTierColors copyWith({Color? strongBg, Color? strongFg, Color? goodBg, Color? goodFg, Color? skipBg, Color? skipFg, Color? highlight}) =>
      JmTierColors(
        strongBg: strongBg ?? this.strongBg, strongFg: strongFg ?? this.strongFg,
        goodBg: goodBg ?? this.goodBg, goodFg: goodFg ?? this.goodFg,
        skipBg: skipBg ?? this.skipBg, skipFg: skipFg ?? this.skipFg,
        highlight: highlight ?? this.highlight,
      );

  @override
  JmTierColors lerp(JmTierColors? other, double t) {
    if (other == null) return this;
    return JmTierColors(
      strongBg: Color.lerp(strongBg, other.strongBg, t)!, strongFg: Color.lerp(strongFg, other.strongFg, t)!,
      goodBg: Color.lerp(goodBg, other.goodBg, t)!, goodFg: Color.lerp(goodFg, other.goodFg, t)!,
      skipBg: Color.lerp(skipBg, other.skipBg, t)!, skipFg: Color.lerp(skipFg, other.skipFg, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? const Color(0xFF3B78FF) : JmColors.cobalt,
    onPrimary: Colors.white,
    secondary: JmColors.azure,
    onSecondary: JmColors.ink,
    tertiary: JmColors.match,
    onTertiary: JmColors.ink,
    error: dark ? const Color(0xFFFF6B6B) : JmColors.danger,
    onError: Colors.white,
    surface: dark ? const Color(0xFF0F1B33) : Colors.white,
    onSurface: dark ? const Color(0xFFEEF3FA) : JmColors.ink,
    surfaceContainerHighest: dark ? const Color(0xFF16233D) : JmColors.surface,
    outline: dark ? const Color(0xFF2C3D5C) : JmColors.line,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final body = GoogleFonts.instrumentSansTextTheme(base.textTheme);
  final display = GoogleFonts.outfit();
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xFF070F1F) : Colors.white,
    textTheme: body.copyWith(
      displayLarge: display.copyWith(fontSize: 32, fontWeight: FontWeight.w700, color: scheme.onSurface),
      titleLarge: display.copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: scheme.onSurface),
      titleMedium: display.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: scheme.onSurface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: JmColors.cobalt, width: 2)),
    ),
    extensions: [dark ? JmTierColors.dark : JmTierColors.light],
  );
}
