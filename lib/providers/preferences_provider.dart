import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/models/app_user.dart';
import '../core/models/automation.dart';
import '../core/models/career_profile.dart';
import '../core/models/user_defaults.dart';

/// Search preferences — interests, sites and limits. Loaded from `/v1/me`,
/// edited on the interests and sites screens, saved when a run starts.
class PreferencesProvider extends ChangeNotifier {
  PreferencesProvider(this._api);

  final ApiClient _api;

  UserDefaults _defaults = const UserDefaults();
  AppUser? _profile;
  CareerProfile _career = const CareerProfile();
  List<Automation> _automations = const [];
  AutomationSettings _settings = const AutomationSettings();
  String? _sheetId;
  bool _loaded = false;

  UserDefaults get defaults => _defaults;
  List<String> get interests => _defaults.interests;
  List<String> get sites => _defaults.sites;
  int get jobsPerSite => _defaults.jobsPerSite;
  int get minScore => _defaults.minScore;
  bool get remoteOnly => _defaults.remoteOnly;
  String get location => _defaults.location;
  bool get loaded => _loaded;
  String? get sheetId => _sheetId;
  AppUser? get profile => _profile;
  CareerProfile get career => _career;
  List<Automation> get automations => _automations;
  AutomationSettings get settings => _settings;
  int get automationsRunning => _automations.where((a) => a.enabled).length;

  Future<void> load() async {
    final me = await _api.get('/v1/me');
    _defaults = UserDefaults.fromJson((me['defaults'] as Map? ?? const {}).cast<String, dynamic>());
    _profile = AppUser(uid: me['id'] ?? '', email: me['email'], displayName: me['displayName']);
    _sheetId = me['sheetId'];
    _career = CareerProfile.fromJson((me['profile'] as Map? ?? const {}).cast<String, dynamic>());
    _automations = (me['automations'] as List? ?? const [])
        .map((a) => Automation.fromJson((a as Map).cast<String, dynamic>()))
        .toList();
    _settings = AutomationSettings.fromJson((me['settings'] as Map? ?? const {}).cast<String, dynamic>());
    _loaded = true;
    notifyListeners();
  }

  void setSalaryMin(int? value) => _update(_defaults.copyWith(salaryMin: value, clearSalary: value == null));
  void setLocation(String value) => _update(_defaults.copyWith(location: value.trim()));
  void setWorkMode(WorkMode mode) => _update(_defaults.copyWith(workMode: mode, remoteOnly: mode == WorkMode.remote));
  void setEmploymentType(EmploymentType type) => _update(_defaults.copyWith(employmentType: type));

  Future<void> toggleAutomation(Automation a, bool enabled) async {
    _automations = [for (final x in _automations) x.id == a.id ? x.copyWith(enabled: enabled) : x];
    notifyListeners();
    try {
      await _api.patch('/v1/automations/${a.id}', body: {'enabled': enabled});
    } catch (_) {
      _automations = [for (final x in _automations) x.id == a.id ? a : x];
      notifyListeners();
      rethrow;
    }
  }

  /// Schedule a search. [hour]/[minute] are the user's local time; the
  /// device's UTC offset goes along so the server fires at that wall clock.
  Future<Automation> createAutomation({
    required String resumeId,
    required List<String> interests,
    required List<String> sites,
    required String frequency,
    required int hour,
    required int minute,
    int? weekday,
    String? name,
  }) async {
    final res = await _api.post(
      '/v1/automations',
      body: {
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        'resumeId': resumeId,
        'interests': interests,
        'sites': sites,
        'jobsPerSite': _defaults.jobsPerSite,
        'frequency': frequency,
        'hour': hour,
        'minute': minute,
        'weekday': ?weekday,
        'tzOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
      },
    );
    final a = Automation.fromJson(res);
    _automations = [a, ..._automations];
    notifyListeners();
    return a;
  }

  Future<void> deleteAutomation(Automation a) async {
    final before = _automations;
    _automations = [for (final x in _automations) if (x.id != a.id) x];
    notifyListeners();
    try {
      await _api.delete('/v1/automations/${a.id}');
    } catch (_) {
      _automations = before;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSettings(AutomationSettings next) async {
    final before = _settings;
    _settings = next;
    notifyListeners();
    try {
      await _api.patch('/v1/me', body: {'settings': next.toJson()});
    } catch (_) {
      _settings = before;
      notifyListeners();
      rethrow;
    }
  }

  bool addInterest(String value) {
    final v = value.trim();
    if (v.isEmpty || interests.length >= maxInterests) return false;
    if (interests.any((i) => i.toLowerCase() == v.toLowerCase())) return false;
    _update(_defaults.copyWith(interests: [...interests, v]));
    return true;
  }

  void removeInterest(String value) =>
      _update(_defaults.copyWith(interests: interests.where((i) => i != value).toList()));

  void toggleSite(String site) {
    final next = sites.contains(site) ? sites.where((s) => s != site).toList() : [...sites, site];
    _update(_defaults.copyWith(sites: next));
  }

  void setAllSites(bool on) => _update(_defaults.copyWith(sites: on ? jobSites : const []));
  void setJobsPerSite(int n) => _update(_defaults.copyWith(jobsPerSite: n.clamp(5, 50)));
  void setMinScore(int n) => _update(_defaults.copyWith(minScore: n.clamp(0, 100)));
  void setRemoteOnly(bool on) => _update(_defaults.copyWith(remoteOnly: on));

  Future<void> save() => _api.patch('/v1/me', body: _defaults.toJson());

  void _update(UserDefaults next) {
    _defaults = next;
    notifyListeners();
  }
}
