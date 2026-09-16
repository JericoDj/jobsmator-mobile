import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/copy.dart';
import '../core/models/job.dart';
import '../core/models/run.dart';
import '../providers/jobs_provider.dart';
import '../providers/run_provider.dart';

/// Where the user actually sees search progress.
///
/// The API only reports queued/running/done, so the site being "searched" is
/// an estimate paced across the run's sites over a typical 60 s. Job counts
/// are never invented — they appear only once the run is done.
class SearchProgress {
  const SearchProgress({required this.sites, required this.index});
  final List<String> sites;
  final int index;

  String get currentSite => sites.isEmpty ? '' : sites[index.clamp(0, sites.length - 1)];
  int get done => index.clamp(0, sites.length);
  int get total => sites.length;
}

/// Step 4. Ties [RunProvider] and [JobsProvider] to one run id and drives
/// the screen's phases: searching → results / empty / failed.
class ResultsController extends ChangeNotifier {
  ResultsController(this.runId, this._runs, this._jobs) {
    _runs.addListener(_onRun);
    // Deferred: created during the screen's first build, and watch() notifies.
    scheduleMicrotask(() {
      if (_runs.current?.id != runId) {
        _runs.watch(runId);
      } else {
        _onRun();
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (run?.isActive ?? true) notifyListeners();
    });
  }

  final String runId;
  final RunProvider _runs;
  final JobsProvider _jobs;

  Timer? _ticker;
  bool _loadedJobs = false;
  bool _exporting = false;
  String? _exportError;

  Run? get run => _runs.current?.id == runId ? _runs.current : null;
  bool get exporting => _exporting;
  String? get exportError => _exportError;

  bool get searching => run == null || run!.isActive;
  bool get failed => run?.isFailed ?? false;
  bool get loadingJobs => run?.isDone == true && (_jobs.loading || !_loadedJobs);
  bool get hasResults => run?.isDone == true && _loadedJobs && !_jobs.loading;

  String get failureMessage => JmCopy.forError(run?.errorCode);
  Duration get elapsed => _runs.elapsed;

  SearchProgress get progress {
    final sites = run?.request.sites ?? const <String>[];
    if (sites.isEmpty) return const SearchProgress(sites: [], index: 0);
    final perSite = Duration(milliseconds: (60000 / sites.length).round());
    final idx = elapsed.inMilliseconds ~/ perSite.inMilliseconds;
    return SearchProgress(sites: sites, index: idx.clamp(0, sites.length - 1));
  }

  String get headline =>
      JmCopy.resultsHeadline(_jobs.strongCount, _jobs.leadInterest ?? run?.request.interests.firstOrNull);

  void _onRun() {
    final r = run;
    if (r != null && r.isDone && !_loadedJobs) {
      _loadedJobs = true;
      _jobs.loadForRun(runId).catchError((_) {
        _loadedJobs = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> retryLoad() {
    _loadedJobs = true;
    return _jobs.loadForRun(runId);
  }

  void filter(Tier? tier) => _jobs.setFilter(tier);

  Future<RunSheet?> exportToSheet() async {
    _exporting = true;
    _exportError = null;
    notifyListeners();
    try {
      return await _runs.exportToSheet(runId);
    } catch (e) {
      _exportError = messageOf(e, fallback: "We couldn't reach Google Sheets. Try again in a minute.");
      return null;
    } finally {
      _exporting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _runs.removeListener(_onRun);
    super.dispose();
  }
}
