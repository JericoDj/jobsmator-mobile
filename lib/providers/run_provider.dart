import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/models/run.dart';

/// Owns the current run and the polling timer (3 s until done or failed).
class RunProvider extends ChangeNotifier {
  RunProvider(this._api);

  final ApiClient _api;

  Run? _current;
  Timer? _poll;
  DateTime? _watchingSince;
  List<Run> _history = const [];
  bool _historyLoaded = false;
  bool _searchTabVisible = true;
  bool _unseenResult = false;

  Run? get current => _current;
  List<Run> get history => _history;
  bool get historyLoaded => _historyLoaded;

  /// A run finished while the Search tab was not on screen — the Volt dot.
  bool get unseenResult => _unseenResult;

  /// The shell reports which tab is visible so a finished run can be
  /// flagged as unseen; switching to Search clears it.
  set searchTabVisible(bool visible) {
    _searchTabVisible = visible;
    if (visible && _unseenResult) {
      _unseenResult = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    final res = await _api.get('/v1/runs');
    _history = (res['items'] as List).map((j) => Run.fromJson((j as Map).cast<String, dynamic>())).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _historyLoaded = true;
    notifyListeners();
  }

  /// How long we've been watching the current run — drives the progress estimate.
  Duration get elapsed => _watchingSince == null ? Duration.zero : DateTime.now().difference(_watchingSince!);

  /// Starts a run and begins polling it. Throws [ApiException].
  Future<String> start({
    required String resumeId,
    required List<String> interests,
    required List<String> sites,
    int jobsPerSite = 20,
    bool remoteOnly = false,
    int minScore = 60,
    String? location,
    bool saveToSheet = false,
  }) async {
    final res = await _api.post(
      '/v1/runs',
      body: {
        'resumeId': resumeId,
        'interests': interests,
        'sites': sites,
        'jobsPerSite': jobsPerSite,
        'remoteOnly': remoteOnly,
        'minScore': minScore,
        'location': ?location,
        'saveToSheet': saveToSheet,
      },
    );
    final id = res['runId'] as String;
    _current = null;
    watch(id);
    return id;
  }

  void watch(String runId) {
    _poll?.cancel();
    _watchingSince = DateTime.now();
    Future<void> tick() async {
      try {
        final wasActive = _current?.isActive ?? true;
        _current = Run.fromJson(await _api.get('/v1/runs/$runId'));
        if (wasActive && !_current!.isActive) {
          _poll?.cancel();
          if (!_searchTabVisible) _unseenResult = true;
          if (_historyLoaded) loadHistory().catchError((_) {});
        }
        notifyListeners();
      } catch (_) {
        // Transient poll failures are ignored; the next tick retries.
      }
    }

    tick();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => tick());
  }

  Future<void> refresh(String runId) async {
    _current = Run.fromJson(await _api.get('/v1/runs/$runId'));
    notifyListeners();
  }

  /// Asks the engine to (re)write the run to the user's Google Sheet.
  Future<RunSheet> exportToSheet(String runId) async {
    final res = await _api.post('/v1/runs/$runId/export');
    final sheet = RunSheet.fromJson((res['sheet'] as Map? ?? const {}).cast<String, dynamic>());
    await refresh(runId).catchError((_) {});
    return sheet;
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
