import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/mock_api_client.dart';
import '../core/models/job.dart';

enum JobFilter {
  all,
  strong,
  good,
  saved,
  applied,
  remote;

  String get label => switch (this) {
    all => 'All',
    strong => 'Strong',
    good => 'Good',
    saved => 'Saved',
    applied => 'Applied',
    remote => 'Remote',
  };
}

/// Every job JobsMator has found for this user, across runs — the job
/// database behind the Jobs tab and the Home recommendations.
class JobCatalogProvider extends ChangeNotifier {
  JobCatalogProvider(this._api);

  final ApiClient _api;

  List<Job> _jobs = const [];
  bool _loading = false;
  bool _loaded = false;
  String _query = '';
  JobFilter _filter = JobFilter.all;

  List<Job> _feed = const [];
  bool _feedLoading = false;

  List<Job> get all => _jobs;

  /// The job board: a random sample of every listing in the database, not
  /// scored for this user. Refreshed on demand.
  List<Job> get feed => _feed;
  bool get feedLoading => _feedLoading;

  /// What the Jobs tab shows as the board: the real feed, or shuffled
  /// fixture listings while that is empty so the section never sits blank.
  List<Job> get board => _feed.isNotEmpty ? _feed : _sampleBoard;
  bool get boardIsSample => _feed.isEmpty;
  List<Job> _sampleBoard = fixtureJobs.map((j) => Job.fromJson(j)).toList()..shuffle();

  Future<void> refreshBoard() async {
    if (_feed.isEmpty) {
      // Nothing real yet: reshuffle the sample so the button still does
      // something visible, and retry the feed quietly.
      _sampleBoard = _sampleBoard.toList()..shuffle();
      notifyListeners();
      await loadFeed().catchError((_) {});
      return;
    }
    await loadFeed();
  }
  bool get loading => _loading;
  bool get loaded => _loaded;
  String get query => _query;
  JobFilter get filter => _filter;

  List<Job> get _live => _jobs.where((j) => !j.hidden).toList();
  int get newMatches => _live.where((j) => j.tier != Tier.skip && !j.applied).length;
  int get applied => _live.where((j) => j.applied).length;
  int get responded => _live.where((j) => j.responded).length;
  int get interviews => _live.where((j) => j.interview).length;
  int get savedCount => _live.where((j) => j.saved).length;

  /// Top matches not yet applied to, best first.
  List<Job> recommended({int limit = 3}) =>
      (_live.where((j) => j.tier == Tier.strong && !j.applied).toList()..sort((a, b) => b.score.compareTo(a.score)))
          .take(limit)
          .toList();

  List<Job> get visible {
    final q = _query.trim().toLowerCase();
    return _live.where((j) {
      final byFilter = switch (_filter) {
        JobFilter.all => true,
        JobFilter.strong => j.tier == Tier.strong,
        JobFilter.good => j.tier == Tier.good,
        JobFilter.saved => j.saved,
        JobFilter.applied => j.applied,
        JobFilter.remote => j.remote,
      };
      final byQuery =
          q.isEmpty ||
          j.title.toLowerCase().contains(q) ||
          j.company.toLowerCase().contains(q) ||
          j.location.toLowerCase().contains(q) ||
          j.site.toLowerCase().contains(q);
      return byFilter && byQuery;
    }).toList()..sort((a, b) => b.score.compareTo(a.score));
  }

  int countFor(JobFilter f) {
    final was = _filter;
    _filter = f;
    final n = visible.length;
    _filter = was;
    return n;
  }

  Job? byId(String id) => _jobs.where((j) => j.id == id).firstOrNull;

  Future<void> loadFeed({int limit = 12}) async {
    _feedLoading = true;
    notifyListeners();
    try {
      final res = await _api.get('/v1/jobs/feed', query: {'limit': '$limit'});
      _feed = (res['items'] as List).map((j) => Job.fromJson((j as Map).cast<String, dynamic>())).toList();
    } finally {
      _feedLoading = false;
      notifyListeners();
    }
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.get('/v1/jobs');
      _jobs = (res['items'] as List).map((j) => Job.fromJson((j as Map).cast<String, dynamic>())).toList();
      _loaded = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Job?> fetch(String id) async {
    final cached = byId(id);
    if (cached != null) return cached;
    final job = Job.fromJson(await _api.get('/v1/jobs/$id'));
    _jobs = [..._jobs, job];
    notifyListeners();
    return job;
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setFilter(JobFilter f) {
    _filter = f;
    notifyListeners();
  }

  Future<void> toggleSaved(Job job) => _toggle(job, 'save', (j, v) => j.copyWith(saved: v), job.saved);
  Future<void> toggleHidden(Job job) => _toggle(job, 'hide', (j, v) => j.copyWith(hidden: v), job.hidden);
  Future<void> markApplied(Job job) => _toggle(job, 'applied', (j, v) => j.copyWith(applied: v), job.applied);
  Future<void> toggleResponded(Job job) =>
      _toggle(job, 'responded', (j, v) => j.copyWith(responded: v), job.responded);
  Future<void> toggleInterview(Job job) =>
      _toggle(job, 'interview', (j, v) => j.copyWith(interview: v), job.interview);

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
