import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/billing/store_billing.dart';
import '../core/models/subscription.dart';
import '../providers/subscription_provider.dart';

/// Paywall state: which plan is highlighted, busy, one error line.
class SubscribeController extends ChangeNotifier {
  SubscribeController(this._subs) : _selected = Plan.pro;

  final SubscriptionProvider _subs;

  Plan _selected; // Pro is highlighted by default; the user can pick Free.
  ProTerm _term = ProTerm.yearly; // Best value first; the user can switch to monthly.
  List<ProOffer> _offers = fallbackProOffers;
  bool _busy = false;
  String? _error;

  Plan get selected => _selected;
  ProTerm get term => _term;
  List<ProOffer> get offers => _offers;
  ProOffer get offer => _offers.firstWhere((o) => o.term == _term, orElse: () => _offers.first);
  bool get busy => _busy;
  String? get error => _error;
  bool get alreadyPro => _subs.isPro;

  /// Pro that came from an App Store / Play subscription. Switching such a
  /// user to Free is the store's job, not ours — see [confirm].
  bool get proFromStore => _subs.isPro && _subs.current.source == SubscriptionSource.revenuecat;
  bool get canConfirm => !_busy && _selected != _subs.plan;

  /// The store button only makes sense while RevenueCat is actually wired
  /// up; otherwise the screen quietly falls back to the mock checkout.
  bool get usesStoreBilling => StoreBilling.configured;

  void select(Plan plan) {
    _selected = plan;
    notifyListeners();
  }

  /// Picking a term also selects Pro — tapping "Yearly" means "I want that".
  void selectTerm(ProTerm term) {
    _term = term;
    _selected = Plan.pro;
    notifyListeners();
  }

  /// Swaps the fallback prices for the store's localised ones once the
  /// offering has loaded. Quietly keeps the fallbacks on any failure.
  Future<void> loadOffers() async {
    try {
      final store = await StoreBilling.offers();
      if (store == null) return;
      _offers = store;
      if (!_offers.any((o) => o.term == _term)) _term = _offers.first.term;
      notifyListeners();
    } catch (_) {}
  }

  /// Returns true when the plan changed. Goes through the store purchase
  /// flow when RevenueCat is configured (then syncs the result with the
  /// backend); falls back to the mock `/v1/billing/checkout` otherwise —
  /// which is all that preview builds and dev-without-keys ever have.
  Future<bool> confirm() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if (StoreBilling.configured && _selected == Plan.pro) {
        final active = await StoreBilling.purchasePro(_term);
        if (!active) return false; // user cancelled; not an error
        await _subs.syncWithStore();
        return true;
      }
      if (_selected == Plan.free && proFromStore) {
        // Hand off to the store: cancelling there is what actually stops the
        // billing, and the next sync will bring the plan down by itself.
        await StoreBilling.manageSubscriptions();
        return false;
      }
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

  /// "Restore purchases" — re-links whatever this store account already
  /// owns and re-syncs the backend. Returns true when Pro came back active.
  Future<bool> restore() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if (!StoreBilling.configured) {
        _error = 'Nothing to restore.';
        return false;
      }
      final active = await StoreBilling.restore();
      await _subs.syncWithStore();
      return active;
    } catch (e) {
      _error = messageOf(e, fallback: "Couldn't restore purchases.");
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> redeemVoucher(String code) async {
    if (code.isEmpty) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _subs.redeemVoucher(code);
      return true;
    } catch (e) {
      _error = messageOf(e, fallback: "Couldn't redeem voucher.");
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
