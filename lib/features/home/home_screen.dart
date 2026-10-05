import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/home_controller.dart';
import '../../core/copy.dart';
import '../../core/models/job.dart';
import '../../core/models/resume.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_catalog_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/resume_provider.dart';

import '../../providers/run_provider.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/notification_bell.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/selection_chip.dart';
import '../shared/widgets/tab_header.dart';
import 'job_list_screen.dart';

/// Home is the product's promise in four rows, no copy needed:
/// Search → Jobs → Matches.

class OnboardingCheck extends StatefulWidget {
  final Widget child;
  const OnboardingCheck({super.key, required this.child});
  @override
  State<OnboardingCheck> createState() => _OnboardingCheckState();
}

class _OnboardingCheckState extends State<OnboardingCheck> {
  // App-session-wide, not per-widget: once we've sent a user to Upload for
  // being brand new, a manual trip back to Home (e.g. via the tab bar)
  // must not bounce them straight back out again.
  static bool _redirectedThisSession = false;

  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final resumes = context.watch<ResumeProvider>();

    if (!_checked && prefs.loaded && resumes.loaded) {
      _checked = true;
      // Brand new: no interests picked *and* nothing uploaded. A user with
      // either already has a reason to see Home's empty states instead.
      final brandNew = prefs.interests.isEmpty && resumes.latest == null;
      if (brandNew && !_redirectedThisSession) {
        _redirectedThisSession = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(AppRoutes.upload);
        });
      }
    }
    return widget.child;
  }
}

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
    final catalog = context.watch<JobCatalogProvider>();
    context.watch<RunProvider>();
    context.watch<PreferencesProvider>();
    final ctrl = context.watch<HomeController>();
    final user = context.watch<AuthProvider>().user;
    final c = context.jm;

    final jobs = catalog.all.where((j) => !j.hidden).toList();
    final applied = jobs.where((j) => j.applied).length;
    final total = jobs.length;
    final notApplied = total - applied;
    final applyRate = total == 0 ? 0.0 : applied / total;

    return OnboardingCheck(
      child: RefreshIndicator(
        onRefresh: ctrl.refreshAll,
        child: JmPage(
          maxWidth: JmLayout.results,
          padding: JmPage.tabPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabHeader(
                title: '${_greeting()}, ${user?.firstName ?? 'there'}',
                subtitle: 'Search less. Apply more.',
                trailing: const NotificationBell(),
              ),
              const SizedBox(height: JmSpace.x4),

              // 1 · Search
              _SearchCard(
                left: ctrl.searchesLeft,
                limit: ctrl.searchLimit,
                period: ctrl.planPeriod,
                running: ctrl.runInProgress,
                nextAutoRunAt: ctrl.nextAutoRunAt,
                onSearch: () => context.go(
                  ctrl.runInProgress
                      ? AppRoutes.run(context.read<RunProvider>().current!.id)
                      : AppRoutes.upload,
                ),
                onSchedule: () => context.push(AppRoutes.schedule),
              ),
              const SizedBox(height: JmSpace.x2),

              // 2 · Jobs
              SectionHeader(
                title: 'Your jobs',

                action: 'View all',
                onAction: () => context.push(AppRoutes.history),
              ),
              const SizedBox(height: JmSpace.x3),
              Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: JmRadius.lgR,
                  border: Border.all(color: c.line),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _Count(
                          value: total,
                          label: 'Total jobs',
                          color: c.ocean,
                        ),
                      ),
                      VerticalDivider(width: 1, color: c.line),
                      Expanded(
                        child: _Count(
                          value: applied,
                          label: 'Applied',
                          color: c.match,
                        ),
                      ),
                      VerticalDivider(width: 1, color: c.line),
                      Expanded(
                        child: _Count(
                          value: notApplied,
                          label: 'Not applied',
                          color: c.sky,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: JmSpace.x4),
              _RateBar(label: 'Application rate', value: applyRate, color: c.ocean),
              const SizedBox(height: JmSpace.x4),
              _RateBar(
                label: 'Strong match rate',
                value: ctrl.strongMatchRate,
                color: c.match,
              ),
              const SizedBox(height: JmSpace.x3),
              // 3 · Matches — scoped to whichever resume is selected, since
              // scoring now happens per resume rather than per catalog job.
              SectionHeader(
                title: 'Matches',

                action: 'See all',
                onAction: () =>
                    context.push(AppRoutes.jobList(JobListKind.matches.name)),
              ),
              const SizedBox(height: JmSpace.x1),
              const _MatchesSection(),
              const SizedBox(height: JmSpace.x6),
              const SizedBox(height: JmSpace.x6),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one action: credits left inside a ring, one big button, and a
/// quiet link to schedule. Sits on a soft cobalt→sky wash so it reads as
/// the hero of the page without a block of dark colour.
class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.left,
    required this.limit,
    required this.period,
    required this.running,
    required this.nextAutoRunAt,
    required this.onSearch,
    required this.onSchedule,
  });
  final int left, limit;
  final String period;
  final bool running;
  final DateTime? nextAutoRunAt;
  final VoidCallback onSearch, onSchedule;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final canSearch = left > 0 || running;
    final share = limit == 0 ? 0.0 : (left / limit).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: JmRadius.lgR,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: ColoredBox(color: c.card)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.2, -1.2),
                  radius: 1.2,
                  colors: [c.ocean.withValues(alpha: .16), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.1, 1.4),
                  radius: 1.0,
                  colors: [c.sky.withValues(alpha: .14), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: JmRadius.lgR,
                border: Border.all(color: c.line),
              ),
            ),
          ),
          // Full width so the wash fills the card, and everything centred.
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                JmSpace.x4,
                JmSpace.x4,
                JmSpace.x4,
                JmSpace.x2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: share),
                          duration: JmMotion.ringFill,
                          curve: JmMotion.ease,
                          builder: (_, v, _) => CircularProgressIndicator(
                            value: running ? null : v,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            color: left == 0 && !running ? c.faint : c.ocean,
                            backgroundColor: c.surface2,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$left',
                                style: context.type.stat.copyWith(
                                  fontSize: 28,
                                  height: 1,
                                  color: c.ink,
                                ),
                              ),
                              Text(
                                'of $limit',
                                style: context.type.meta.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: JmSpace.x2),
                  Text(
                    running
                        ? 'Search running'
                        : '${left == 1 ? 'Search' : 'Searches'} left $period',
                    style: context.type.meta.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: JmSpace.x1),
                  SizedBox(
                    width: 220,
                    child: PrimaryButton(
                      label: running ? 'See progress' : 'Search now',
                      icon: running
                          ? Icons.timelapse_rounded
                          : Icons.play_arrow_rounded,
                      onPressed: canSearch ? onSearch : null,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onSchedule,
                    style: TextButton.styleFrom(foregroundColor: c.oceanDeep),
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(
                      nextAutoRunAt == null
                          ? 'Schedule'
                          : 'Next run ${JmCopy.relativeFuture(nextAutoRunAt!)}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Number over label, centred.
class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label, required this.color});
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final body = Padding(
      padding: const EdgeInsets.symmetric(vertical: JmSpace.x2),
      child: Column(
        children: [
          Text(
            '$value',
            style: context.type.stat.copyWith(
              fontSize: 22,
              color: value == 0 ? c.faint : c.ink,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: context.type.meta.copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
    return body;
  }
}

/// Score and title, nothing else.
class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.job, required this.onTap});
  final Job job;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final color = job.score >= 70 ? c.matchDeep : c.oceanDeep;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                '${job.score}%',
                style: context.type.stat.copyWith(fontSize: 15, color: color),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                job.title,
                style: context.type.uiStrong,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.faint),
          ],
        ),
      ),
    );
  }
}

