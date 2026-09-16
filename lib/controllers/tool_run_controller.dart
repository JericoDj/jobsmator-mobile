import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/ai/ai_service.dart';
import '../core/models/tool.dart';
import '../providers/resume_provider.dart';
import '../providers/subscription_provider.dart';

/// One run of one tool: input → busy → result. Premium tools on Free
/// report [locked] so the screen can open the paywall instead of running.
class ToolRunController extends ChangeNotifier {
  ToolRunController(this.tool, this._ai, this._subs, this._resumes, {String? initialInput})
    : input = initialInput ?? '' {
    // Deferred: created during the screen's first build, and load() notifies.
    scheduleMicrotask(() {
      if (!_resumes.loaded) _resumes.load().catchError((_) {});
    });
  }

  final Tool tool;
  final AiService _ai;
  final SubscriptionProvider _subs;
  final ResumeProvider _resumes;

  String input;
  bool _busy = false;
  String? _result;
  String? _error;

  bool get busy => _busy;
  String? get result => _result;
  String? get error => _error;
  bool get locked => tool.premium && !_subs.isPro;

  Future<void> run() async {
    if (_busy || locked) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _result = await _ai.runTool(tool.id, input.trim());
    } catch (_) {
      _error = "That didn't go through. Try again in a moment.";
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void reset() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}
