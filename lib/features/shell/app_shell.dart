import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme/theme.dart';
import '../../providers/run_provider.dart';
import 'announcement_bar.dart';

/// The tab shell: Home · Jobs · AI · Tools · Profile. The bar is ground +
/// hairline — no elevation, no tint — and the only decoration is the Volt
/// unread dot on Jobs when a search finishes off-screen (guide §02, Volt).
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const jobsTab = 1;

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
    return Scaffold(
      // The announcement bar owns the top inset, so the tabs must not pad
      // for the notch a second time.
      body: Column(
        children: [
          const AnnouncementBar(),
          Expanded(
            child: MediaQuery.removePadding(context: context, removeTop: true, child: widget.navigationShell),
          ),
        ],
      ),
      bottomNavigationBar: JmBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onSelect: _select,
        items: [
          const JmNavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
          JmNavItem(label: 'Jobs', icon: Icons.work_outline_rounded, activeIcon: Icons.work_rounded, dot: unseen),
          const JmNavItem(label: 'AI', icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy_rounded),
          const JmNavItem(label: 'Tools', icon: Icons.handyman_outlined, activeIcon: Icons.handyman_rounded),
          const JmNavItem(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
        ],
      ),
    );
  }
}

class JmNavItem {
  const JmNavItem({required this.label, required this.icon, required this.activeIcon, this.dot = false});
  final String label;
  final IconData icon, activeIcon;
  final bool dot;
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
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
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
                  child: Icon(active ? item.activeIcon : item.icon, key: ValueKey(active), size: 24, color: color),
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
