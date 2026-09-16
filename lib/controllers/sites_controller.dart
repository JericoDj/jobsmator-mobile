import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/copy.dart';
import '../providers/preferences_provider.dart';
import '../providers/resume_provider.dart';
import '../providers/run_provider.dart';
import '../providers/subscription_provider.dart';

/// Step 3. Sites and limits, then one tap to start the run.
class SitesController extends ChangeNotifier {
  SitesController(this._prefs, this._resumes, this._runs, this._subs) {
    scheduleMicrotask(() {
      if (!_subs.loaded) _subs.load().catchError((_) {});
    });
  }

  final PreferencesProvider _prefs;
  final ResumeProvider _resumes;
  final RunProvider _runs;
  final SubscriptionProvider _subs;

  bool _starting = false;
  bool _saveToSheet = false;
  String? _error;

  bool get starting => _starting;
  bool get saveToSheet => _saveToSheet;
  String? get error => _error;
  bool get canStart => _prefs.sites.isNotEmpty && _prefs.interests.isNotEmpty && !_starting;
  bool get hasResume => _resumes.latest != null;

  /// Sites past the plan's limit are still selectable; the paywall explains.
  bool get overSiteLimit => _prefs.sites.length > _subs.plan.siteLimit;

  /// True when starting would hit the plan quota — the screen shows the paywall.
  bool get needsUpgrade => !_subs.canSearch || overSiteLimit || (_saveToSheet && !_subs.plan.sheets);
  int get searchesLeft => _subs.searchesLeft;
  String get planLabel => _subs.plan.label;
  int get siteLimit => _subs.plan.siteLimit;
  bool get sheetsAllowed => _subs.plan.sheets;

  void setSaveToSheet(bool on) {
    _saveToSheet = on;
    notifyListeners();
  }

  /// Saves preferences, starts the run, returns its id — or null with [error] set.
  Future<String?> start() async {
    final resume = _resumes.latest;
    if (resume == null) {
      _error = 'Upload a resume first.';
      notifyListeners();
      return null;
    }
    _starting = true;
    _error = null;
    notifyListeners();
    try {
      await _prefs.save().catchError((_) {}); // preferences are a convenience; never block the run on them
      final id = await _runs.start(
        resumeId: resume.id,
        interests: _prefs.interests,
        sites: _prefs.sites,
        jobsPerSite: _prefs.jobsPerSite,
        remoteOnly: _prefs.remoteOnly,
        minScore: _prefs.minScore,
        location: _prefs.location,
        saveToSheet: _saveToSheet,
      );
      _subs.noteSearchStarted();
      return id;
    } on ApiException catch (e) {
      _error = JmCopy.forError(e.code);
      return null;
    } catch (_) {
      _error = JmCopy.forError(null);
      return null;
    } finally {
      _starting = false;
      notifyListeners();
    }
  }
}
