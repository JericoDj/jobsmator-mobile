import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/models/run.dart';

class RunProvider extends ChangeNotifier {
  late ApiClient api;

  Run? current;
  String? error;
  Timer? _poll;

  Future<String?> start({
    required String resumeId, required List<String> interests, required List<String> sites,
    int jobsPerSite = 20, bool remoteOnly = false, int minScore = 60, bool saveToSheet = false,
  }) async {
    error = null;
    try {
      final res = await api.post('/v1/runs', body: {
        'resumeId': resumeId, 'interests': interests, 'sites': sites, 'jobsPerSite': jobsPerSite,
        'remoteOnly': remoteOnly, 'minScore': minScore, 'saveToSheet': saveToSheet,
      });
      final id = res['runId'] as String;
      watch(id);
      return id;
    } catch (e) {
      error = e is ApiException ? e.message : 'Something went wrong. Try again.';
      notifyListeners();
      return null;
    }
  }

  /// Polls every 3 s until the run is done or failed.
  void watch(String runId) {
    _poll?.cancel();
    Future<void> tick() async {
      try {
        current = Run.fromJson(await api.get('/v1/runs/$runId'));
        notifyListeners();
        if (!current!.isActive) _poll?.cancel();
      } catch (_) {}
    }
    tick();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => tick());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }
}
