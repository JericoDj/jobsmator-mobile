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
    expect(Plan.free.periodLabel, 'today');
  });

  test('pro plan parses from the API and never goes negative', () {
    final s = Subscription.fromJson({'plan': 'pro', 'searchesUsed': 9, 'renewsAt': '2026-10-16T00:00:00Z'});
    expect(s.isPro, isTrue);
    expect(s.searchesLeft, 0);
    expect(s.renewsAt, isNotNull);
    expect(Plan.pro.searchLimit, 5);
    expect(Plan.pro.sheets, isTrue);
  });

  test('unknown plan falls back to free', () {
    expect(Subscription.fromJson(const {}).plan, Plan.free);
  });
}
