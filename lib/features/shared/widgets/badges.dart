import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/models/job.dart';

/// Tier pill: dot + label. Never colour alone — the dot, the label and the
/// score number on the card all agree.
class TierBadge extends StatelessWidget {
  const TierBadge({super.key, required this.tier, this.count});
  final Tier tier;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final t = context.tiers;
    final (bg, fg, dot) = switch (tier) {
      Tier.strong => (t.strongBg, t.strongFg, t.strongDot),
      Tier.good => (t.goodBg, t.goodFg, t.goodDot),
      Tier.skip => (t.skipBg, t.skipFg, t.skipDot),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 3, 10, 3),
      decoration: BoxDecoration(color: bg, borderRadius: JmRadius.pillR),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              border: tier == Tier.good ? Border.all(color: fg, width: 1) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            count == null ? tier.label : '${tier.label} $count',
            style: context.type.meta.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: .2,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Red flag chip: semantic danger tint, radius 6, always visible.
class FlagChip extends StatelessWidget {
  const FlagChip(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 9, 3),
      decoration: BoxDecoration(color: c.dangerTint, borderRadius: JmRadius.smR),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 13, color: c.danger),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: context.type.meta.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.danger,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single line of danger text with an icon, for inline form errors.
class ErrorLine extends StatelessWidget {
  const ErrorLine(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.error_outline_rounded, size: 16, color: c.danger),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(message, style: context.type.meta.copyWith(color: c.danger, fontSize: 14)),
        ),
      ],
    );
  }
}
