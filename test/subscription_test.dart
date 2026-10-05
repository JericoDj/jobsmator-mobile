import 'package:flutter_test/flutter_test.dart';
import 'package:jobsmator_mobile/core/models/subscription.dart';

void main() {
  test('free plan: one search a day, three sites, no sheets', () {
    const s = Subscription();
    expect(s.plan, Plan.free);
    expect(s.searchesLeft, 1);
    expect(s.canSearch, isTrue);
    expect(s.copyWith(searchesUsed: 1).canSearch, isFalse);
    expect(Plan.free.siteLimit, 3);
    expect(Plan.free.sheets, isFalse);
    expect(s.periodLabel, 'today');
  });

  // The API is now the source of truth for searchLimit/period, not the
  // client — this covers a plan (Pro, 5/day) that's fully used up.
  test('pro plan parses from the API and never goes negative', () {
    final s = Subscription.fromJson({
      'plan': 'pro',
      'searchesUsed': 9,
      'searchLimit': 5,
      'period': 'day',
      'renewsAt': '2026-10-16T00:00:00Z',
      'source': 'revenuecat',
      'entitlementActive': true,
    });
    expect(s.isPro, isTrue);
    expect(s.searchesLeft, 0);
    expect(s.renewsAt, isNotNull);
    expect(s.periodLabel, 'today');
    expect(s.source, SubscriptionSource.revenuecat);
    expect(s.entitlementActive, isTrue);
  });

  test('unknown plan falls back to free', () {
    expect(Subscription.fromJson(const {}).plan, Plan.free);
  });

  test('pro plan without searchLimit/period falls back to 5/day', () {
    // An older API build (or a stale cache) might not send the new fields
    // yet — the client must not show "of 0" while that rolls out.
    final s = Subscription.fromJson({'plan': 'pro', 'searchesUsed': 2});
    expect(s.searchLimit, 5);
    expect(s.period, 'day');
    expect(s.searchesLeft, 3);
    expect(s.source, SubscriptionSource.none);
    expect(s.entitlementActive, isFalse);
  });
}
