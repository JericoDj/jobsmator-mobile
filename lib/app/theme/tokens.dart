import 'package:flutter/material.dart';

/// Design tokens from docs/design-guide.html (v1.1).
///
/// Everything visual in the app should trace back to a value in this file.
/// Colours live in [JmColors] (a ThemeExtension so light/dark resolve through
/// the theme); spacing, radius and motion are plain constants because they do
/// not change with brightness.

/// The full palette for one brightness. Read it with `context.jm`.
class JmColors extends ThemeExtension<JmColors> {
  const JmColors({
    required this.ocean,
    required this.sky,
    required this.match,
    required this.volt,
    required this.oceanDeep,
    required this.skyDeep,
    required this.matchDeep,
    required this.voltDeep,
    required this.oceanTint,
    required this.skyTint,
    required this.matchTint,
    required this.voltTint,
    required this.danger,
    required this.dangerTint,
    required this.warn,
    required this.warnTint,
    required this.ink,
    required this.text,
    required this.muted,
    required this.faint,
    required this.line,
    required this.lineStrong,
    required this.surface,
    required this.surface2,
    required this.ground,
    required this.card,
    required this.focus,
    required this.codeBg,
    required this.codeFg,
    required this.shadow,
  });

  // Brand — each has exactly one job (guide §02).
  final Color ocean; // Cobalt · primary. The only brand hue allowed as text on white.
  final Color sky; // Azure · interactive: focus rings, hover washes, info.
  final Color match; // Match · success, the strong tier. Earned, not sprinkled.
  final Color volt; // Volt · marker: highlighted skills, good tier, unread dot.

  // Text-safe derivatives (AA on the ground colour).
  final Color oceanDeep, skyDeep, matchDeep, voltDeep;

  // Tints — chip and banner backgrounds.
  final Color oceanTint, skyTint, matchTint, voltTint;

  // Semantic, never decorative.
  final Color danger, dangerTint, warn, warnTint;

  // Neutrals, navy-biased so greys feel part of the family.
  final Color ink, text, muted, faint;
  final Color line, lineStrong;
  final Color surface, surface2, ground, card;

  final Color focus;
  final Color codeBg, codeFg;

  /// The one shadow, spent only on the job card, dialogs and toasts.
  final List<BoxShadow> shadow;

