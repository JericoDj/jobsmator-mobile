import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../app/theme/theme.dart';
import '../../../core/activity.dart';
import '../../../providers/job_catalog_provider.dart';
import '../../../providers/preferences_provider.dart';
import '../../../providers/run_provider.dart';
import 'activity_row.dart';

/// Bell for a tab header's trailing slot. A Volt dot means a search
/// finished while you were elsewhere. Tapping drops a small panel of the
/// latest activity under the bell, with "View all" going to History.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  void _open(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    context.read<RunProvider>().markResultsSeen();
    Navigator.of(context, rootNavigator: true).push(_DropdownRoute(anchor: anchor));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final unread = context.select<RunProvider, bool>((r) => r.unseenResult);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => _open(context),
          icon: const Icon(Icons.notifications_none_rounded),
          color: c.ink,
          style: IconButton.styleFrom(
            backgroundColor: c.card,
            side: BorderSide(color: c.line),
            fixedSize: const Size(44, 44),
          ),
        ),
        if (unread)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: c.volt,
                shape: BoxShape.circle,
                border: Border.all(color: c.card, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// A transparent-barrier route that places the panel just under the bell,
/// right-aligned to it, and scales it in from the top-right corner.
class _DropdownRoute extends PopupRoute<void> {
  _DropdownRoute({required this.anchor});
  final Rect anchor;

  @override
  Color? get barrierColor => Colors.transparent;
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => 'Close';
  @override
  Duration get transitionDuration => JmMotion.enterExit;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final screen = MediaQuery.sizeOf(context);
    final gutter = JmSpace.gutter(screen.width);
    final width = (screen.width - gutter * 2).clamp(280.0, 360.0);
    return Stack(
      children: [
        Positioned(
          top: anchor.bottom + JmSpace.x2,
          right: (screen.width - anchor.right).clamp(gutter, screen.width - width),
          width: width,
          child: const _Panel(),
        ),
      ],
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> _, Widget child) {
    final curved = CurvedAnimation(parent: animation, curve: JmMotion.ease);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: .94, end: 1.0).animate(curved),
        alignment: Alignment.topRight,
        child: child,
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel();

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final items = recentActivity(
      runs: context.watch<RunProvider>().history,
      automations: context.watch<PreferencesProvider>().automations,
      jobs: context.watch<JobCatalogProvider>().all,
    );
    return Material(
      color: c.card,
      surfaceTintColor: Colors.transparent,
      borderRadius: JmRadius.lgR,
      elevation: 12,
      shadowColor: JmColors.navy.withValues(alpha: .25),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Text('Notifications', style: context.type.uiStrong),
          ),
          Divider(height: 1, color: c.line),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: Text('Nothing yet — searches and applications will show up here.', style: context.type.meta),
            )
          else
            for (final (i, item) in items.indexed) ...[
              if (i > 0) Divider(height: 1, color: c.line),
              ActivityRow(item: item, dense: true),
            ],
          Divider(height: 1, color: c.line),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.history);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'View all',
                textAlign: TextAlign.center,
                style: context.type.uiStrong.copyWith(color: c.oceanDeep, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
