import 'package:flutter/foundation.dart';

import '../core/api_client.dart';

const jobSites = [
  'LinkedIn', 'JobStreet', 'OnlineJobs.ph', 'Indeed', 'BossJob',
  'Kalibrr', 'Glassdoor', 'ZipRecruiter', 'Google Jobs', 'Wellfound',
];

class PreferencesProvider extends ChangeNotifier {
  late ApiClient api;

  List<String> interests = [];
  Set<String> sites = jobSites.toSet();
  int jobsPerSite = 20;
  bool remoteOnly = false;
  int minScore = 60;
  bool loaded = false;

  Future<void> load() async {
    final me = await api.get('/v1/me');
    final d = (me['defaults'] as Map).cast<String, dynamic>();
    interests = (d['interests'] as List? ?? const []).cast<String>();
    final s = (d['sites'] as List?)?.cast<String>();
    if (s != null && s.isNotEmpty) sites = s.toSet();
    jobsPerSite = d['jobsPerSite'] ?? 20;
    remoteOnly = d['remoteOnly'] ?? false;
    minScore = d['minScore'] ?? 60;
    loaded = true;
    notifyListeners();
  }

  void toggleSite(String site) {
    sites.contains(site) ? sites.remove(site) : sites.add(site);
    notifyListeners();
  }

  void setInterests(List<String> value) {
    interests = value.take(5).toList();
    notifyListeners();
  }

  Future<void> save() => api.patch('/v1/me', body: {
        'interests': interests, 'sites': sites.toList(), 'jobsPerSite': jobsPerSite,
        'remoteOnly': remoteOnly, 'minScore': minScore,
      });
}
