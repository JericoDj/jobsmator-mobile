import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../providers/run_provider.dart';
import '../../providers/subscription_provider.dart';
import 'announcement_bar.dart';

import 'dart:math' as math;

/// The tab shell: Home · Jobs · AI · Tools · Profile. The bar is ground +
/// hairline — no elevation, no tint — and the only decoration is the Volt
/// unread dot on Jobs when a search finishes off-screen (guide §02, Volt).
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const jobsTab = 1;
  static const aiTab = 2;


  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int? _reportedIndex;

  /// Tell RunProvider which tab is on screen. Called from build because the
  /// shell widget's currentIndex reads shared route state, so old and new
  /// widgets always agree in didUpdateWidget.
  void _reportVisibility() {
    final index = widget.navigationShell.currentIndex;
    if (index == _reportedIndex) return;
    _reportedIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RunProvider>().searchTabVisible = index == AppShell.jobsTab;
    });
  }

  void _select(int index) {
    widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    _reportVisibility();
    final unseen = context.select<RunProvider, bool>((r) => r.unseenResult);
    final isPro = context.select<SubscriptionProvider, bool>((s) => s.isPro);
    final index = widget.navigationShell.currentIndex;
    // every tab except AI, whose composer already owns that edge.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showPill = !isPro && index != AppShell.aiTab && !keyboardOpen;
    final mq = MediaQuery.of(context);

    // The floating bar's own height plus the margin it sits on.
    final bottomNavHeight = JmBottomNav.totalHeight + mq.padding.bottom;
    // The inner scaffold only needs to shrink by the portion of the keyboard
    // that overlaps the navigation shell.
    final adjustedBottomInset = math.max(0.0, mq.viewInsets.bottom - bottomNavHeight);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // The bar is a floating panel with the page visible around and behind it,
      // which is the whole point of frosting it.
      extendBody: true,
      // The announcement bar owns the top inset. The tab bar floats over the
      // content now, so the tabs are handed its height as their bottom inset —
      // a list can scroll under the glass, but it must still be able to end
      // above it.
      body: Column(
        children: [
          const AnnouncementBar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: MediaQuery(
                    data: mq.copyWith(
                      padding: mq.padding.copyWith(top: 0, bottom: bottomNavHeight),
                      viewPadding: mq.viewPadding.copyWith(top: 0, bottom: bottomNavHeight),
                      viewInsets: mq.viewInsets.copyWith(bottom: adjustedBottomInset),
                    ),
                    child: widget.navigationShell,
                  ),
                ),
                if (showPill)
                  // Sits at the top: the floating bar now owns the bottom edge,
                  // and a nudge that covers the primary action is worse than one
                  // that waits above the fold.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: JmSpace.x3,
                    child: Center(child: _UpgradePill(onTap: () => context.push(AppRoutes.subscribe))),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: JmBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onSelect: _select,
        items: [
          const JmNavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
          JmNavItem(label: 'Jobs', icon: Icons.work_outline_rounded, activeIcon: Icons.work_rounded, dot: unseen),
          const JmNavItem(label: 'AI', icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy_rounded, image: 'assets/logo/robot.png'),
          const JmNavItem(label: 'Tools', icon: Icons.handyman_outlined, activeIcon: Icons.handyman_rounded),
          const JmNavItem(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
        ],
      ),
    );
  }
}

