import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// A one-line news ticker: short facts scrolling past continuously on a
/// solid band, looping seamlessly. Light text on whatever the parent
/// paints behind it. Keep each item under ~40 characters.
class JmTicker extends StatelessWidget {
  const JmTicker({super.key, required this.items, this.height = 32, this.color = JmColors.navyText});
  final List<String> items;
  final double height;

  /// Text colour — light by default for a navy band; pass `muted` on a
  /// light one.
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final text = context.type.meta.copyWith(color: color, fontSize: 13);
    return SizedBox(
      height: height,
      child: _Marquee(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items) ...[
              const SizedBox(width: 18),
              Text(item, style: text),
              const SizedBox(width: 18),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: color.withValues(alpha: .5), shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Scrolls [child] leftwards forever. The child is laid out twice back to
/// back and the offset wraps at one child width, so the loop has no seam.
class _Marquee extends StatefulWidget {
  const _Marquee({required this.child});
  final Widget child;

  static const pixelsPerSecond = 32.0;

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  final _key = GlobalKey();
  double _width = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    final w = box?.size.width ?? 0;
    if (w <= 0 || w == _width) return;
    setState(() => _width = w);
    _ctrl
      ..duration = Duration(milliseconds: (w / _Marquee.pixelsPerSecond * 1000).round())
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant _Marquee old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => OverflowBox(
        alignment: Alignment.centerLeft,
        maxWidth: double.infinity,
        child: Transform.translate(
          offset: Offset(-_ctrl.value * _width, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyedSubtree(key: _key, child: widget.child),
              if (_width > 0) widget.child,
            ],
          ),
        ),
      ),
    ),
  );
}
