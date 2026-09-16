import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Body text with the matched interests marked in Volt — a literal
/// highlighter. Matching is case-insensitive on whole words.
class HighlightedText extends StatelessWidget {
  const HighlightedText(this.text, {super.key, required this.terms, this.style});
  final String text;
  final List<String> terms;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.type.body;
    final t = context.tiers;
    final mark = base.copyWith(backgroundColor: t.highlight, color: t.highlightFg, fontWeight: FontWeight.w500);

    final words = terms.map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (words.isEmpty) return Text(text, style: base);

    final pattern = RegExp('(?<![\\w])(${words.map(RegExp.escape).join('|')})(?![\\w])', caseSensitive: false);
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(TextSpan(text: text.substring(m.start, m.end), style: mark));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(style: base, children: spans));
  }
}
