import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/job_detail_controller.dart';
import '../../core/copy.dart';
import '../../core/models/job.dart';
import '../../providers/job_catalog_provider.dart';
import '../../providers/preferences_provider.dart';
import '../results/widgets/empty_state.dart';
import '../results/widgets/score_ring.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/highlighted_text.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/jm_toast.dart';

/// One job, in full. Same anatomy as the card, more room: where it came
/// from → what it is → why → watch out for → apply. Applied state is
/// remembered so the same listing is never applied to twice.
class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key});

  Future<void> _open(BuildContext context, Job job) async {
    final ok = await launchUrl(Uri.parse(job.url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showJmToast(context, title: "Couldn't open ${job.site}", tone: ToastTone.error);
  }

  Future<void> _apply(BuildContext context, Job job) async {
    final catalog = context.read<JobCatalogProvider>();
    await _open(context, job);
    if (!context.mounted || job.applied) return;
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(JmSpace.x4, 0, JmSpace.x4, JmSpace.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Did you apply?', style: ctx.type.title),
            const SizedBox(height: JmSpace.x2),
            Text(
              "We'll mark it so it never shows up as new again, and track it under Applications.",
              style: ctx.type.body.copyWith(color: ctx.jm.muted),
            ),
            const SizedBox(height: JmSpace.x6),
            PrimaryButton(label: 'Yes, I applied', large: true, onPressed: () => Navigator.pop(ctx, true)),
            const SizedBox(height: JmSpace.x2),
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          ],
        ),
      ),
    );
    if (confirm == true && context.mounted) {
      await catalog.markApplied(job).catchError((_) {});
      if (!context.mounted) return;
      showJmToast(context, title: 'Marked as applied', body: '${job.title} at ${job.company}', tone: ToastTone.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<JobCatalogProvider>();
    final interests = context.watch<PreferencesProvider>().interests;
    final ctrl = context.watch<JobDetailController>();
    final job = catalog.byId(ctrl.jobId);
    final c = context.jm;

    if (job == null) {
      return JmPage(
        appBar: AppBar(),
        scrollable: false,
        child: ctrl.missing
            ? EmptyState(title: "That job isn't here any more", body: 'It may have been removed from the source site.')
            : const Center(child: CircularProgressIndicator()),
      );
    }

    final terms = {
      ...interests,
      job.matchedInterest,
      ...interests.expand((i) => i.split(RegExp(r'\s+'))),
    }.where((t) => t.length > 2).toList();
    final meta = [
      job.site,
      if (job.location.isNotEmpty) job.location,
      if (job.remote) 'Remote',
      if (job.postedAt != null) JmCopy.relative(job.postedAt),
    ];

    return JmPage(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: job.saved ? 'Saved' : 'Save',
            onPressed: () => catalog.toggleSaved(job).catchError((_) {}),
            icon: Icon(
              job.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: job.saved ? c.oceanDeep : null,
            ),
          ),
          IconButton(
            tooltip: 'Hide',
            onPressed: () {
              catalog.toggleHidden(job).catchError((_) {});
              context.pop();
            },
            icon: const Icon(Icons.visibility_off_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottom: Row(
        children: [
          Expanded(
            child: job.applied
                ? SecondaryButton(
                    label: 'Open on ${job.site}',
                    icon: Icons.open_in_new_rounded,
                    onPressed: () => _open(context, job),
                  )
                : PrimaryButton(
                    label: 'Apply on ${job.site}',
                    icon: Icons.open_in_new_rounded,
                    large: true,
                    onPressed: () => _apply(context, job),
                  ),
          ),
          if (!job.applied) ...[
            const SizedBox(width: JmSpace.x2),
            SecondaryButton(
              label: 'Write application',
              onPressed: () =>
                  context.push(AppRoutes.tool('application-email'), extra: '${job.title} at ${job.company}'),
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (job.applied)
            Container(
              margin: const EdgeInsets.only(bottom: JmSpace.x4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: c.matchTint, borderRadius: JmRadius.mdR),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: c.matchDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You already applied to this one.',
                      style: context.type.ui.copyWith(color: c.matchDeep),
                    ),
                  ),
                ],
              ),
            ),
          // Track what happened next — these feed the Activity numbers.
          if (job.applied)
            Padding(
              padding: const EdgeInsets.only(bottom: JmSpace.x4),
              child: Wrap(
                spacing: JmSpace.x2,
                runSpacing: JmSpace.x2,
                children: [
                  FilterChip(
                    label: const Text('Got a response'),
                    avatar: Icon(Icons.mark_email_read_outlined, size: 16, color: job.responded ? c.oceanDeep : c.muted),
                    selected: job.responded,
                    onSelected: (_) => catalog.toggleResponded(job).catchError((_) {}),
                  ),
                  FilterChip(
                    label: const Text('Interview'),
                    avatar: Icon(Icons.event_available_outlined, size: 16, color: job.interview ? c.oceanDeep : c.muted),
                    selected: job.interview,
                    onSelected: (_) => catalog.toggleInterview(job).catchError((_) {}),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(meta.join(' · '), style: context.type.meta),
                        TierBadge(tier: job.tier),
                      ],
                    ),
                    const SizedBox(height: JmSpace.x2),
                    Text(job.title, style: context.type.title),
                    const SizedBox(height: 4),
                    Text(
                      job.salary == null ? job.company : '${job.company} · ${job.salary}',
                      style: context.type.ui.copyWith(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: JmSpace.x4),
              ScoreRing(score: job.score, size: 72),
            ],
          ),
          const SizedBox(height: JmSpace.x6),
          JmLabel('Why it fits', color: c.muted),
          const SizedBox(height: JmSpace.x2),
          HighlightedText(job.why.isEmpty ? 'No reason recorded for this listing.' : job.why, terms: terms),
          if (job.redFlags.isNotEmpty) ...[
            const SizedBox(height: JmSpace.x6),
            JmLabel('Watch out for', color: c.muted),
            const SizedBox(height: JmSpace.x2),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final f in job.redFlags) FlagChip(f)]),
          ],
          const SizedBox(height: JmSpace.x6),
          JmLabel('Matched interest', color: c.muted),
          const SizedBox(height: JmSpace.x2),
          Text(job.matchedInterest.isEmpty ? '—' : job.matchedInterest, style: context.type.body),
          const SizedBox(height: JmSpace.x8),
          Container(
            padding: const EdgeInsets.all(JmSpace.x4),
            decoration: BoxDecoration(color: c.surface, borderRadius: JmRadius.lgR),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ask the assistant', style: context.type.uiStrong),
                const SizedBox(height: JmSpace.x2),
                Wrap(
                  spacing: JmSpace.x2,
                  runSpacing: JmSpace.x2,
                  children: [
                    SecondaryButton(
                      label: 'Prepare me for interview',
                      onPressed: () =>
                          context.push(AppRoutes.tool('interview-prep'), extra: '${job.title} at ${job.company}'),
                    ),
                    SecondaryButton(
                      label: 'Analyze this job',
                      onPressed: () => context.push(AppRoutes.tool('jd-analyzer'), extra: job.url),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
