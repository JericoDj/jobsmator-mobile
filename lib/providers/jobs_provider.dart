import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/models/job.dart';

/// Jobs for the current run: tier filter, weaker-tier disclosure, and
/// optimistic save/hide.
class JobsProvider extends ChangeNotifier {
  JobsProvider(this._api);

  final ApiClient _api;

  String? _runId;
  List<Job> _jobs = const [];
  bool _loading = false;
  Tier? _filter;
  bool _showWeaker = false;

  List<Job> get all => _jobs;
  bool get loading => _loading;
  Tier? get filter => _filter;
  bool get showWeaker => _showWeaker;
  bool loadedFor(String runId) => _runId == runId && !_loading;

  List<Job> get _notHidden => _jobs.where((j) => !j.hidden).toList();

  int countOf(Tier t) => _notHidden.where((j) => j.tier == t).length;
  int get strongCount => countOf(Tier.strong);
  int get goodCount => countOf(Tier.good);
  int get weakerCount => countOf(Tier.skip);
  int get hiddenCount => _jobs.where((j) => j.hidden).length;

  /// Ranked, filtered, with the skip tier collapsed unless disclosed.
  List<Job> get visible {
    final base = _notHidden.where((j) => _filter == null || j.tier == _filter);
    if (_filter == Tier.skip || _showWeaker) return base.toList();
    return base.where((j) => j.tier != Tier.skip).toList();
  }

  /// The interest that produced the most strong matches — for the headline.
  String? get leadInterest {
    final strong = _notHidden.where((j) => j.tier == Tier.strong && j.matchedInterest.isNotEmpty);
    if (strong.isEmpty) return null;
    final counts = <String, int>{};
    for (final j in strong) {
      counts[j.matchedInterest] = (counts[j.matchedInterest] ?? 0) + 1;
    }
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
  }

  Future<void> loadForRun(String runId) async {
    _runId = runId;
    _loading = true;
    _filter = null;
    _showWeaker = false;
    notifyListeners();
    try {
      final res = await _api.get('/v1/runs/$runId/jobs');
      _jobs = (res['items'] as List).map((j) => Job.fromJson((j as Map).cast<String, dynamic>())).toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setFilter(Tier? tier) {
    _filter = _filter == tier ? null : tier;
    notifyListeners();
  }

  void revealWeaker() {
    _showWeaker = true;
    notifyListeners();
  }

  Future<void> toggleSaved(Job job) => _toggle(job, 'save', (j, v) => j.copyWith(saved: v), job.saved);
  Future<void> toggleHidden(Job job) => _toggle(job, 'hide', (j, v) => j.copyWith(hidden: v), job.hidden);

  Future<void> _toggle(Job job, String action, Job Function(Job, bool) apply, bool before) async {
    _replace(apply(job, !before));
    try {
      await _api.post('/v1/jobs/${job.id}/$action');
    } catch (_) {
      _replace(apply(job, before));
      rethrow;
    }
  }

  void _replace(Job updated) {
    _jobs = [for (final j in _jobs) j.id == updated.id ? updated : j];
    notifyListeners();
  }
}
