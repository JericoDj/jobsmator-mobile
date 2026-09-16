import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Eyebrow + title + lede for the three onboarding steps, with the stepper.
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.step, required this.title, this.lede, this.total = 3});
  final int step, total;
  final String title;
  final String? lede;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepBars(step: step, total: total),
        const SizedBox(height: JmSpace.x4),
        JmLabel('Step $step of $total', color: c.oceanDeep),
        const SizedBox(height: JmSpace.x2),
        Text(title, style: context.type.title),
        if (lede != null) ...[
          const SizedBox(height: JmSpace.x2),
          Text(lede!, style: context.type.body.copyWith(color: c.muted)),
        ],
      ],
    );
  }
}

/// Segmented progress: done = Match, now = Cobalt, rest = surface-2.
class StepBars extends StatelessWidget {
  const StepBars({super.key, required this.step, required this.total, this.pulse = false});
  final int step, total;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: JmMotion.state,
              curve: JmMotion.ease,
              height: 5,
              decoration: BoxDecoration(
                color: i < step
                    ? c.match
                    : i == step
                    ? c.ocean
                    : c.surface2,
                borderRadius: BorderRadius.circular(3),
              ),
              child: i == step && pulse ? const _Pulse() : null,
            ),
          ),
        ],
      ],
    );
  }
}

/// The only ambient animation in the app. Static when motion is reduced.
class _Pulse extends StatefulWidget {
  const _Pulse();
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: JmMotion.pulse);

  @override
  void initState() {
    super.initState();
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return const SizedBox.shrink();
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: .55).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)),
      ),
    );
  }
}
