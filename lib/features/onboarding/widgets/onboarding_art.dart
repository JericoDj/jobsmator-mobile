import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/models/job.dart';
import '../../results/widgets/score_ring.dart';
import '../../shared/widgets/badges.dart';

/// The one picture on each welcome slide. Built from the same parts as the
/// product (cards, bars, the ring, the tier pill) so the tour previews the
/// app rather than decorating it. Each sits in a soft field with a single
/// brand wash — Cobalt, Sky, then Match, in the order the slides earn them.
class OnboardingArt extends StatelessWidget {
  const OnboardingArt({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final wash = switch (index) {
      0 => c.ocean,
      1 => c.sky,
      _ => c.match,
    };
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.surface),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(.8, -.9),
                  radius: 1.1,
                  colors: [wash.withValues(alpha: .22), Colors.transparent],
                ),
              ),
            ),
            Center(
              child: switch (index) {
                0 => const _ResumeArt(),
                1 => const _SitesArt(),
                _ => const _RankedArt(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A resume card with the mark of a skill picked out, and the upload button.
class _ResumeArt extends StatelessWidget {
  const _ResumeArt();

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return SizedBox(
      width: 200,
      height: 220,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _Card(
            width: 176,
            height: 212,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Bar(width: 84, height: 10, color: c.ink),
                const SizedBox(height: 8),
                _Bar(width: 56, height: 6, color: c.faint.withValues(alpha: .5)),
                const SizedBox(height: 22),
                _Bar(width: 136, height: 6, color: c.surface2),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Bar(width: 48, height: 6, color: c.surface2),
                    const SizedBox(width: 6),
                    _Bar(width: 40, height: 10, color: c.volt, radius: 3),
                    const SizedBox(width: 6),
                    _Bar(width: 30, height: 6, color: c.surface2),
                  ],
                ),
                const SizedBox(height: 10),
                _Bar(width: 120, height: 6, color: c.surface2),
                const SizedBox(height: 10),
                _Bar(width: 136, height: 6, color: c.surface2),
                const SizedBox(height: 10),
                _Bar(width: 96, height: 6, color: c.surface2),
              ],
            ),
          ),
          Positioned(
            right: -6,
            bottom: 6,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: c.ocean, shape: BoxShape.circle, boxShadow: c.shadow),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nine site tiles under one lens.
class _SitesArt extends StatelessWidget {
  const _SitesArt();

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return SizedBox(
      width: 216,
      height: 216,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < 9; i++)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: i == 4 ? c.skyTint : c.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.line),
                  ),
                  child: Center(child: _Bar(width: 22, height: 6, color: i == 4 ? c.sky : c.surface2)),
                ),
            ],
          ),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.card.withValues(alpha: .55),
              border: Border.all(color: c.ocean, width: 5),
              boxShadow: c.shadow,
            ),
          ),
          // Handle: sits on the ring's 4-o'clock point, rotated 45°.
          Positioned(
            right: 54,
            bottom: 38,
            child: Transform.rotate(
              angle: .785,
              child: Container(
                width: 12,
                height: 44,
                decoration: BoxDecoration(color: c.ocean, borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The product's job card: score ring, tier, and a "why" line.
class _RankedArt extends StatelessWidget {
  const _RankedArt();

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return _Card(
      width: 224,
      height: 168,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _Bar(width: 104, height: 10, color: c.ink),
                    const SizedBox(height: 8),
                    _Bar(width: 72, height: 6, color: c.faint.withValues(alpha: .5)),
                    const SizedBox(height: 14),
                    const TierBadge(tier: Tier.strong),
                  ],
                ),
              ),
              const ScoreRing(score: 92, size: 56),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _Bar(width: 34, height: 6, color: c.surface2),
              const SizedBox(width: 6),
              _Bar(width: 44, height: 10, color: c.volt, radius: 3),
              const SizedBox(width: 6),
              _Bar(width: 62, height: 6, color: c.surface2),
            ],
          ),
          const SizedBox(height: 10),
          _Bar(width: 150, height: 6, color: c.surface2),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.width, required this.height, required this.child});
  final double width, height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
        boxShadow: c.shadow,
      ),
      child: child,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, required this.color, this.radius = 999});
  final double width, height, radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
  );
}