  static const light = JmColors(
    ocean: Color(0xFF1E5EFF),
    sky: Color(0xFF2EA8FF),
    match: Color(0xFF16C172),
    volt: Color(0xFFFFE600),
    oceanDeep: Color(0xFF163FB8),
    skyDeep: Color(0xFF0B6FD1),
    matchDeep: Color(0xFF0A7F45),
    voltDeep: Color(0xFF7A6200),
    oceanTint: Color(0xFFE4ECFF),
    skyTint: Color(0xFFE0F3FF),
    matchTint: Color(0xFFDCF9EA),
    voltTint: Color(0xFFFFF9C2),
    danger: Color(0xFFE03131),
    dangerTint: Color(0xFFFFE6E6),
    warn: Color(0xFFD97706),
    warnTint: Color(0xFFFFF1DB),
    ink: Color(0xFF0B1F3A),
    text: Color(0xFF22354F),
    muted: Color(0xFF5A6B82),
    faint: Color(0xFF8C9BB0),
    line: Color(0xFFD3DCEA),
    lineStrong: Color(0xFFB8C5D8),
    surface: Color(0xFFF2F5FB),
    surface2: Color(0xFFE6EBF5),
    ground: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    focus: Color(0xFF2EA8FF),
    codeBg: Color(0xFF0B1F3A),
    codeFg: Color(0xFFDCE8F2),
    shadow: [
      BoxShadow(color: Color(0x140B1F3A), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x1F0B1F3A), offset: Offset(0, 8), blurRadius: 24),
    ],
  );

  static const dark = JmColors(
    ocean: Color(0xFF3B78FF),
    sky: Color(0xFF2EA8FF),
    match: Color(0xFF16C172),
    volt: Color(0xFFFFE600),
    oceanDeep: Color(0xFF8FB0FF),
    skyDeep: Color(0xFF86CFFF),
    matchDeep: Color(0xFF5EE6A0),
    voltDeep: Color(0xFFFFE84D),
    oceanTint: Color(0xFF132A5C),
    skyTint: Color(0xFF0F2C48),
    matchTint: Color(0xFF0C3A26),
    voltTint: Color(0xFF3D3600),
    danger: Color(0xFFFF6B6B),
    dangerTint: Color(0xFF4A1A1A),
    warn: Color(0xFFFBBF24),
    warnTint: Color(0xFF433012),
    ink: Color(0xFFEEF3FA),
    text: Color(0xFFC9D4E3),
    muted: Color(0xFF8C9BB0),
    faint: Color(0xFF5F6F86),
    line: Color(0xFF1F2E48),
    lineStrong: Color(0xFF2C3D5C),
    surface: Color(0xFF0B162B),
    surface2: Color(0xFF16233D),
    ground: Color(0xFF070F1F),
    card: Color(0xFF0F1B33),
    focus: Color(0xFF2EA8FF),
    codeBg: Color(0xFF03080F),
    codeFg: Color(0xFFCFE0EC),
    shadow: [
      BoxShadow(color: Color(0x80000000), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color(0x73000000), offset: Offset(0, 8), blurRadius: 24),
    ],
  );

  /// Navy is always navy — the hero band and toasts keep it in both themes.
  static const navy = Color(0xFF0B1F3A);
  static const navyText = Color(0xFFC9D4E3);

  @override
  JmColors copyWith() => this;

  @override
  JmColors lerp(JmColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return JmColors(
      ocean: c(ocean, other.ocean),
      sky: c(sky, other.sky),
      match: c(match, other.match),
      volt: c(volt, other.volt),
      oceanDeep: c(oceanDeep, other.oceanDeep),
      skyDeep: c(skyDeep, other.skyDeep),
      matchDeep: c(matchDeep, other.matchDeep),
      voltDeep: c(voltDeep, other.voltDeep),
      oceanTint: c(oceanTint, other.oceanTint),
      skyTint: c(skyTint, other.skyTint),
      matchTint: c(matchTint, other.matchTint),
      voltTint: c(voltTint, other.voltTint),
      danger: c(danger, other.danger),
      dangerTint: c(dangerTint, other.dangerTint),
      warn: c(warn, other.warn),
      warnTint: c(warnTint, other.warnTint),
      ink: c(ink, other.ink),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      faint: c(faint, other.faint),
      line: c(line, other.line),
      lineStrong: c(lineStrong, other.lineStrong),
      surface: c(surface, other.surface),
      surface2: c(surface2, other.surface2),
      ground: c(ground, other.ground),
      card: c(card, other.card),
      focus: c(focus, other.focus),
      codeBg: c(codeBg, other.codeBg),
      codeFg: c(codeFg, other.codeFg),
      shadow: t < .5 ? shadow : other.shadow,
    );
  }
}

/// Tier colours are not ColorScheme slots (guide §09, "Flutter mapping").
/// Tint background + deep text for chips; the dot is the raw brand hue.
class JmTierColors extends ThemeExtension<JmTierColors> {
  const JmTierColors({
    required this.strongBg,
    required this.strongFg,
    required this.strongDot,
    required this.goodBg,
    required this.goodFg,
    required this.goodDot,
    required this.skipBg,
    required this.skipFg,
    required this.skipDot,
    required this.highlight,
    required this.highlightFg,
  });

  final Color strongBg, strongFg, strongDot;
  final Color goodBg, goodFg, goodDot;
  final Color skipBg, skipFg, skipDot;

