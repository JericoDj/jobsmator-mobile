import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/activity.dart';
import '../core/copy.dart';
import '../core/models/automation.dart';
import '../core/models/job.dart';
import '../core/models/run.dart';
import '../providers/job_catalog_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/run_provider.dart';
import '../providers/subscription_provider.dart';

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
    final manual = _runs.history
        .where((r) => !r.isActive)
        .map((r) => r.finishedAt ?? r.startedAt);
    final auto = _prefs.automations
        .map((a) => a.lastRunAt)
        .whereType<DateTime>();
    final all = [...manual, ...auto]..sort((a, b) => b.compareTo(a));
    return all.firstOrNull;
  }

  /// The soonest enabled automation.
  DateTime? get nextAutoRunAt {
    final next =
        _prefs.automations
            .where((a) => a.enabled && a.nextRunAt != null)
            .map((a) => a.nextRunAt!)
            .toList()
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
  int get totalJobs => _catalog.all.where((j) => !j.hidden).length;
  int get automationsRunning => _prefs.automationsRunning;
  int get searchLimit => _subs.plan.searchLimit;
  String get planLabel => _subs.plan.label;
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

  List<Activity> get recent =>
      recentActivity(runs: _runs.history, automations: _prefs.automations, jobs: _catalog.all);

  Run? get latestRun => _runs.history.firstOrNull;
}
