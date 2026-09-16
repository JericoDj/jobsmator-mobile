import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/home_controller.dart';
import '../../core/copy.dart';
import '../../core/models/automation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_catalog_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/run_provider.dart';
import '../jobs/widgets/job_row.dart';
import '../shared/widgets/cta_card.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/jm_robot.dart';
import '../shared/widgets/tab_header.dart';

/// The command centre. Numbers first, then the three best jobs, then what
/// the assistant thinks, then what's running and what just happened.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Good morning'
        : h < 18
        ? 'Good afternoon'
        : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<JobCatalogProvider>();
    context.watch<RunProvider>();
    context.watch<PreferencesProvider>();
    final ctrl = context.watch<HomeController>();
    final user = context.watch<AuthProvider>().user;
    final unseen = context.select<RunProvider, bool>((r) => r.unseenResult);
    final c = context.jm;

    return JmPage(
      maxWidth: JmLayout.results,
      padding: JmPage.tabPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabHeader(
            title: '${_greeting()}, ${user?.firstName ?? 'there'} 👋',
            subtitle: ctrl.subtext,
            trailing: _BellButton(unread: unseen, onTap: () => context.push(AppRoutes.history)),
          ),
          const SizedBox(height: JmSpace.x6),

          // Numbers
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'New matches',
                  value: ctrl.newMatches,
                  icon: Icons.track_changes_rounded,
                  color: c.match,
                  onTap: () => context.go(AppRoutes.jobs),
                ),
              ),
              const SizedBox(width: JmSpace.x3),
              Expanded(
                child: _Stat(
                  label: 'Applications',
                  value: ctrl.applications,
                  icon: Icons.send_rounded,
                  color: c.ocean,
                  onTap: () {
                    context.read<JobCatalogProvider>().setFilter(JobFilter.applied);
                    context.go(AppRoutes.jobs);
                  },
                ),
              ),
              const SizedBox(width: JmSpace.x3),
              Expanded(
                child: _Stat(
                  label: 'Automations',
                  value: ctrl.automationsRunning,
                  icon: Icons.bolt_rounded,
                  color: c.sky,
                  onTap: () => context.push(AppRoutes.automation),
                ),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x6),

          // Run it — the one action the whole screen leads to. Just a title
          // and the buttons; the numbers live in the ticker above.
          CtaCard(
            title: ctrl.runInProgress
                ? 'A search is running'
                : !ctrl.canSearch
                ? 'Out of searches ${ctrl.planPeriod}'
                : ctrl.lastRunAt == null
                ? 'Run your first search'
                : 'Run a search now',
            actionLabel: ctrl.runInProgress ? 'See progress' : 'Search',
            actionIcon: ctrl.runInProgress ? Icons.timelapse_rounded : Icons.play_arrow_rounded,
            onAction: () => context.go(
              ctrl.runInProgress ? AppRoutes.run(context.read<RunProvider>().current!.id) : AppRoutes.upload,
            ),
            secondaryLabel: 'Schedules',
            onSecondary: () => context.push(AppRoutes.automation),
          ),
          const SizedBox(height: JmSpace.x8),

          // Recommended
          _SectionHeader(
            title: 'Recommended for you',
            action: 'View all jobs',
            onAction: () => context.go(AppRoutes.jobs),
          ),
          const SizedBox(height: JmSpace.x3),
          if (!ctrl.ready)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: JmSpace.x6),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (ctrl.recommended.isEmpty)
            _QuietCard(
              icon: Icons.upload_file_rounded,
              text: ctrl.hasResume
                  ? 'No strong matches yet. Run a search to fill this in.'
                  : 'Upload a resume and run your first search.',
              action: SecondaryButton(label: 'Find matching jobs', onPressed: () => context.go(AppRoutes.upload)),
            )
          else
            for (final (i, job) in ctrl.recommended.indexed) ...[
              if (i > 0) const SizedBox(height: JmSpace.x2),
              JobRow(job: job, onTap: () => context.push(AppRoutes.job(job.id))),
            ],
          const SizedBox(height: JmSpace.x8),

          // AI suggestion — the robot says one line; tap to talk to it.
          Material(
            color: c.skyTint,
            borderRadius: JmRadius.lgR,
            child: InkWell(
              onTap: () => context.go(AppRoutes.ai),
              borderRadius: JmRadius.lgR,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(JmSpace.x3, JmSpace.x3, JmSpace.x3, JmSpace.x3),
                child: Row(
                  children: [
                    const JmRobot(size: 40, tinted: false),
                    const SizedBox(width: JmSpace.x3),
                    Expanded(
                      child: Text(ctrl.suggestion, style: context.type.body.copyWith(color: c.ink, fontSize: 15)),
                    ),
                    const SizedBox(width: JmSpace.x2),
                    Icon(Icons.chat_bubble_outline_rounded, size: 20, color: c.skyDeep),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: JmSpace.x8),

          // Quick actions
          JmLabel('Quick actions', color: c.muted),
          const SizedBox(height: JmSpace.x3),
          Wrap(
            spacing: JmSpace.x2,
            runSpacing: JmSpace.x2,
            children: [
              _Quick(
                icon: Icons.search_rounded,
                label: 'Find matching jobs',
                onTap: () => context.go(AppRoutes.upload),
              ),
              _Quick(
                icon: Icons.description_outlined,
                label: 'Analyze my resume',
                onTap: () => context.push(AppRoutes.tool('resume-analyzer')),
              ),
              _Quick(
                icon: Icons.mail_outline_rounded,
                label: 'Write an application',
                onTap: () => context.push(AppRoutes.tool('application-email')),
              ),
              _Quick(
                icon: Icons.record_voice_over_outlined,
                label: 'Interview prep',
                onTap: () => context.push(AppRoutes.tool('interview-prep')),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x8),

          // Automations
          _SectionHeader(title: 'Automations', action: 'Manage', onAction: () => context.push(AppRoutes.automation)),
          const SizedBox(height: JmSpace.x3),
          if (ctrl.automations.isEmpty)
            _QuietCard(
              icon: Icons.bolt_rounded,
              text: 'No automations yet. Schedule a search and JobsMator keeps looking while you sleep.',
            )
          else
            for (final (i, a) in ctrl.automations.indexed) ...[
              if (i > 0) const SizedBox(height: JmSpace.x2),
              _AutomationRow(automation: a),
            ],
          const SizedBox(height: JmSpace.x8),

          // Recent activity
          _SectionHeader(title: 'Recent activity', action: 'History', onAction: () => context.push(AppRoutes.history)),
          const SizedBox(height: JmSpace.x3),
          if (ctrl.recent.isEmpty)
            _QuietCard(
              icon: Icons.history_rounded,
              text: 'Nothing yet — your searches and applications will show up here.',
            )
          else
            Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: JmRadius.lgR,
                border: Border.all(color: c.line),
              ),
              child: Column(
                children: [
                  for (final (i, item) in ctrl.recent.indexed) ...[
                    if (i > 0) const Divider(),
                    _ActivityRow(item: item),
                  ],
                ],
              ),
            ),
          const SizedBox(height: JmSpace.x6),
        ],
      ),
    );
  }
}

