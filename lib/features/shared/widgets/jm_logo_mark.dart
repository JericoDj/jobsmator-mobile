import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// The mark: Cobalt tile, Match dot, a Volt sliver on its right edge.
class JmLogoMark extends StatelessWidget {
  const JmLogoMark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final dot = size * .5;
    return Semantics(
      label: 'JobsMator',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: c.ocean, borderRadius: BorderRadius.circular(size * 8 / 28)),
        alignment: Alignment.center,
        child: SizedBox(
          width: dot,
          height: dot,
          child: ClipOval(
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: c.match)),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: dot * 4 / 14,
                  child: ColoredBox(color: c.volt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mark + wordmark, for the sign-in screen and app bars.
class JmWordmark extends StatelessWidget {
  const JmWordmark({super.key, this.size = 28, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      JmLogoMark(size: size),
      SizedBox(width: size * .4),
      Text(
        'JobsMator',
        style: context.type.heading.copyWith(fontSize: size * .75, color: color ?? context.jm.ink, letterSpacing: -.2),
      ),
    ],
  );
}