  /// Volt behind matched skills inside the "why" text. Always navy text on it.
  final Color highlight, highlightFg;

  static const light = JmTierColors(
    strongBg: Color(0xFFDCF9EA),
    strongFg: Color(0xFF0A7F45),
    strongDot: Color(0xFF16C172),
    goodBg: Color(0xFFFFF9C2),
    goodFg: Color(0xFF7A6200),
    goodDot: Color(0xFFFFE600),
    skipBg: Color(0xFFE6EBF5),
    skipFg: Color(0xFF5A6B82),
    skipDot: Color(0xFF8C9BB0),
    highlight: Color(0xFFFFE600),
    highlightFg: Color(0xFF0B1F3A),
  );

  static const dark = JmTierColors(
    strongBg: Color(0xFF0C3A26),
    strongFg: Color(0xFF5EE6A0),
    strongDot: Color(0xFF16C172),
    goodBg: Color(0xFF3D3600),
    goodFg: Color(0xFFFFE84D),
    goodDot: Color(0xFFFFE600),
    skipBg: Color(0xFF16233D),
    skipFg: Color(0xFF8C9BB0),
    skipDot: Color(0xFF5F6F86),
    highlight: Color(0xFFFFE600),
    highlightFg: Color(0xFF0B1F3A),
  );

  @override
  JmTierColors copyWith() => this;

  @override
  JmTierColors lerp(JmTierColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return JmTierColors(
      strongBg: c(strongBg, other.strongBg),
      strongFg: c(strongFg, other.strongFg),
      strongDot: c(strongDot, other.strongDot),
      goodBg: c(goodBg, other.goodBg),
      goodFg: c(goodFg, other.goodFg),
      goodDot: c(goodDot, other.goodDot),
      skipBg: c(skipBg, other.skipBg),
      skipFg: c(skipFg, other.skipFg),
      skipDot: c(skipDot, other.skipDot),
      highlight: c(highlight, other.highlight),
      highlightFg: c(highlightFg, other.highlightFg),
    );
  }
}

/// 4px base, 8px rhythm (guide §04).
/// Inside a component 8–16 · between components 16–24 · between sections 48–64.
abstract final class JmSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x12 = 48;
  static const double x16 = 64;

  /// Page gutter: 16 on phones, 24 on tablet, 32 on desktop.
  static double gutter(double width) => width < 600
      ? x4
      : width < 1024
      ? x6
      : x8;
}

/// Radius grows with the size of the object.
abstract final class JmRadius {
  static const double sm = 6; // chips, tags
  static const double md = 10; // buttons, inputs
  static const double lg = 14; // cards, panels
  static const double pill = 999; // tiers, filters

  static final BorderRadius smR = BorderRadius.circular(sm);
  static final BorderRadius mdR = BorderRadius.circular(md);
  static final BorderRadius lgR = BorderRadius.circular(lg);
  static final BorderRadius pillR = BorderRadius.circular(pill);
}

/// Layout widths: 720 for reading, 960 for the results list, 1200 for the shell.
abstract final class JmLayout {
  static const double reading = 720;
  static const double results = 960;
  static const double shell = 1200;
  static const double touchTarget = 44;
}

/// Motion (guide §07). One easing everywhere, no bounces.
abstract final class JmMotion {
  static const Duration state = Duration(milliseconds: 120);
  static const Duration enterExit = Duration(milliseconds: 200);
  static const Duration ringFill = Duration(milliseconds: 400);
  static const Duration stagger = Duration(milliseconds: 40);
  static const Duration pulse = Duration(milliseconds: 1400);
  static const Curve ease = Cubic(.2, .8, .2, 1);
}

extension JmThemeContext on BuildContext {
  JmColors get jm => Theme.of(this).extension<JmColors>()!;
  JmTierColors get tiers => Theme.of(this).extension<JmTierColors>()!;

  /// prefers-reduced-motion. Ambient animation switches to static when true.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}