/// Cobalt pill that floats over the tab content: the one upgrade nudge free
/// users see everywhere.
class _UpgradePill extends StatelessWidget {
  const _UpgradePill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Semantics(
      button: true,
      label: 'Get full access',
      child: Material(
        color: c.ocean,
        shape: const StadiumBorder(),
        elevation: 6,
        shadowColor: c.ocean.withValues(alpha: .4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 20, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text('Get full access', style: context.type.uiStrong.copyWith(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JmNavItem {
  const JmNavItem({required this.label, required this.icon, required this.activeIcon, this.dot = false, this.image});
  final String label;
  final IconData icon, activeIcon;
  final bool dot;

  /// An asset drawn instead of [icon] — the assistant shows the product's own
  /// robot. It keeps its colour in both states and sits on a white disc, so it
  /// reads the same on the ground and on the selected pill.
  final String? image;
}

class JmBottomNav extends StatelessWidget {
  const JmBottomNav({super.key, required this.items, required this.currentIndex, required this.onSelect});
  final List<JmNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// The travelling pill: wide enough to hold an icon with air around it,
  /// short enough to leave the label outside it.
  static const _pillWidth = 60.0;
  static const _pillHeight = 32.0;
  static const _barHeight = 58.0;

  /// Side and bottom margin — the bar floats, so the page shows around it.
  static const _inset = 14.0;

  /// What the shell must leave free at the bottom of a scroll view.
  static const totalHeight = _barHeight + _inset;

  /// The assistant's disc, and how far it stands proud of the bar.
  static const _discSize = 54.0;
  static const _discLift = 18.0;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final aiIndex = items.indexWhere((i) => i.image != null);

    return Padding(
      padding: EdgeInsets.fromLTRB(_inset, 0, _inset, _inset + MediaQuery.paddingOf(context).bottom),
      child: LayoutBuilder(
        builder: (context, box) {
          final slot = box.maxWidth / items.length;
          return Stack(
            // The assistant's disc rises out of the bar, so nothing may clip it.
            clipBehavior: Clip.none,
            children: [
              // Frosted panel. Saturation is what keeps the page's colour
              // underneath from going grey behind the blur.
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    height: _barHeight,
                    decoration: BoxDecoration(
                      color: c.ground.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: c.line),
                      boxShadow: [
                        BoxShadow(
                          color: JmColors.navy.withValues(alpha: .22),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // One pill that slides between tabs, rather than a highlight
                        // appearing and disappearing in place: the movement is what
                        // says "you are here now, you were there before".
                        AnimatedPositioned(
                          duration: JmMotion.enterExit,
                          curve: Curves.easeOutCubic,
                          left: slot * currentIndex + (slot - _pillWidth) / 2,
                          top: 5,
                          child: AnimatedOpacity(
                            duration: JmMotion.state,
                            // The assistant already has its own round indicator, so
                            // the pill fades out rather than stacking behind it.
                            opacity: currentIndex == aiIndex ? 0 : 1,
                            child: Container(
                              width: _pillWidth,
                              height: _pillHeight,
                              decoration: BoxDecoration(color: c.oceanTint, borderRadius: JmRadius.pillR),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (final (i, item) in items.indexed)
                              Expanded(
                                child: _NavButton(item: item, active: i == currentIndex, onTap: () => onSelect(i)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // The assistant sits above the bar rather than in it: it is the one
              // destination people open without being sent there.
              if (aiIndex >= 0)
                Positioned(
                  left: slot * aiIndex + (slot - _discSize) / 2,
                  top: -_discLift,
                  child: _AssistantDisc(
                    item: items[aiIndex],
                    active: currentIndex == aiIndex,
                    onTap: () => onSelect(aiIndex),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// The raised robot. White disc, cobalt ring when selected, real shadow — it
/// has to read as a button sitting on top of the bar, not a sticker on it.
class _AssistantDisc extends StatelessWidget {
  const _AssistantDisc({required this.item, required this.active, required this.onTap});
  final JmNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: JmMotion.state,
          curve: JmMotion.ease,
          width: JmBottomNav._discSize,
          height: JmBottomNav._discSize,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: c.ground,
            shape: BoxShape.circle,
            border: Border.all(color: active ? c.oceanTint : c.line, width: active ? 3 : 1),
            boxShadow: [
              BoxShadow(
                color: active ? c.ocean.withValues(alpha: .18) : JmColors.navy.withValues(alpha: .14),
                blurRadius: active ? 14 : 10,
                spreadRadius: active ? 1 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(item.image!, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.active, required this.onTap});
  final JmNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    // Darker blue on the light pill, so the glyph stays the loudest thing in it.
    final iconColor = active ? c.oceanDeep : c.muted;
    return Semantics(
      button: true,
      selected: active,
      label: item.label + (item.dot ? ', new results' : ''),
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        highlightShape: BoxShape.rectangle,
        containedInkWell: true,
        splashColor: c.oceanTint,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: JmBottomNav._pillHeight + 5,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // The assistant's glyph is drawn by the raised disc above the
                    // bar; this slot only keeps the space, label and tap target.
                    if (item.image != null)
                      const SizedBox.shrink()
                    else
                      AnimatedSwitcher(
                        duration: JmMotion.state,
                        child: Icon(active ? item.activeIcon : item.icon, key: ValueKey(active), size: 23, color: iconColor),
                      ),
                    if (item.dot)
                      Positioned(
                        top: -2,
                        right: -4,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: c.volt,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.ground, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: JmMotion.state,
              style: context.type.meta.copyWith(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? c.oceanDeep : c.muted,
                height: 1.2,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
