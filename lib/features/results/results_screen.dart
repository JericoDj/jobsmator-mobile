import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/results_controller.dart';
import '../../core/copy.dart';
import '../../core/models/job.dart';
import '../../core/models/tool.dart';
import '../../providers/jobs_provider.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_logo_mark.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/jm_toast.dart';
import '../shared/widgets/section_header.dart';
import 'widgets/empty_state.dart';
import 'widgets/job_card.dart';
import 'widgets/search_progress.dart';
import 'widgets/staggered_entry.dart';
import 'widgets/summary_tiles.dart';

/// Step 4 — where the user lives. Summary tiles, tier filters, then the
/// list best-first. Single column at every width: a ranking, not a grid.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  Future<void> _open(BuildContext context, Job job) async {
    final ok = await launchUrl(
      Uri.parse(job.url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      showJmToast(
        context,
        title: "Couldn't open ${job.site}",
        body: 'Copy the link from the listing instead.',
        tone: ToastTone.error,
      );
    }
  }

  Future<void> _export(BuildContext context) async {
    final ctrl = context.read<ResultsController>();
    final sheet = await ctrl.exportToSheet();
    if (!context.mounted) return;
    if (sheet == null) {
      showJmToast(
        context,
        title: "Couldn't save to Google Sheets",
        body: ctrl.exportError,
        tone: ToastTone.error,
      );
      return;
    }
    final url = sheet.url;
    showJmToast(
      context,
      title: 'Saved to Google Sheets',
      body: sheet.rowsAdded == null
          ? null
          : '${JmCopy.plural(sheet.rowsAdded!, 'job')} added.',
      tone: ToastTone.success,
      actionLabel: url == null ? null : 'Open sheet',
      onAction: url == null
          ? null
          : () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ResultsController>();
    final jobs = context.watch<JobsProvider>();
    final c = context.jm;
    final run = ctrl.run;

    final appBar = AppBar(
      leading: BackButton(onPressed: () => context.go(AppRoutes.jobs)),
      title: const JmWordmark(size: 24),
      actions: [
        if (ctrl.hasResults)
          IconButton(
            tooltip: 'Save to Google Sheets',
            onPressed: ctrl.exporting ? null : () => _export(context),
            icon: ctrl.exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.table_chart_outlined),
          ),
        const SizedBox(width: 4),
      ],
    );

    if (ctrl.searching) {
      return JmPage(
        appBar: appBar,
        child: SearchProgressView(
          progress: ctrl.progress,
          queued: run == null || run.status.name == 'queued',
          interests: run?.request.interests ?? const [],
        ),
      );
    }

    if (ctrl.failed) {
      return JmPage(
        appBar: appBar,
        scrollable: false,
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: "That search didn't finish",
          body: ctrl.failureMessage,
          action: SecondaryButton(
            label: 'Change sites',
            onPressed: () => context.go(AppRoutes.sites),
          ),
        ),
      );
    }

    if (ctrl.loadingJobs) {
      return JmPage(
        appBar: appBar,
        scrollable: false,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final visible = jobs.visible;
    final interests = run?.request.interests ?? const <String>[];
    final showWeakerLink =
        jobs.filter == null && !jobs.showWeaker && jobs.weakerCount > 0;

    return JmPage(
      appBar: appBar,
      maxWidth: JmLayout.results,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: JmSpace.x2),
          Text(
            ctrl.headline,
            style: context.type.display.copyWith(fontSize: 28),
          ),
          const SizedBox(height: JmSpace.x2),
          Text(
            '${JmCopy.plural(run?.stats?.scored ?? jobs.all.length, 'listing')} scored across '
            '${JmCopy.plural(run?.request.sites.length ?? 0, 'site')} for ${interests.join(', ')}.',
            style: context.type.body.copyWith(color: c.muted),
          ),
          const SizedBox(height: JmSpace.x6),
          SummaryTiles(
            strong: jobs.strongCount,
            good: jobs.goodCount,
            weaker: jobs.weakerCount,
            sites: run?.request.sites.length ?? 0,
            active: jobs.filter,
            onTier: ctrl.filter,
          ),
          const SizedBox(height: JmSpace.x6),
          if (run?.stats?.feedback != null) ...[
            _FeedbackCard(text: run!.stats!.feedback!),
            const SizedBox(height: JmSpace.x6),
          ],
          if (jobs.filter != null)
            Padding(
              padding: const EdgeInsets.only(bottom: JmSpace.x3),
              child: Row(
                children: [
                  TierBadge(
                    tier: jobs.filter!,
                    count: jobs.countOf(jobs.filter!),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => ctrl.filter(null),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Show all'),
                  ),
                ],
              ),
            ),
          if (visible.isEmpty)
            jobs.strongCount == 0 && jobs.filter == null && jobs.goodCount == 0
                ? EmptyState(
                    title: 'No matches this time',
                    body:
                        'Adding another interest or lowering the minimum score usually helps.',
                    action: SecondaryButton(
                      label: 'Edit interests',
                      onPressed: () => context.go(AppRoutes.interests),
                    ),
                  )
                : EmptyState(
                    title: 'Nothing in this tier',
                    body: 'Tap the tile again to show every match.',
                    action: SecondaryButton(
                      label: 'Show all',
                      onPressed: () => ctrl.filter(null),
                    ),
                  )
          else ...[
            for (final (i, job) in visible.indexed) ...[
              if (i > 0) const SizedBox(height: JmSpace.x3),
              StaggeredEntry(
                key: ValueKey(job.id),
                index: i,
                child: JobCard(
                  job: job,
                  interests: interests,
                  onOpen: () => _open(context, job),
                  onSave: () => jobs.toggleSaved(job).catchError((_) {
                    if (!context.mounted) return;
                    showJmToast(
                      context,
                      title: "Couldn't save that job",
                      body: 'Check your connection and try again.',
                      tone: ToastTone.error,
                    );
                  }),
                  onHide: () {
                    jobs.toggleHidden(job).catchError((_) {});
                    showJmToast(
                      context,
                      title: 'Hidden ${job.title}',
                      actionLabel: 'Undo',
                      onAction: () => jobs.toggleHidden(job).catchError((_) {}),
                    );
                  },
                ),
              ),
            ],
          ],
          if (showWeakerLink) ...[
            const SizedBox(height: JmSpace.x6),
            Center(
              child: SecondaryButton(
                label: JmCopy.weakerLink(jobs.weakerCount),
                icon: Icons.expand_more_rounded,
                onPressed: jobs.revealWeaker,
              ),
            ),
          ],
          if (jobs.hiddenCount > 0) ...[
            const SizedBox(height: JmSpace.x4),
            Center(
              child: Text(
                '${JmCopy.plural(jobs.hiddenCount, 'job')} hidden',
                style: context.type.meta,
              ),
            ),
          ],
          const SizedBox(height: JmSpace.x6),
        ],
      ),
    );
  }
}

