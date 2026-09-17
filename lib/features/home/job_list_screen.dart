import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/models/job.dart';
import '../../providers/job_catalog_provider.dart';
import '../jobs/widgets/job_row.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/selection_chip.dart';

/// One slice of the catalogue. The route carries it as `/jobs/list/<name>`.
enum JobListKind {
  all,
  matches,
  saved,
  applied,
  notApplied;

  String get label => switch (this) {
    all => 'All',
    matches => 'New',
    saved => 'Saved',
    applied => 'Applied',
    notApplied => 'Not applied',
  };

  String get empty => switch (this) {
    all => 'No jobs yet. Run a search and every match lands here.',
    matches => 'No new matches. Run a search and they will land here.',
    saved => 'Nothing saved yet. Tap the bookmark on a job to keep it here.',
    applied => 'Nothing applied yet. Open a job and tap Mark as applied when you send it.',
    notApplied => 'Everything has been applied to — nice.',
  };

  List<Job> pick(JobCatalogProvider catalog) {
    final live = catalog.all.where((j) => !j.hidden);
    return switch (this) {
      all => live,
      matches => live.where((j) => j.tier != Tier.skip && !j.applied),
      saved => live.where((j) => j.saved),
      applied => live.where((j) => j.applied),
      notApplied => live.where((j) => !j.applied),
    }.toList()..sort((a, b) => b.score.compareTo(a.score));
  }

  static JobListKind parse(String? name) => values.where((k) => k.name == name).firstOrNull ?? all;
}

/// The full list, one chip per slice. Opens on [initial] and lets the user
/// hop between slices without going back.
class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key, required this.initial});
  final JobListKind initial;

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  late JobListKind _kind = widget.initial;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final catalog = context.watch<JobCatalogProvider>();
    final jobs = _kind.pick(catalog);
    return JmPage(
      appBar: AppBar(title: const Text('Jobs')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${jobs.length} ${jobs.length == 1 ? 'job' : 'jobs'}', style: context.type.title.copyWith(fontSize: 22)),
          const SizedBox(height: 2),
          Text('Best match first.', style: context.type.body.copyWith(color: c.muted, fontSize: 14)),
          const SizedBox(height: JmSpace.x4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final k in JobListKind.values) ...[
                  SelectionChip(
                    label: '${k.label} ${k.pick(catalog).length}',
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
              decoration: BoxDecoration(color: c.surface, borderRadius: JmRadius.lgR),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_kind.empty, style: context.type.body.copyWith(fontSize: 15)),
                  if (_kind == JobListKind.all || _kind == JobListKind.matches) ...[
                    const SizedBox(height: JmSpace.x3),
                    SecondaryButton(label: 'Find matching jobs', onPressed: () => context.go(AppRoutes.upload)),
                  ],
                ],
              ),
            )
          else
            for (final (i, job) in jobs.indexed) ...[
              if (i > 0) const SizedBox(height: JmSpace.x2),
              JobRow(job: job, onTap: () => context.push(AppRoutes.job(job.id))),
            ],
          const SizedBox(height: JmSpace.x6),
        ],
      ),
    );
  }
}
