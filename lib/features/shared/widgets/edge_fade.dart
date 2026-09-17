import 'package:flutter/material.dart';

/// Fades [child] to transparent over the top [top] px and bottom [bottom]
/// px. It masks alpha rather than painting a scrim, so whatever is behind
/// shows through cleanly. The ramp is eased (slow start, faster finish) so
/// the eye never finds the line where the fade begins.
class EdgeFade extends StatelessWidget {
  const EdgeFade({
    super.key,
    this.top = 0,
    this.bottom = 0,
    required this.child,
  });
  final double top, bottom;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final h = box.maxHeight;
      if (h <= 0 || (top == 0 && bottom == 0)) return child;
      final t = top / h, bt = bottom / h;
      return ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0x00FFFFFF),
            Color(0x59FFFFFF),
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x59FFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0, t * .45, t, 1 - bt, 1 - bt * .45, 1],
        ).createShader(rect),
        child: child,
      );
    },
  );
}
