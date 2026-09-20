import '../../core/api/api_client.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/job_detail_controller.dart';
import '../../core/copy.dart';
import '../../core/models/job.dart';
import '../../providers/job_catalog_provider.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/resume_provider.dart';
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
    final ok = await launchUrl(
      Uri.parse(job.url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted)
      showJmToast(
        context,
        title: "Couldn't open ${job.site}",
        tone: ToastTone.error,
      );
  }

  Future<void> _apply(BuildContext context, Job job) async {
    final catalog = context.read<JobCatalogProvider>();
    await _open(context, job);
    if (!context.mounted || job.applied) return;
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          JmSpace.x4,
          0,
          JmSpace.x4,
          JmSpace.x6,
        ),
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
            PrimaryButton(
              label: 'Yes, I applied',
              large: true,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: JmSpace.x2),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not yet'),
            ),
          ],
        ),
      ),
    );
    if (confirm == true && context.mounted) {
      await catalog.markApplied(job).catchError((_) {});
      if (!context.mounted) return;
      showJmToast(
        context,
        title: 'Marked as applied',
        body: '${job.title} at ${job.company}',
        tone: ToastTone.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<JobCatalogProvider>();
    final interests = context.watch<PreferencesProvider>().interests;
    final ctrl = context.watch<JobDetailController>();
    final job = catalog.byId(ctrl.jobId);
    final c = context.jm;
    final isFeedOnly =
        catalog.feed.any((j) => j.id == job?.id) &&
        !catalog.all.any((j) => j.id == job?.id);

    if (job == null) {
      return JmPage(
        appBar: AppBar(),
        scrollable: false,
        child: ctrl.missing
            ? EmptyState(
                title: "That job isn't here any more",
                body: 'It may have been removed from the source site.',
              )
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
        title: Text(job.title),
        actions: [
          IconButton(
            tooltip: job.saved ? 'Saved' : 'Save',
            onPressed: () => catalog.toggleSaved(job).catchError((_) {}),
            icon: Icon(
              job.saved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: job.saved ? c.oceanDeep : null,
            ),
          ),
          IconButton(
            tooltip: 'Copy link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: job.url));
              showJmToast(context, title: 'Link copied');
            },
            icon: const Icon(Icons.link_rounded),
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
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (job.expired)
            Container(
              margin: const EdgeInsets.only(bottom: JmSpace.x4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.warnTint,
                borderRadius: JmRadius.mdR,
              ),
              child: Row(
                children: [
                  Icon(Icons.event_busy_rounded, size: 18, color: c.warn),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This listing has expired on ${job.site}. It may be reposted, but the link no longer works.',
                      style: context.type.meta.copyWith(color: c.text),
                    ),
                  ),
                ],
              ),
            ),
          if (job.applied)
            Container(
              margin: const EdgeInsets.only(bottom: JmSpace.x4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.matchTint,
                borderRadius: JmRadius.mdR,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: c.matchDeep,
                  ),
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
                    avatar: Icon(
                      Icons.mark_email_read_outlined,
                      size: 16,
                      color: job.responded ? c.oceanDeep : c.muted,
                    ),
                    selected: job.responded,
                    onSelected: (_) =>
                        catalog.toggleResponded(job).catchError((_) {}),
                  ),
                  FilterChip(
                    label: const Text('Interview'),
                    avatar: Icon(
                      Icons.event_available_outlined,
                      size: 16,
                      color: job.interview ? c.oceanDeep : c.muted,
                    ),
                    selected: job.interview,
                    onSelected: (_) =>
                        catalog.toggleInterview(job).catchError((_) {}),
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
                        if (!isFeedOnly) TierBadge(tier: job.tier),
                      ],
                    ),
                    const SizedBox(height: JmSpace.x2),
                    Text(job.title, style: context.type.title),
                    const SizedBox(height: 4),
                    Text(
                      job.salary == null
                          ? job.company
                          : '${job.company} · ${job.salary}',
                      style: context.type.ui.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: JmSpace.x4),
              if (!isFeedOnly) ScoreRing(score: job.score, size: 72),
            ],
          ),
          const SizedBox(height: JmSpace.x6),
          if (isFeedOnly)
            Container(
              padding: const EdgeInsets.all(JmSpace.x4),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: JmRadius.lgR,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'This job is from the global board.',
                    style: context.type.uiStrong,
                  ),
                  const SizedBox(height: JmSpace.x2),
                  Text(
                    'Find out how well it fits your resume and interests.',
                    style: context.type.body.copyWith(color: c.muted),
                  ),
                  const SizedBox(height: JmSpace.x4),
                  PrimaryButton(
                    label: 'Score this job (1 credit)',
                    icon: Icons.auto_awesome,
                    onPressed: () async {
                      final resumeId = await _selectResume(context);
                      if (resumeId == null) return;
                      try {
                        final newJob = await catalog.scoreJob(job.id, resumeId: resumeId);
                        if (context.mounted) {
                          context.pushReplacement(AppRoutes.job(newJob.id));
                        }
                      } catch (e) {
                        if (context.mounted)
                          showJmToast(
                            context,
                            title: messageOf(e),
                            tone: ToastTone.error,
                          );
                      }
                    },
                  ),
                ],
              ),
            )
          else ...[
            JmLabel('Why it fits', color: c.muted),
            const SizedBox(height: JmSpace.x2),
            HighlightedText(
              job.why.isEmpty
                  ? 'No reason recorded for this listing.'
                  : job.why,
              terms: terms,
            ),
            if (job.redFlags.isNotEmpty) ...[
              const SizedBox(height: JmSpace.x6),
              JmLabel('Watch out for', color: c.muted),
              const SizedBox(height: JmSpace.x2),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final f in job.redFlags) FlagChip(f)],
              ),
            ],
            const SizedBox(height: JmSpace.x6),
            JmLabel('Matched interest', color: c.muted),
            const SizedBox(height: JmSpace.x2),
            Text(
              job.matchedInterest.isEmpty ? '—' : job.matchedInterest,
              style: context.type.body,
            ),
            const SizedBox(height: JmSpace.x6),
            _ReanalyzeCard(job: job),
          ],
          const SizedBox(height: JmSpace.x8),
          Container(
            padding: const EdgeInsets.all(JmSpace.x4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: JmRadius.lgR,
            ),
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
                      onPressed: () => context.push(
                        AppRoutes.tool('interview-prep'),
                        extra: '${job.title} at ${job.company}',
                      ),
                    ),
                    SecondaryButton(
                      label: 'Analyze this job',
                      onPressed: () => context.push(
                        AppRoutes.tool('jd-analyzer'),
                        extra: job.url,
                      ),
                    ),
                    if (job.coverLetter != null && job.coverLetter!.isNotEmpty)
                      SecondaryButton(
                        label: 'View cover letter',
                        onPressed: () => _showCoverLetterDialog(context, job),
                      )
                    else
                      SecondaryButton(
                        label: 'Write a cover letter',
                        onPressed: () => _generateCoverLetter(context, job, catalog),
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

/// Score this listing again against the current resume and interests.
/// Costs one credit, same as scoring a board job.
class _ReanalyzeCard extends StatefulWidget {
  const _ReanalyzeCard({required this.job});
  final Job job;

  @override
  State<_ReanalyzeCard> createState() => _ReanalyzeCardState();
}

class _ReanalyzeCardState extends State<_ReanalyzeCard> {
  var _busy = false;

  Future<void> _run() async {
    final resumeId = await _selectResume(context);
    if (resumeId == null) return;
    setState(() => _busy = true);
    try {
      final updated = await context.read<JobCatalogProvider>().scoreJob(
        widget.job.id, resumeId: resumeId
      );
      if (!mounted) return;
      context.read<JobsProvider>().replace(updated);
      showJmToast(
        context,
        title: 'Re-analysed: ${updated.score}% match',
        body: updated.why.isEmpty ? null : updated.why,
        tone: ToastTone.success,
      );
    } catch (e) {
      if (mounted)
        showJmToast(context, title: messageOf(e), tone: ToastTone.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Container(
      padding: const EdgeInsets.all(JmSpace.x4),
      decoration: BoxDecoration(color: c.surface, borderRadius: JmRadius.lgR),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Updated your resume?', style: context.type.uiStrong),
                const SizedBox(height: 2),
                Text(
                  'Score this job again with your latest profile.',
                  style: context.type.meta,
                ),
              ],
            ),
          ),
          const SizedBox(width: JmSpace.x3),
          SecondaryButton(
            label: _busy ? 'Scoring…' : 'Re-analyze · 1 credit',
            icon: Icons.refresh_rounded,
            onPressed: _busy ? null : _run,
          ),
        ],
      ),
    );
  }
}

