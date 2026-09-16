import 'package:flutter/material.dart';

import '../providers/preferences_provider.dart';

/// Form state for the job-preferences settings page: the two text fields
/// and a saving flag. The values themselves live in [PreferencesProvider].
class JobPreferencesController extends ChangeNotifier {
  JobPreferencesController(this._prefs)
    : salary = TextEditingController(text: _prefs.defaults.salaryMin?.toString() ?? ''),
      location = TextEditingController(text: _prefs.defaults.location);

  final PreferencesProvider _prefs;
  final TextEditingController salary, location;

  bool _saving = false;
  bool get saving => _saving;

  /// Returns true when saved; the screen shows the toast either way.
  Future<bool> save() async {
    _prefs.setSalaryMin(int.tryParse(salary.text.replaceAll(RegExp(r'[^0-9]'), '')));
    _prefs.setLocation(location.text.isEmpty ? 'Philippines' : location.text);
    _saving = true;
    notifyListeners();
    try {
      await _prefs.save();
      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    salary.dispose();
    location.dispose();
    super.dispose();
  }
}
