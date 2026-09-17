import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/copy.dart';
import '../../providers/ai_provider.dart';
import '../../providers/subscription_provider.dart';
import '../shared/widgets/edge_fade.dart';
import 'ai_tools.dart';

/// Slides the AI side sheet in from the left. Pushed on the root navigator
/// so it covers the tab bar, not just the AI tab's body. Tap the dim area
/// or drag the sheet left to close.
Future<void> showAiSideSheet(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(_SideSheetRoute());

class _SideSheetRoute extends PopupRoute<void> {
  @override
  Color get barrierColor => JmColors.navy.withValues(alpha: .45);
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => 'Close';
  @override
  Duration get transitionDuration => const Duration(milliseconds: 260);

  /// Scrub the slide by a fraction of the sheet width (negative = closing).
  void drag(double fraction) {
    final a = controller;
    if (a == null) return;
    a.value = (a.value + fraction).clamp(0.0, 1.0);
  }

  /// Finish a drag: fling shut or snap back open.
  void settle(double velocity) {
    final a = controller;
    if (a == null) return;
    final close = velocity < -300 || (velocity.abs() < 300 && a.value < .5);
    if (close) {
      navigator?.pop();
    } else {
      a.fling(velocity: 1);
    }
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => const _SideSheet();

  // No curve on the slide: the drag gesture drives this same animation
  // value directly, and a curve would make the sheet lag the finger.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> _,
    Widget child,
  ) => SlideTransition(
    position: Tween(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  );
}

/// Brand header, a compact tool grid, then the list of conversations, with
/// the plan card floating at the bottom. Everything in between scrolls and
/// fades out as it slides under either edge. Drag the sheet left to close.
class _SideSheet extends StatefulWidget {
  const _SideSheet();

  @override
  State<_SideSheet> createState() => _SideSheetState();
}

class _SideSheetState extends State<_SideSheet> {
  static const _headerHeight = 96.0;

  /// Room reserved at the bottom for the floating plan card.
  static const _footerHeight = 136.0;

  double _width = 320;

  /// Dragging scrubs the route's own slide animation, so the sheet tracks
  /// the finger; on release it snaps shut or back open.
  _SideSheetRoute? get _route => ModalRoute.of(context) as _SideSheetRoute?;

  void _onDrag(DragUpdateDetails d) => _route?.drag(d.primaryDelta! / _width);

  void _onDragEnd(DragEndDetails d) => _route?.settle(d.primaryVelocity ?? 0);

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    _width = (MediaQuery.sizeOf(context).width * .84).clamp(280.0, 360.0);
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onHorizontalDragUpdate: _onDrag,
        onHorizontalDragEnd: _onDragEnd,
        child: Material(
          color: c.card,
          surfaceTintColor: Colors.transparent,
          elevation: 16,
          shadowColor: JmColors.navy.withValues(alpha: .35),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
              right: Radius.circular(JmRadius.lg),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: _width,
            height: double.infinity,
            child: SafeArea(
              child: Stack(
                children: [
                  // Scrolling body: tools, then conversations. Fades under
                  // the header at the top and the floating plan card below.
                  Positioned.fill(
                    child: EdgeFade(
                      top: _headerHeight,
                      bottom: _footerHeight,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          JmSpace.x4,
                          _headerHeight,
                          JmSpace.x4,
                          _footerHeight + JmSpace.x4,
                        ),
                        children: const [
                          _Section('Tools'),
                          SizedBox(height: JmSpace.x3),
                          _ToolGrid(),
                          SizedBox(height: JmSpace.x6),
                          _Section('Conversations'),
                          SizedBox(height: JmSpace.x2),
                          _Conversations(),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(top: 0, left: 0, right: 0, child: _Header()),
                  const Positioned(
                    left: JmSpace.x4,
                    right: JmSpace.x4,
                    bottom: JmSpace.x4,
                    child: _PlanCard(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Padding(
      padding: const EdgeInsets.fromLTRB(JmSpace.x4, JmSpace.x4, JmSpace.x2, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JobsMator',
                  style: context.type.title.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 2),
                Text(
                  'Search less. Apply more.',
                  style: context.type.body.copyWith(
                    color: c.muted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
            style: IconButton.styleFrom(foregroundColor: c.muted),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => JmLabel(text, color: context.jm.muted);
}

/// Plan name, searches left, and an Upgrade link for free users.
class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final subs = context.watch<SubscriptionProvider>();
    final left = subs.searchesLeft;
    final limit = subs.plan.searchLimit;
    return Container(
      padding: const EdgeInsets.all(JmSpace.x4),
      decoration: BoxDecoration(
        color: subs.isPro ? c.oceanTint : c.surface,
        borderRadius: JmRadius.lgR,
        border: Border.all(
          color: subs.isPro ? c.ocean.withValues(alpha: .25) : c.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                subs.isPro
                    ? Icons.workspace_premium_rounded
                    : Icons.person_outline_rounded,
                size: 18,
                color: subs.isPro ? c.oceanDeep : c.muted,
              ),
              const SizedBox(width: JmSpace.x2),
              Text('${subs.plan.label} plan', style: context.type.uiStrong),
              const Spacer(),
              if (!subs.isPro)
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.subscribe);
                  },
                  child: Text(
                    'Upgrade',
                    style: context.type.uiStrong.copyWith(
                      color: c.oceanDeep,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: JmSpace.x3),
          // Credits: a thin bar and the count.
          ClipRRect(
            borderRadius: JmRadius.pillR,
            child: LinearProgressIndicator(
              value: limit == 0 ? 0 : left / limit,
              minHeight: 6,
              color: left == 0 ? c.danger : c.ocean,
              backgroundColor: c.line,
            ),
          ),
          const SizedBox(height: JmSpace.x2),
          Text(
            '${JmCopy.plural(left, 'search', 'searches')} left ${subs.plan.periodLabel} · $limit per ${subs.plan.period}',
            style: context.type.meta,
          ),
        ],
      ),
    );
  }
}

/// Three columns of small tinted tiles with a one-word label.
class _ToolGrid extends StatelessWidget {
  const _ToolGrid();

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return LayoutBuilder(
      builder: (context, box) {
        const gap = JmSpace.x2;
        final w = (box.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in aiTools)
              SizedBox(
                width: w,
                child: Builder(
                  builder: (context) {
                    final (tint, deep) = aiHueColors(c, t.hue);
                    return Semantics(
                      button: true,
                      label: t.title,
                      child: Material(
                        color: c.surface,
                        borderRadius: JmRadius.mdR,
                        child: InkWell(
                          borderRadius: JmRadius.mdR,
                          onTap: () {
                            Navigator.of(context).pop();
                            openAiTool(context, t);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: JmSpace.x3,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: tint,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(t.icon, size: 18, color: deep),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  t.short,
                                  style: context.type.meta.copyWith(
                                    color: c.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Saved threads, newest first, with the active one highlighted. Long
/// press to delete.
class _Conversations extends StatelessWidget {
  const _Conversations();

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final ai = context.watch<AiProvider>();
    final threads = ai.threads;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: JmSpace.x2),
          dense: true,
          leading: Icon(
            Icons.add_comment_outlined,
            size: 20,
            color: c.oceanDeep,
          ),
          title: Text(
            'New conversation',
            style: context.type.uiStrong.copyWith(
              color: c.oceanDeep,
              fontSize: 14,
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: JmRadius.mdR),
          onTap: () {
            ai.newThread();
            Navigator.of(context).pop();
          },
        ),
        if (threads.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              JmSpace.x2,
              JmSpace.x2,
              JmSpace.x2,
              0,
            ),
            child: Text(
              'Nothing yet — ask the assistant something.',
              style: context.type.meta,
            ),
          ),
        for (final t in threads)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: JmSpace.x2),
            dense: true,
            selected: t.id == ai.active.id,
            selectedTileColor: c.surface,
            leading: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 18,
              color: c.muted,
            ),
            title: Text(
              t.title,
              style: context.type.ui.copyWith(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              JmCopy.relative(t.updatedAt),
              style: context.type.meta.copyWith(fontSize: 12),
            ),
            shape: RoundedRectangleBorder(borderRadius: JmRadius.mdR),
            onTap: () {
              ai.open(t.id);
              Navigator.of(context).pop();
            },
            onLongPress: () => _confirmDelete(context, ai, t),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AiProvider ai,
    AiThread t,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text(t.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.jm.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true) ai.delete(t.id);
  }
}