Future<void> _generateCoverLetter(BuildContext context, Job job, JobCatalogProvider catalog) async {
  try {
    showJmToast(context, title: 'Generating cover letter...');
    final updatedJob = await catalog.generateCoverLetter(job.id);
    if (context.mounted) {
      context.read<JobsProvider>().replace(updatedJob);
      _showCoverLetterDialog(context, updatedJob);
    }
  } catch (e) {
    if (context.mounted) showJmToast(context, title: messageOf(e), tone: ToastTone.error);
  }
}

void _showCoverLetterDialog(BuildContext context, Job job) {
  final catalog = context.read<JobCatalogProvider>();
  final ctrl = TextEditingController(text: job.coverLetter ?? '');
  var saving = false;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: JmSpace.x4, right: JmSpace.x4, top: JmSpace.x6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cover Letter', style: context.type.title),
            const SizedBox(height: JmSpace.x4),
            Expanded(
              child: TextField(
                controller: ctrl,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write your cover letter here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: JmSpace.x4),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Copy',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: ctrl.text));
                      showJmToast(context, title: 'Copied');
                    },
                  ),
                ),
                const SizedBox(width: JmSpace.x4),
                Expanded(
                  child: PrimaryButton(
                    label: saving ? 'Saving...' : 'Save',
                    onPressed: saving ? null : () async {
                      setState(() => saving = true);
                      try {
                        await catalog.updateCoverLetter(job.id, ctrl.text);
                        if (context.mounted) {
                          context.read<JobsProvider>().replace(job.copyWith(coverLetter: ctrl.text));
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) showJmToast(context, title: messageOf(e), tone: ToastTone.error);
                        setState(() => saving = false);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: JmSpace.x4),
          ],
        ),
      ),
    ),
  );
}

Future<String?> _selectResume(BuildContext context) async {
  final resumes = context.read<ResumeProvider>().resumes;
  if (resumes.isEmpty) {
    showJmToast(context, title: 'No resumes available. Please upload one first.', tone: ToastTone.error);
    return null;
  }
  if (resumes.length == 1) return resumes.first.id;

  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(JmSpace.x4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Select a Resume', style: context.type.title),
          const SizedBox(height: JmSpace.x4),
          ...resumes.map((r) => ListTile(
            title: Text(r.filename),
            onTap: () => Navigator.pop(context, r.id),
          )),
        ],
      ),
    ),
  );
}
