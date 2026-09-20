import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/copy.dart';
import '../../core/models/job.dart';
import '../../providers/job_catalog_provider.dart';
import '../../providers/run_provider.dart';
import '../jobs/widgets/job_row.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/selection_chip.dart';

enum JobListKind {
  all,
  strong,
  good,
  matches,
  saved,
  applied,
  notApplied,
  weaker;

  String get label => switch (this) {
    all => 'All',
    strong => 'Strong',
    good => 'Good',
    matches => 'New',
    saved => 'Saved',
    applied => 'Applied',
    notApplied => 'Not applied',
    weaker => 'Weaker',
  };

  String get empty => switch (this) {
    all => 'No jobs yet. Run a search and every match lands here.',
    strong => 'No strong matches yet.',
    good => 'No good matches yet.',
    matches => 'No new matches. Run a search and they will land here.',
    saved => 'Nothing saved yet. Tap the bookmark on a job to keep it here.',
    applied =>
      'Nothing applied yet. Open a job and tap Mark as applied when you send it.',
    notApplied => 'Everything has been applied to — nice.',
    weaker => 'No weaker matches. Everything found cleared your minimum score.',
  };

  List<Job> pick(JobCatalogProvider catalog, {String? runId}) {
    final live = catalog.all.where(
      (j) => !j.hidden && (runId == null || j.runId == runId),
    );
    return switch (this) {
      all => live,
      strong => live.where((j) => j.tier == Tier.strong),
      good => live.where((j) => j.tier == Tier.good),
      matches => live.where((j) => j.tier != Tier.skip && !j.applied),
      saved => live.where((j) => j.saved),
      applied => live.where((j) => j.applied),
      notApplied => live.where((j) => !j.applied),
      weaker => live.where((j) => j.tier == Tier.skip),
    }.toList()..sort((a, b) => b.score.compareTo(a.score));
  }

  static JobListKind parse(String? name) =>
      values.where((k) => k.name == name).firstOrNull ?? all;
}

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key, required this.initial});
  final JobListKind initial;

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  late JobListKind _kind = widget.initial;
  String? _runId;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final catalog = context.watch<JobCatalogProvider>();
    final runs = context.watch<RunProvider>();
    final jobs = _kind.pick(catalog, runId: _runId);

    final strongCount = JobListKind.strong.pick(catalog, runId: _runId).length;
    final goodCount = JobListKind.good.pick(catalog, runId: _runId).length;
    final totalMatches = JobListKind.all.pick(catalog, runId: _runId).length;
    final clampedTotal = totalMatches.clamp(1, 1 << 30);

    return JmPage(
      appBar: AppBar(title: const Text('Jobs')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _TierCard(
                  label: 'Strong',
                  value: strongCount,
                  fill: strongCount / clampedTotal,
                  color: c.match,
                  selected: _kind == JobListKind.strong,
                  dimmed:
                      _kind != JobListKind.strong &&
                      (_kind == JobListKind.good),
                  onTap: () => setState(() => _kind = JobListKind.strong),
                ),
              ),
              const SizedBox(width: JmSpace.x3),
              Expanded(
                child: _TierCard(
                  label: 'Good',
                  value: goodCount,
                  fill: goodCount / clampedTotal,
                  color: c.volt,
                  selected: _kind == JobListKind.good,
                  dimmed:
                      _kind != JobListKind.good &&
                      (_kind == JobListKind.strong),
                  onTap: () => setState(() => _kind = JobListKind.good),
                ),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x6),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${jobs.length} ${jobs.length == 1 ? 'job' : 'jobs'}',
                      style: context.type.title.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Best match first.',
                      style: context.type.body.copyWith(
                        color: c.muted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String?>(
                initialValue: _runId,
                onSelected: (id) => setState(() => _runId = id),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: null, child: Text('All Runs')),
                  for (final r in runs.history)
                    PopupMenuItem(
                      value: r.id,
                      child: Text(
                        '${JmCopy.relative(r.startedAt)} - ${r.request.interests.join(', ')}',
                      ),
                    ),
                ],
                child: SelectionChip(
                  label: _runId == null
                      ? 'All Runs ▾'
                      : 'Run: ${JmCopy.relative(runs.history.firstWhere((r) => r.id == _runId).startedAt)} ▾',
                  selected: _runId != null,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final k in JobListKind.values.where(
                  (k) => k != JobListKind.strong && k != JobListKind.good,
                )) ...[
                  SelectionChip(
                    label:
                        '${k.label} ${k.pick(catalog, runId: _runId).length}',
                    selected: _kind == k,
                    onChanged: (_) => setState(() => _kind = k),
                  ),
                  const SizedBox(width: JmSpace.x2),
                ],
              ],
            ),
          ),
          const SizedBox(height: JmSpace.x4),
          if (!catalog.loaded)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: JmSpace.x8),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (jobs.isEmpty)
            Container(
              padding: const EdgeInsets.all(JmSpace.x4),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: JmRadius.lgR,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _kind.empty,
                    style: context.type.body.copyWith(fontSize: 15),
                  ),
                  if (_kind == JobListKind.all ||
                      _kind == JobListKind.matches) ...[
                    const SizedBox(height: JmSpace.x3),
                    SecondaryButton(
                      label: 'Find matching jobs',
                      onPressed: () => context.go(AppRoutes.upload),
                    ),
                  ],
                ],
              ),
            )
          else
            for (final (i, job) in jobs.indexed) ...[
              if (i > 0) const SizedBox(height: JmSpace.x2),
              JobRow(
                job: job,
                onTap: () => context.push(AppRoutes.job(job.id)),
              ),
            ],
          const SizedBox(height: JmSpace.x6),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.label,
    required this.value,
    required this.fill,
    required this.color,
    required this.selected,
    required this.dimmed,
    this.onTap,
  });

  final String label;
  final int value;
  final double fill;
  final Color color;
  final bool selected, dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '$value $label${onTap == null ? '' : ', filter'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: JmRadius.mdR,
          child: AnimatedContainer(
            duration: JmMotion.state,
            curve: JmMotion.ease,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: selected ? c.oceanTint : c.card,
              borderRadius: JmRadius.mdR,
              border: Border.all(
                color: selected ? c.ocean : c.line,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: AnimatedOpacity(
              duration: JmMotion.state,
              opacity: dimmed ? .55 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JmLabel(label, color: selected ? c.oceanDeep : c.muted),
                  const SizedBox(height: 2),
                  Text('$value', style: context.type.stat),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 6,
                      child: Stack(
                        children: [
                          Positioned.fill(child: ColoredBox(color: c.surface2)),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: fill.clamp(0, 1),
                            heightFactor: 1,
                            child: ColoredBox(color: color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