/// The resume-scoped matches list: a selector chip (opens a picker when
/// there's more than one resume), the resume's top tags, then its ranked
/// matches from `GET /v1/resumes/:id/matches`. While the resume is still
/// being analysed, polls `GET /v1/resumes/:id` every 4s for up to 2
/// minutes rather than leaving the section stuck on a spinner forever.
class _MatchesSection extends StatefulWidget {
  const _MatchesSection();

  @override
  State<_MatchesSection> createState() => _MatchesSectionState();
}

class _MatchesSectionState extends State<_MatchesSection> {
  Timer? _poll;
  DateTime? _pollStart;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _ensurePolling(ResumeProvider resumes, String id) {
    if (_poll != null) return;
    _pollStart = DateTime.now();
    _poll = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (DateTime.now().difference(_pollStart!) > const Duration(minutes: 2)) {
        timer.cancel();
        _poll = null;
        return;
      }
      try {
        final updated = await resumes.fetchOne(id);
        if (updated.analysisStatus != ResumeAnalysisStatus.pending) {
          timer.cancel();
          _poll = null;
        }
      } catch (_) {
        // Transient poll failures are ignored; the next tick retries.
      }
    });
  }

  Future<void> _pickResume(BuildContext context, ResumeProvider resumes) {
    final c = context.jm;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in resumes.resumes)
              ListTile(
                leading: Icon(
                  Icons.description_outlined,
                  color: r.id == resumes.selectedId ? c.oceanDeep : c.muted,
                ),
                title: Text(r.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: r.id == resumes.selectedId
                    ? Icon(Icons.check_rounded, color: c.oceanDeep)
                    : null,
                onTap: () {
                  resumes.select(r.id);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resumes = context.watch<ResumeProvider>();
    final c = context.jm;
    final selected = resumes.selected;

    if (selected == null) {
      return _Empty(
        text: 'Upload a resume to get matches.',
        action: SecondaryButton(
          label: 'Upload a resume',
          onPressed: () => context.go(AppRoutes.upload),
        ),
      );
    }

    final pending = selected.analysisStatus == ResumeAnalysisStatus.pending;
    if (pending) {
      _ensurePolling(resumes, selected.id);
    } else {
      _poll?.cancel();
      _poll = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _ResumeSelectorChip(
            resume: selected,
            expandable: resumes.resumes.length > 1,
            onTap: resumes.resumes.length > 1 ? () => _pickResume(context, resumes) : null,
          ),
        ),
        const SizedBox(height: JmSpace.x2),
        if (pending)
          const _AnalyzingCard()
        else if (selected.analysisStatus == ResumeAnalysisStatus.failed)
          const _Empty(text: "Couldn't analyze this resume. Try re-analyzing it from your AI profile.")
        else ...[
          if (selected.analysis != null && selected.analysis!.tags.isNotEmpty) ...[
            Wrap(
              spacing: JmSpace.x2,
              runSpacing: JmSpace.x2,
              children: [
                for (final t in selected.analysis!.tags.take(5))
                  SelectionChip(label: t, selected: false, onChanged: null),
              ],
            ),
            const SizedBox(height: JmSpace.x3),
          ],
          FutureBuilder<ResumeMatches>(
            key: ValueKey(selected.id),
            future: resumes.loadMatches(selected.id),
            initialData: resumes.cachedMatches(selected.id),
            builder: (context, snap) {
              final items = snap.data?.items ?? const <Job>[];
              if (snap.connectionState == ConnectionState.waiting && items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: JmSpace.x6),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (items.isEmpty) {
                return const _Empty(text: 'No matches yet for this resume.');
              }
              final top = items.take(5).toList();
              return Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: JmRadius.lgR,
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  children: [
                    for (final (i, job) in top.indexed) ...[
                      if (i > 0) Divider(height: 1, color: c.line),
                      _MatchRow(job: job, onTap: () => context.push(AppRoutes.job(job.id))),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// "Matches for: (filename) ▾" — the ▾ only shows once there's something
/// to switch to.
class _ResumeSelectorChip extends StatelessWidget {
  const _ResumeSelectorChip({required this.resume, required this.expandable, this.onTap});
  final Resume resume;
  final bool expandable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: JmRadius.pillR,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: JmRadius.pillR,
            border: Border.all(color: c.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 14, color: c.muted),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  'Matches for: ${resume.filename}',
                  style: context.type.meta.copyWith(fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (expandable) ...[
                const SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, size: 16, color: c.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyzingCard extends StatelessWidget {
  const _AnalyzingCard();

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Container(
      padding: const EdgeInsets.all(JmSpace.x4),
      decoration: BoxDecoration(color: c.surface, borderRadius: JmRadius.lgR),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.ocean),
          ),
          const SizedBox(width: JmSpace.x3),
          Expanded(
            child: Text('Analyzing your resume…', style: context.type.body.copyWith(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

/// Label on the left, percentage on the right, a thin filled bar below.
class _RateBar extends StatelessWidget {
  const _RateBar({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value; // 0..1
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final share = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: context.type.ui.copyWith(fontSize: 14)),
            ),
            Text(
              '${(share * 100).round()}%',
              style: context.type.stat.copyWith(fontSize: 15, color: c.ink),
            ),
          ],
        ),
        const SizedBox(height: JmSpace.x2),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: c.surface2)),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: share,
                      heightFactor: 1,
                      child: ColoredBox(color: color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, this.action});
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
          Text(text, style: context.type.body.copyWith(fontSize: 15)),
          if (action != null) ...[const SizedBox(height: JmSpace.x3), action!],
        ],
      ),
    );
  }
}
