import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// 64px conic ring that fills over 400 ms on first render.
/// Match green ≥ 80, Cobalt 60–79, muted below.
class ScoreRing extends StatefulWidget {
  const ScoreRing({super.key, required this.score, this.size = 64, this.animate = true});
  final int score;
  final double size;
  final bool animate;

  @override
  State<ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<ScoreRing> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: JmMotion.ringFill);
  late final Animation<double> _t = CurvedAnimation(parent: _ctrl, curve: JmMotion.ease);

  @override
  void initState() {
    super.initState();
    widget.animate ? _ctrl.forward() : _ctrl.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) _ctrl.value = 1;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final color = widget.score >= 80
        ? c.match
        : widget.score >= 60
        ? c.ocean
        : c.faint;
    final tier = widget.score >= 80
        ? 'strong'
        : widget.score >= 60
        ? 'good'
        : 'weaker';
    return Semantics(
      container: true,
      excludeSemantics: true, // the label says it all; "87" + "MATCH" would be noise
      label: 'Match score ${widget.score} of 100, $tier',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _t,
              builder: (_, _) => CustomPaint(
                painter: _RingPainter(
                  fraction: widget.score / 100 * _t.value,
                  color: color,
                  track: c.surface2,
                  inner: c.card,
                ),
                child: Center(
                  child: Text(
                    '${widget.score}',
                    style: context.type.stat.copyWith(fontSize: widget.size * .29, color: c.ink),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          JmLabel('Match', color: c.muted),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction, required this.color, required this.track, required this.inner});
  final double fraction;
  final Color color, track, inner;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = size.width / 2;
    canvas.drawCircle(center, r, Paint()..color = track);
    if (fraction > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction.clamp(0, 1), true, Paint()..color = color);
    }
    canvas.drawCircle(center, r - 6, Paint()..color = inner);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track || old.inner != inner;
}
