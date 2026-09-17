import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Section title with an optional badge ("Sample") and a text action on
/// the right. Used by Home and Jobs.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.badge, this.action, this.onAction});
  final String title;
  final String? badge, action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(title, style: context.type.heading),
      if (badge != null) ...[const SizedBox(width: JmSpace.x2), JmBadge(badge!)],
      const Spacer(),
      if (action != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            foregroundColor: context.jm.oceanDeep,
          ),
          child: Text(action!),
        ),
    ],
  );
}

/// Small muted pill, e.g. "Sample".
class JmBadge extends StatelessWidget {
  const JmBadge(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.surface2, borderRadius: JmRadius.pillR),
      child: Text(
        text.toUpperCase(),
        style: context.type.meta.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .6, color: c.muted),
      ),
    );
  }
}
