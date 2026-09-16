import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import 'jm_buttons.dart';

/// One line of fact, one line of context, one primary action. The navy
/// variant is the guide's hero band; the surface variant is quieter.
class CtaCard extends StatelessWidget {
  const CtaCard({
    super.key,
    this.eyebrow,
    required this.title,
    this.body,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon,
    this.secondaryLabel,
    this.onSecondary,
    this.navy = true,
    this.facts = const [],
  });

  final String title, actionLabel;
  final String? eyebrow, body;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool navy;

  /// Small icon + text pairs shown under the body ("Last run 6h ago").
  final List<(IconData, String)> facts;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final fg = navy ? Colors.white : c.ink;
    final sub = navy ? JmColors.navyText : c.muted;
    return ClipRRect(
      borderRadius: JmRadius.lgR,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: navy ? JmColors.navy : c.surface)),
          if (navy) ...[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.2, -1.2),
                    radius: 1.1,
                    colors: [const Color(0xFF1E5EFF).withValues(alpha: .45), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.1, 1.4),
                    radius: 0.9,
                    colors: [const Color(0xFF16C172).withValues(alpha: .22), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(JmSpace.x4 + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  JmLabel(eyebrow!, color: navy ? const Color(0xFFFFE600) : c.oceanDeep),
                  const SizedBox(height: JmSpace.x2),
                ],
                Text(title, style: context.type.title.copyWith(color: fg, fontSize: 22)),
                if (body != null) ...[
                  const SizedBox(height: 6),
                  Text(body!, style: context.type.body.copyWith(color: sub, fontSize: 15, height: 1.45)),
                ],
                if (facts.isNotEmpty) ...[
                  const SizedBox(height: JmSpace.x3),
                  Wrap(
                    spacing: JmSpace.x4,
                    runSpacing: 6,
                    children: [
                      for (final (icon, text) in facts)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: sub),
                            const SizedBox(width: 5),
                            Text(text, style: context.type.meta.copyWith(color: sub, fontSize: 12.5)),
                          ],
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: JmSpace.x4),
                Wrap(
                  spacing: JmSpace.x2,
                  runSpacing: JmSpace.x2,
                  children: [
                    PrimaryButton(label: actionLabel, icon: actionIcon, onPressed: onAction),
                    if (secondaryLabel != null)
                      navy
                          ? OutlinedButton(
                              onPressed: onSecondary,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withValues(alpha: .35)),
                              ),
                              child: Text(secondaryLabel!),
                            )
                          : SecondaryButton(label: secondaryLabel!, onPressed: onSecondary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
