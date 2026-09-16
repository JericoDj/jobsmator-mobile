import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this install has been through the welcome tour. Read once at
/// start so the router can decide the first screen without a flash.
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider(this._prefs) : _seen = _prefs.getBool(_key) ?? false;

  static const _key = 'onboarding.seen';
  final SharedPreferences _prefs;

  bool _seen;
  bool get seen => _seen;

  Future<void> markSeen() async {
    if (_seen) return;
    _seen = true;
    notifyListeners();
    await _prefs.setBool(_key, true);
  }

  /// For the profile screen's "Show the tour again".
  Future<void> reset() async {
    _seen = false;
    notifyListeners();
    await _prefs.remove(_key);
  }
}
