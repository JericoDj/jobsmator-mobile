import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Results arrive one card at a time with a 40 ms stagger, from a visible
/// resting state (60 % opacity, 8 px down) — never from opacity 0.
class StaggeredEntry extends StatefulWidget {
  const StaggeredEntry({super.key, required this.index, required this.child, this.enabled = true});
  final int index;
  final Widget child;
  final bool enabled;

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: JmMotion.enterExit);
  late final Animation<double> _t = CurvedAnimation(parent: _ctrl, curve: JmMotion.ease);

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _ctrl.value = 1;
      return;
    }
    Future.delayed(JmMotion.stagger * widget.index.clamp(0, 12), () {
      if (mounted) _ctrl.forward();
    });
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (_, child) => Opacity(
      opacity: .6 + .4 * _t.value,
      child: Transform.translate(offset: Offset(0, 8 * (1 - _t.value)), child: child),
    ),
    child: widget.child,
  );
}
