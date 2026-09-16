import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Page shell: safe area, responsive gutter, a reading column of 720 and an
/// optional sticky bottom bar for the one primary action.
class JmPage extends StatelessWidget {
  const JmPage({
    super.key,
    required this.child,
    this.appBar,
    this.bottom,
    this.maxWidth = JmLayout.reading,
    this.scrollable = true,
    this.padding,
  });

  /// The padding every tab page uses, so the five tabs line up: gutter on
  /// the sides, x4 under the announcement bar, x6 above the nav bar.
  static EdgeInsets tabPadding(BuildContext context) {
    final gutter = JmSpace.gutter(MediaQuery.sizeOf(context).width);
    return EdgeInsets.fromLTRB(gutter, JmSpace.x4, gutter, JmSpace.x6);
  }

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottom;
  final double maxWidth;
  final bool scrollable;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final gutter = JmSpace.gutter(width);
    final pad = padding ?? EdgeInsets.fromLTRB(gutter, JmSpace.x2, gutter, JmSpace.x6);

    Widget body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: pad, child: child),
      ),
    );
    if (scrollable) body = SingleChildScrollView(child: body);

    return Scaffold(
      appBar: appBar,
      body: SafeArea(bottom: bottom == null, child: body),
      bottomNavigationBar: bottom == null ? null : JmBottomBar(child: bottom!),
    );
  }
}

/// Hairline-topped bar that keeps the primary action reachable by thumb.
class JmBottomBar extends StatelessWidget {
  const JmBottomBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final gutter = JmSpace.gutter(MediaQuery.sizeOf(context).width);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.ground,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, JmSpace.x3, gutter, JmSpace.x3),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: JmLayout.reading),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
