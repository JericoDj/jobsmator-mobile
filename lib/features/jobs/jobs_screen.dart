import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/copy.dart';
import '../../providers/job_catalog_provider.dart';
import '../../providers/run_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../core/models/job.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/jm_toast.dart';
import '../shared/widgets/notification_bell.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/tab_header.dart';
import '../home/job_list_screen.dart';
import 'widgets/job_row.dart';

/// The job database. Numbers first (three ring buttons that open the
/// matching slice of the list), then the job board. "My jobs" opens the
/// full list; new searches start from here.
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  Future<void> _openListing(Job job) async {
    final ok = await launchUrl(Uri.parse(job.url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) showJmToast(context, title: "Couldn't open ${job.site}", tone: ToastTone.error);
  }

  @override
  void initState() {
    super.initState();
    final catalog = context.read<JobCatalogProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!catalog.loaded) catalog.load().catchError((_) {});
      final runs = context.read<RunProvider>();
      if (!runs.historyLoaded) runs.loadHistory().catchError((_) {});
      final subs = context.read<SubscriptionProvider>();
      if (!subs.loaded) subs.load().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<JobCatalogProvider>();
    final runs = context.watch<RunProvider>();
    final subs = context.watch<SubscriptionProvider>();
    final lastRun = runs.history.where((r) => !r.isActive).firstOrNull;
    final running = runs.current?.isActive ?? false;

    return JmPage(
      maxWidth: JmLayout.results,
      padding: JmPage.tabPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabHeader(
            title: 'Jobs',
            subtitle: running
                ? 'Searching ten sites now…'
                : lastRun == null
                ? 'Every match, ranked with a reason.'
                : 'Last search ${JmCopy.relative(lastRun.finishedAt ?? lastRun.startedAt)}',
            trailing: const NotificationBell(),
          ),
          const SizedBox(height: JmSpace.x4),
          _NumbersCard(
            total: catalog.all.where((j) => !j.hidden).length,
            newMatches: catalog.newMatches,
            applied: catalog.applied,
            notApplied: catalog.all.where((j) => !j.hidden && !j.applied).length,
            creditsLine: '${JmCopy.plural(subs.searchesLeft, 'search', 'searches')} left ${subs.plan.periodLabel}',
            running: running,
            onNew: () => context.push(AppRoutes.jobList(JobListKind.matches.name)),
            onApplied: () => context.push(AppRoutes.jobList(JobListKind.applied.name)),
            onNotApplied: () => context.push(AppRoutes.jobList(JobListKind.notApplied.name)),
            onViewAll: () => context.push(AppRoutes.jobList(JobListKind.all.name)),
            onAutomation: () => context.push(AppRoutes.automation),
          ),
          const SizedBox(height: JmSpace.x2),

          // Job board — a random slice of everything in the database.
          SectionHeader(
            title: 'On the job board',
            badge: catalog.boardIsSample ? 'Sample' : null,
            action: 'Shuffle',
            onAction: catalog.feedLoading ? null : catalog.refreshBoard,
          ),
          const SizedBox(height: JmSpace.x2),

          AnimatedOpacity(
            opacity: catalog.feedLoading ? .5 : 1,
            duration: JmMotion.enterExit,
            child: Column(
              children: [
                for (final (i, job) in catalog.board.take(5).indexed) ...[
                  if (i > 0) const SizedBox(height: JmSpace.x2),
                  JobRow(job: job, dense: true, onTap: () => _openListing(job)),


                ],
                const SizedBox(height: JmSpace.x8),
                const SizedBox(height: JmSpace.x3),
              ],
            ),
          ),




        ],
      ),
    );
  }
}

/// Three ring buttons (new, applied, not applied) with the total in the middle
/// of the copy, one credits line, and the two actions. Tapping a ring
/// filters the list and scrolls to it.
class _NumbersCard extends StatelessWidget {
  const _NumbersCard({
    required this.total,
    required this.newMatches,
    required this.applied,
    required this.notApplied,
    required this.creditsLine,
    required this.running,
    required this.onNew,
    required this.onApplied,
    required this.onNotApplied,
    required this.onViewAll,
    required this.onAutomation,
  });
  final int total, newMatches, applied, notApplied;
  final String creditsLine;
  final bool running;
  final VoidCallback onNew, onApplied, onNotApplied, onViewAll, onAutomation;


  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Container(
      padding: const EdgeInsets.all(JmSpace.x4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: JmRadius.lgR,
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('${JmCopy.plural(total, 'job')} in your database', style: context.type.uiStrong)),
              Icon(Icons.toll_rounded, size: 14, color: c.muted),
              const SizedBox(width: 4),
              Text(creditsLine, style: context.type.meta.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: JmSpace.x4),
          Row(
            children: [
              Expanded(child: _Ring(value: newMatches, total: total, label: 'New', color: c.match, onTap: onNew)),
              Expanded(child: _Ring(value: applied, total: total, label: 'Applied', color: c.ocean, onTap: onApplied)),
              Expanded(child: _Ring(value: notApplied, total: total, label: 'Not applied', color: c.sky, onTap: onNotApplied)),
            ],
          ),
          const SizedBox(height: JmSpace.x2),
          PrimaryButton(label: 'My jobs', icon: Icons.work_outline_rounded, onPressed: onViewAll),
          const SizedBox(height: JmSpace.x1),
          SecondaryButton(label: 'Jobs automation', icon: Icons.bolt_rounded, onPressed: onAutomation),

        ],
      ),
    );
  }
}

/// A circular button: ring showing [value] as a share of [total], the
/// number inside, the label under it.
class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.total, required this.label, required this.color, required this.onTap});
  final int value, total;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final share = total == 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Semantics(
      button: true,
      label: '$value $label',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: share),
                      duration: JmMotion.ringFill,
                      curve: JmMotion.ease,
                      builder: (_, v, _) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        color: color,
                        backgroundColor: c.surface2,
                      ),
                    ),
                    Center(child: Text('$value', style: context.type.stat.copyWith(fontSize: 22))),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(label, style: context.type.meta.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),

            ],

          ),
        ),
      ),
    );
  }
}
