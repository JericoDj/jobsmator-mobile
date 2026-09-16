import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// The assistant's face: a friendly robot head drawn in code so it scales
/// crisply and picks up the theme. Used wherever "AI" needs a face rather
/// than a sparkle.
class JmRobot extends StatelessWidget {
  const JmRobot({super.key, this.size = 44, this.tinted = true});

  final double size;

  /// Draws the sky-tint disc behind the head. Off when the parent already
  /// provides a background.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final head = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RobotPainter(body: c.skyDeep, face: c.ocean, eye: Colors.white)),
    );
    if (!tinted) return head;
    return Container(
      width: size * 1.35,
      height: size * 1.35,
      decoration: BoxDecoration(color: c.skyTint, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: head,
    );
  }
}

class _RobotPainter extends CustomPainter {
  _RobotPainter({required this.body, required this.face, required this.eye});
  final Color body, face, eye;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final p = Paint()..style = PaintingStyle.fill;

    // Antenna
    canvas.drawRect(Rect.fromLTWH(w * .47, h * .06, w * .06, h * .14), p..color = body);
    canvas.drawCircle(Offset(w * .5, h * .07), w * .07, p..color = face);

    // Ears
    final ear = RRect.fromRectAndRadius(Rect.fromLTWH(0, h * .42, w * .1, h * .24), Radius.circular(w * .04));
    canvas.drawRRect(ear, p..color = body);
    canvas.drawRRect(ear.shift(Offset(w * .9, 0)), p);

    // Head
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * .1, h * .2, w * .8, h * .7), Radius.circular(w * .22)),
      p..color = body,
    );

    // Visor
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * .2, h * .36, w * .6, h * .3), Radius.circular(w * .12)),
      p..color = face,
    );

    // Eyes
    canvas.drawCircle(Offset(w * .37, h * .51), w * .065, p..color = eye);
    canvas.drawCircle(Offset(w * .63, h * .51), w * .065, p);

    // Smile
    final smile = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .05
      ..strokeCap = StrokeCap.round
      ..color = eye;
    canvas.drawArc(Rect.fromLTWH(w * .38, h * .68, w * .24, h * .12), 0.15, 2.85, false, smile);
  }

  @override
  bool shouldRepaint(covariant _RobotPainter old) => old.body != body || old.face != face || old.eye != eye;
}
