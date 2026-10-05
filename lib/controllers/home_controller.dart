import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/models/job.dart';
import '../providers/job_catalog_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/resume_provider.dart';
import '../providers/run_provider.dart';
import '../providers/subscription_provider.dart';

/// Aggregates the dashboard from providers. No data of its own — it just
/// triggers loads and derives the numbers the Home screen shows.
class HomeController extends ChangeNotifier {
  HomeController(this._catalog, this._runs, this._prefs, this._subs, this._resumes) {
    // Controllers are created lazily, inside the screen's first build. The
    // providers notify as soon as a load starts, so kick loads off after the
    // build phase, never from the constructor itself.
    scheduleMicrotask(refreshAll);
    _wasRunInProgress = runInProgress;
    _runs.addListener(_onRunsChanged);
  }

  final JobCatalogProvider _catalog;
  final RunProvider _runs;
  final PreferencesProvider _prefs;
  final SubscriptionProvider _subs;
  final ResumeProvider _resumes;

  late bool _wasRunInProgress;

  /// A run just finished (manual or automatic) — the catalog it feeds is
  /// now stale everywhere it's shown (Home and the Jobs tab share it), so
  /// reload it once rather than waiting for the user to notice.
  void _onRunsChanged() {
    final now = runInProgress;
    if (_wasRunInProgress && !now) {
      _catalog.load().catchError((_) {});
    }
    _wasRunInProgress = now;
  }

  /// Pull-to-refresh: everything Home reads, at once.
  Future<void> refreshAll() => Future.wait([
    _catalog.load().catchError((_) {}),
    _runs.loadHistory().catchError((_) {}),
    _prefs.load().catchError((_) {}),
    _subs.load().catchError((_) {}),
    _resumes.load().catchError((_) {}),
  ]);

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
  String get planPeriod => _subs.current.periodLabel;
  bool get canSearch => _subs.canSearch;

  bool get ready => _catalog.loaded && _prefs.loaded;
  List<Job> get _liveJobs => _catalog.all.where((j) => !j.hidden).toList();
  int get totalJobs => _liveJobs.length;
  int get searchLimit => _subs.current.searchLimit;
  bool get hasResume => _resumes.latest != null;

  /// Share of non-hidden jobs that scored a strong match — replaces the
  /// old "average match score", which rewarded a pile of mediocre scores
  /// the same as a handful of great ones.
  double get strongMatchRate {
    if (totalJobs == 0) return 0;
    return _liveJobs.where((j) => j.tier == Tier.strong).length / totalJobs;
  }

  @override
  void dispose() {
    _runs.removeListener(_onRunsChanged);
    super.dispose();
  }
}
