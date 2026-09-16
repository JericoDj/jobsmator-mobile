import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/copy.dart';
import '../core/models/automation.dart';
import '../core/models/job.dart';
import '../core/models/run.dart';
import '../providers/job_catalog_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/run_provider.dart';
import '../providers/subscription_provider.dart';

/// One item in "Recent activity".
class Activity {
  const Activity({required this.title, required this.detail, required this.at, required this.kind});
  final String title, detail;
  final DateTime at;
  final ActivityKind kind;
}

enum ActivityKind { run, failed, applied, automation }

/// Aggregates the dashboard from providers. No data of its own — it just
/// triggers loads and derives the numbers the Home screen shows.
class HomeController extends ChangeNotifier {
  HomeController(this._catalog, this._runs, this._prefs, this._subs) {
    // Controllers are created lazily, inside the screen's first build. The
    // providers notify as soon as a load starts, so kick loads off after the
    // build phase, never from the constructor itself.
    scheduleMicrotask(() {
      if (!_catalog.loaded) _catalog.load().catchError((_) {});
      if (!_runs.historyLoaded) _runs.loadHistory().catchError((_) {});
      if (!_prefs.loaded) _prefs.load().catchError((_) {});
      if (!_subs.loaded) _subs.load().catchError((_) {});
    });
  }

  final JobCatalogProvider _catalog;
  final RunProvider _runs;
  final PreferencesProvider _prefs;
  final SubscriptionProvider _subs;

  /// When the last search finished (manual or automatic), if ever.
  DateTime? get lastRunAt {
    final manual = _runs.history.where((r) => !r.isActive).map((r) => r.finishedAt ?? r.startedAt);
    final auto = _prefs.automations.map((a) => a.lastRunAt).whereType<DateTime>();
    final all = [...manual, ...auto]..sort((a, b) => b.compareTo(a));
    return all.firstOrNull;
  }

  /// The soonest enabled automation.
  DateTime? get nextAutoRunAt {
    final next = _prefs.automations.where((a) => a.enabled && a.nextRunAt != null).map((a) => a.nextRunAt!).toList()
      ..sort();
    return next.firstOrNull;
  }

  bool get runInProgress => _runs.current?.isActive ?? false;
  int get searchesLeft => _subs.searchesLeft;
  String get planPeriod => _subs.plan.periodLabel;
  bool get canSearch => _subs.canSearch;

  bool get ready => _catalog.loaded && _prefs.loaded;
  int get newMatches => _catalog.newMatches;
  int get applications => _catalog.applied;
  int get automationsRunning => _prefs.automationsRunning;
  List<Job> get recommended => _catalog.recommended();
  List<Automation> get automations => _prefs.automations;
  bool get hasResume => _prefs.career.isEmpty == false;

  /// The line under the greeting: the single most useful number right now.
  String get subtext {
    if (runInProgress) return 'A search is running for you.';
    if (!ready) return 'Search less. Apply more.';
    if (newMatches > 0) return '${JmCopy.plural(newMatches, 'new match', 'new matches')} waiting for you.';
    if (lastRunAt == null) return 'Search less. Apply more.';
    return 'All caught up. Last search ${JmCopy.relative(lastRunAt)}.';
  }

  /// The assistant's one-line nudge. Derived, so it is always true.
  String get suggestion {
    final strong = _catalog.recommended(limit: 10).length;
    if (!_catalog.loaded) return 'Loading your matches…';
    if (_catalog.all.isEmpty) return 'Upload a resume and run a search — I will rank everything I find.';
    if (strong == 0) return 'No strong matches yet. Adding another interest usually helps.';
    if (strong == 1) return 'One job looks worth applying to today.';
    return '$strong jobs look worth applying to today.';
  }

  List<Activity> get recent {
    final items = <Activity>[
      for (final r in _runs.history.take(5))
        Activity(
          title: r.isFailed ? 'Search failed' : 'Search finished',
          detail: r.isFailed
              ? r.request.interests.join(', ')
              : '${r.stats?.recommended ?? 0} matches for ${r.request.interests.join(', ')}',
          at: r.finishedAt ?? r.startedAt,
          kind: r.isFailed ? ActivityKind.failed : ActivityKind.run,
        ),
      for (final a in _prefs.automations.where((a) => a.lastRunAt != null))
        Activity(
          title: a.name,
          detail: a.lastResultCount == null ? 'Ran' : '${a.lastResultCount} new jobs',
          at: a.lastRunAt!,
          kind: ActivityKind.automation,
        ),
      for (final j in _catalog.all.where((j) => j.applied).take(3))
        Activity(
          title: 'Applied',
          detail: '${j.title} · ${j.company}',
          at: j.postedAt ?? DateTime.now(),
          kind: ActivityKind.applied,
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return items.take(5).toList();
  }

  Run? get latestRun => _runs.history.firstOrNull;
}
