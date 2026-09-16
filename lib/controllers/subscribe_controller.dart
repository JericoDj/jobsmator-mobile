import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/models/subscription.dart';
import '../providers/subscription_provider.dart';

/// Paywall state: which plan is highlighted, busy, one error line.
class SubscribeController extends ChangeNotifier {
  SubscribeController(this._subs) : _selected = Plan.pro;

  final SubscriptionProvider _subs;

  Plan _selected; // Pro is highlighted by default; the user can pick Free.
  bool _busy = false;
  String? _error;

  Plan get selected => _selected;
  bool get busy => _busy;
  String? get error => _error;
  bool get alreadyPro => _subs.isPro;
  bool get canConfirm => !_busy && _selected != _subs.plan;

  void select(Plan plan) {
    _selected = plan;
    notifyListeners();
  }

  /// Returns true when the plan changed. Billing runs through the store
  /// purchase flow; the API records the result.
  Future<bool> confirm() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _subs.subscribe(_selected);
      return true;
    } catch (e) {
      _error = messageOf(e, fallback: "We couldn't complete that purchase. You haven't been charged.");
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
