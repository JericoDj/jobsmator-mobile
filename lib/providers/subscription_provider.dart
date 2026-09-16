import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/models/subscription.dart';

/// Plan + quota. Loaded from `/v1/me` (the `subscription` field); upgrading
/// goes through `/v1/billing/checkout`, which the store purchase flow will
/// call once in-app purchases are wired up.
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider(this._api);

  final ApiClient _api;

  Subscription _sub = const Subscription();
  bool _loaded = false;

  Subscription get current => _sub;
  Plan get plan => _sub.plan;
  bool get isPro => _sub.isPro;
  bool get canSearch => _sub.canSearch;
  int get searchesLeft => _sub.searchesLeft;
  bool get loaded => _loaded;

  Future<void> load() async {
    final me = await _api.get('/v1/me');
    _sub = Subscription.fromJson((me['subscription'] as Map? ?? const {}).cast<String, dynamic>());
    _loaded = true;
    notifyListeners();
  }

  /// Count a started run against the quota without waiting for a refetch.
  void noteSearchStarted() {
    _sub = _sub.copyWith(searchesUsed: _sub.searchesUsed + 1);
    notifyListeners();
  }

  Future<void> subscribe(Plan plan) async {
    final res = await _api.post('/v1/billing/checkout', body: {'plan': plan.name});
    _sub = Subscription.fromJson((res['subscription'] as Map? ?? {'plan': plan.name}).cast<String, dynamic>());
    notifyListeners();
  }

  Future<void> cancel() => subscribe(Plan.free);
}