/// Bell in the top-right corner. A Volt dot means a search finished while
/// you were elsewhere — same signal the Jobs tab shows.
class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onTap});
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: onTap,
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
              decoration: BoxDecoration(color: c.volt, shape: BoxShape.circle, border: Border.all(color: c.card, width: 2)),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon, required this.color, required this.onTap});
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: JmRadius.mdR,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: JmRadius.mdR,
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 8),
              Text('$value', style: context.type.stat),
              const SizedBox(height: 2),
              Text(
                label,
                style: context.type.meta.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: context.type.heading)),
      if (action != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            foregroundColor: context.jm.oceanDeep,
          ),
          child: Text(action!),
        ),
    ],
  );
}

class _QuietCard extends StatelessWidget {
  const _QuietCard({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Container(
      padding: const EdgeInsets.all(JmSpace.x4),
      decoration: BoxDecoration(color: c.surface, borderRadius: JmRadius.lgR),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: c.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text, style: context.type.body.copyWith(fontSize: 15, color: c.text)),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: JmSpace.x3), action!],
        ],
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: JmRadius.mdR,
        child: Container(
          constraints: const BoxConstraints(minHeight: JmLayout.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: JmRadius.mdR,
            border: Border.all(color: c.lineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: c.oceanDeep),
              const SizedBox(width: 8),
              Text(label, style: context.type.uiStrong.copyWith(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutomationRow extends StatelessWidget {
  const _AutomationRow({required this.automation});
  final Automation automation;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final a = automation;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: JmRadius.mdR,
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: a.enabled ? c.match : c.faint, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: context.type.uiStrong),
                Text(
                  a.enabled
                      ? '${a.schedule}${a.nextRunAt == null ? '' : ' · next ${JmCopy.relativeFuture(a.nextRunAt!)}'}'
                      : 'Paused · ${a.schedule}',
                  style: context.type.meta,
                ),
              ],
            ),
          ),
          if (a.lastResultCount != null)
            Text(
              '+${a.lastResultCount}',
              style: context.type.stat.copyWith(fontSize: 16, color: a.enabled ? c.ink : c.muted),
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final Activity item;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final (icon, color) = switch (item.kind) {
      ActivityKind.run => (Icons.search_rounded, c.match),
      ActivityKind.failed => (Icons.error_outline_rounded, c.danger),
      ActivityKind.applied => (Icons.send_rounded, c.ocean),
      ActivityKind.automation => (Icons.bolt_rounded, c.sky),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: context.type.uiStrong.copyWith(fontSize: 14)),
                Text(item.detail, style: context.type.meta, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(JmCopy.relative(item.at), style: context.type.meta.copyWith(color: c.faint, fontSize: 12)),
        ],
      ),
    );
  }
}
