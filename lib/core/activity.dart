import 'models/job.dart';
import 'models/automation.dart';
import 'models/run.dart';

/// One line of "what just happened": a finished or failed search, an
/// automation that ran, an application sent. Shown on Home and in the
/// notifications dropdown.
class Activity {
  const Activity({required this.title, required this.detail, required this.at, required this.kind});
  final String title, detail;
  final DateTime at;
  final ActivityKind kind;
}

enum ActivityKind { run, failed, applied, automation }

/// Newest first, at most [limit].
List<Activity> recentActivity({
  required List<Run> runs,
  required List<Automation> automations,
  required List<Job> jobs,
  int limit = 5,
}) {
  final items = <Activity>[
    for (final r in runs.take(5))
      Activity(
        title: r.isFailed ? 'Search failed' : 'Search finished',
        detail: r.isFailed
            ? r.request.interests.join(', ')
            : '${r.stats?.recommended ?? 0} matches for ${r.request.interests.join(', ')}',
        at: r.finishedAt ?? r.startedAt,
        kind: r.isFailed ? ActivityKind.failed : ActivityKind.run,
      ),
    for (final a in automations.where((a) => a.lastRunAt != null))
      Activity(
        title: a.name,
        detail: a.lastResultCount == null ? 'Ran' : '${a.lastResultCount} new jobs',
        at: a.lastRunAt!,
        kind: ActivityKind.automation,
      ),
    for (final j in jobs.where((j) => j.applied).take(3))
      Activity(
        title: 'Applied',
        detail: '${j.title} · ${j.company}',
        at: j.postedAt ?? DateTime.now(),
        kind: ActivityKind.applied,
      ),
  ]..sort((a, b) => b.at.compareTo(a.at));
  return items.take(limit).toList();
}
