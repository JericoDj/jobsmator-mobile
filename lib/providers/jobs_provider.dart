import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/models/job.dart';

class JobsProvider extends ChangeNotifier {
  late ApiClient api;

  List<Job> jobs = [];
  Tier? filter;
  bool loading = false;

  List<Job> get visible => jobs.where((j) => !j.hidden && (filter == null || j.tier == filter)).toList();

  Future<void> loadForRun(String runId) async {
    loading = true;
    notifyListeners();
    try {
      final res = await api.get('/v1/runs/$runId/jobs');
      jobs = (res['items'] as List).map((j) => Job.fromJson(j)).toList();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setFilter(Tier? tier) {
    filter = tier;
    notifyListeners();
  }

  Future<void> toggleSaved(Job job) => _toggle(job, 'save', (j, v) => j.copyWith(saved: v), job.saved);
  Future<void> toggleHidden(Job job) => _toggle(job, 'hide', (j, v) => j.copyWith(hidden: v), job.hidden);

  Future<void> _toggle(Job job, String action, Job Function(Job, bool) apply, bool before) async {
    _replace(apply(job, !before)); // optimistic
    try {
      await api.post('/v1/jobs/${job.id}/$action');
    } catch (_) {
      _replace(apply(job, before));
    }
  }

  void _replace(Job updated) {
    jobs = [for (final j in jobs) j.id == updated.id ? updated : j];
    notifyListeners();
  }
}