/// What the engine thinks of the resume against these interests. Two lines
/// on the page; the full text and the tools that act on it live in a sheet.
/// The text is stored on the run, so reopening it from History shows it too.
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Material(
      color: c.oceanTint.withValues(alpha: .45),
      borderRadius: JmRadius.lgR,
      child: InkWell(
        borderRadius: JmRadius.lgR,
        onTap: () => _showFeedbackSheet(context, text),
        child: Container(
          padding: const EdgeInsets.all(JmSpace.x4),
          decoration: BoxDecoration(
            borderRadius: JmRadius.lgR,
            border: Border.all(color: c.ocean.withValues(alpha: .25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: c.oceanDeep,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Resume feedback',
                    style: context.type.label.copyWith(color: c.oceanDeep),
                  ),
                  const Spacer(),
                  Text(
                    'Read more',
                    style: context.type.meta.copyWith(
                      color: c.oceanDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: c.oceanDeep,
                  ),
                ],
              ),
              const SizedBox(height: JmSpace.x2),
              Text(
                text,
                style: context.type.body.copyWith(fontSize: 14.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showFeedbackSheet(BuildContext context, String text) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.jm.ground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FeedbackSheet(text: text),
  );
}

class _FeedbackSheet extends StatelessWidget {
  const _FeedbackSheet({required this.text});
  final String text;

  // The tools that act on this advice, in the order a user would reach for them.
  static const _toolIds = ['resume-analyzer', 'resume-builder', 'job-match'];

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .6,
      maxChildSize: .92,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(
          JmSpace.x4,
          JmSpace.x3,
          JmSpace.x4,
          JmSpace.x6,
        ),
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: c.oceanDeep),
              const SizedBox(width: 8),
              Text('Resume feedback', style: context.type.heading),
              const Spacer(),
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  showJmToast(
                    context,
                    title: 'Copied',
                    tone: ToastTone.success,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x3),
          Text(
            text,
            style: context.type.body.copyWith(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: JmSpace.x6),
          JmLabel('Tools that can help', color: c.muted),
          const SizedBox(height: JmSpace.x2),
          Container(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: JmRadius.lgR,
              border: Border.all(color: c.line),
            ),
            child: Column(
              children: [
                for (final (i, id) in _toolIds.indexed)
                  if (toolById(id) case final tool?) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: c.line,
                      ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.tool(tool.id));
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        child: Row(
                          children: [
                            Icon(tool.icon, size: 20, color: c.oceanDeep),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        tool.title,
                                        style: context.type.uiStrong,
                                      ),
                                      if (tool.premium) ...[
                                        const SizedBox(width: 6),
                                        const JmBadge('Pro'),
                                      ],
                                    ],
                                  ),
                                  Text(tool.blurb, style: context.type.meta),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: c.faint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
