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

    // JmBottomNav is 50px + bottom safe area.
    final bottomNavHeight = 50.0 + mq.padding.bottom;
    // The inner scaffold only needs to shrink by the portion of the keyboard
    // that overlaps the navigation shell.
    final adjustedBottomInset = math.max(0.0, mq.viewInsets.bottom - bottomNavHeight);

    // If the current screen has a JmBottomBar, we float the pill higher so it
    // doesn't cover the primary action button.
    final String loc = GoRouterState.of(context).matchedLocation;
    final bool hasBottomBar = loc == AppRoutes.schedule ||
        loc == AppRoutes.upload ||
        loc == AppRoutes.interests ||
        loc == AppRoutes.sites ||
        loc.startsWith('/tools/') ||
        loc == AppRoutes.jobPreferences ||
        loc == AppRoutes.career;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // The announcement bar owns the top inset and the tab bar owns the
      // home-indicator inset, so the tabs must pad for neither — content
      // runs right down to the bar and the pill simply floats over it.
      body: Column(
        children: [
          const AnnouncementBar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: MediaQuery(
                    data: mq.copyWith(
                      padding: mq.padding.copyWith(top: 0, bottom: 0),
                      viewPadding: mq.viewPadding.copyWith(top: 0, bottom: 0),
                      viewInsets: mq.viewInsets.copyWith(bottom: adjustedBottomInset),
                    ),
                    child: widget.navigationShell,
                  ),
                ),
                if (showPill)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: hasBottomBar ? 96 : JmSpace.x3,
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

  /// An asset to draw instead of [icon] — the assistant uses the product's
  /// own robot rather than a stock glyph. Greyed out when the tab is inactive
  /// so it still sits in the same visual hierarchy as its neighbours.
  final String? image;
}

class JmBottomNav extends StatelessWidget {
  const JmBottomNav({super.key, required this.items, required this.currentIndex, required this.onSelect});
  final List<JmNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.ground,
        border: Border(top: BorderSide(color: c.line)),
      ),
      // The row is just tall enough for icon + label; SafeArea then adds
      // the home-indicator zone underneath, painted in the same ground.
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              for (final (i, item) in items.indexed)
                Expanded(
                  child: _NavButton(item: item, active: i == currentIndex, onTap: () => onSelect(i)),
                ),
            ],
          ),
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
    final color = active ? c.ocean : c.muted;
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
        highlightColor: c.surface,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: JmMotion.state,
                  child: item.image != null
                      ? Image.asset(
                          item.image!,
                          key: ValueKey(active),
                          width: 26,
                          height: 26,
                          // Inactive tabs are muted, so the full-colour mark would
                          // shout; it only gets its blue back when selected.
                          color: active ? null : color,
                        )
                      : Icon(active ? item.activeIcon : item.icon, key: ValueKey(active), size: 24, color: color),
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
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: JmMotion.state,
              style: context.type.meta.copyWith(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: color,
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
