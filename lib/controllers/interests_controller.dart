import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/models/user_defaults.dart';
import '../providers/preferences_provider.dart';

/// Step 2. Edits the interest list held by [PreferencesProvider].
/// Interests are pre-filled from saved defaults so the user edits, not types.
class InterestsController extends ChangeNotifier {
  InterestsController(this._prefs) {
    scheduleMicrotask(() {
      if (!_prefs.loaded) _prefs.load().catchError((_) {});
    });
  }

  final PreferencesProvider _prefs;

  String? _hint;
  String? get hint => _hint;

  bool get canContinue => _prefs.interests.isNotEmpty;
  int get remaining => maxInterests - _prefs.interests.length;

  /// Returns true when the chip was added (so the field can clear).
  bool add(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    if (_prefs.interests.length >= maxInterests) {
      _set('Five is the limit — remove one to add another.');
      return false;
    }
    if (_prefs.interests.any((i) => i.toLowerCase() == v.toLowerCase())) {
      _set('$v is already on the list.');
      return false;
    }
    _prefs.addInterest(v);
    _set(null);
    return true;
  }

  void remove(String value) {
    _prefs.removeInterest(value);
    _set(null);
  }

  void _set(String? hint) {
    _hint = hint;
    notifyListeners();
  }
}
