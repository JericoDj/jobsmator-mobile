import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// The type scale from guide §03, resolved for one brightness.
///
/// Outfit for headings and numbers, Instrument Sans for reading and UI,
/// JetBrains Mono for the identifiers that matter. Read it with `context.type`.
class JmText extends ThemeExtension<JmText> {
  const JmText({
    required this.display,
    required this.title,
    required this.heading,
    required this.body,
    required this.ui,
    required this.uiStrong,
    required this.meta,
    required this.label,
    required this.code,
    required this.stat,
  });

  /// 32/36 · 700 · results headline, onboarding.
  final TextStyle display;

  /// 24/28 · 600 · section titles, sheet dialogs.
  final TextStyle title;

  /// 18/24 · 600 · job title on a card.
  final TextStyle heading;

  /// 16/26 · 400 · reasons, descriptions.
  final TextStyle body;

  /// 15/20 · 500 / 600 · buttons, chips, inputs, tabs.
  final TextStyle ui, uiStrong;

  /// 13/18 · 400 · site name, location, posted date.
  final TextStyle meta;

  /// 12/16 · +0.08em caps · 600 · stat labels, eyebrows.
  final TextStyle label;

  /// 13/20 · 400 · IDs, JSON, settings.
  final TextStyle code;

  /// Outfit 24 · 700 · tabular · the number in a stat tile or score ring.
  final TextStyle stat;

  /// Fonts come from google_fonts at runtime. Tests (and any build that
  /// bundles the .ttf files itself) turn this off to use the family names.
  static bool useGoogleFonts = true;

  static JmText forPalette(JmColors c) {
    final outfit = useGoogleFonts
        ? GoogleFonts.outfit(color: c.ink)
        : TextStyle(fontFamily: 'Outfit', fontFamilyFallback: const ['SF Pro Rounded', 'Roboto'], color: c.ink);
    final sans = useGoogleFonts
        ? GoogleFonts.instrumentSans(color: c.text)
        : TextStyle(fontFamily: 'Instrument Sans', fontFamilyFallback: const ['SF Pro Text', 'Roboto'], color: c.text);
    final mono = useGoogleFonts
        ? GoogleFonts.jetBrainsMono(color: c.ink)
        : TextStyle(fontFamily: 'JetBrains Mono', fontFamilyFallback: const ['Menlo', 'monospace'], color: c.ink);
    const tabular = [FontFeature.tabularFigures()];
    return JmText(
      display: outfit.copyWith(fontSize: 32, height: 36 / 32, fontWeight: FontWeight.w700, letterSpacing: -0.64),
      title: outfit.copyWith(fontSize: 24, height: 28 / 24, fontWeight: FontWeight.w600, letterSpacing: -0.36),
      heading: outfit.copyWith(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600),
      body: sans.copyWith(fontSize: 16, height: 26 / 16, fontWeight: FontWeight.w400),
      ui: sans.copyWith(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w500, color: c.ink),
      uiStrong: sans.copyWith(fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600, color: c.ink),
      meta: sans.copyWith(fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400, color: c.muted),
      label: sans.copyWith(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.96,
        color: c.muted,
      ),
      code: mono.copyWith(fontSize: 13, height: 20 / 13, fontWeight: FontWeight.w400),
      stat: outfit.copyWith(fontSize: 24, height: 1.1, fontWeight: FontWeight.w700, fontFeatures: tabular),
    );
  }

  @override
  JmText copyWith() => this;

  @override
  JmText lerp(JmText? other, double t) {
    if (other == null) return this;
    TextStyle s(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return JmText(
      display: s(display, other.display),
      title: s(title, other.title),
      heading: s(heading, other.heading),
      body: s(body, other.body),
      ui: s(ui, other.ui),
      uiStrong: s(uiStrong, other.uiStrong),
      meta: s(meta, other.meta),
      label: s(label, other.label),
      code: s(code, other.code),
      stat: s(stat, other.stat),
    );
  }
}

extension JmTextContext on BuildContext {
  JmText get type => Theme.of(this).extension<JmText>()!;
}

/// Uppercases label text — the style carries the tracking, the widget the case.
class JmLabel extends StatelessWidget {
  const JmLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: context.type.label.copyWith(color: color));
}
