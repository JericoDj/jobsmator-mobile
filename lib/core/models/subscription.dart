/// Plans. `searchLimit`/`period` are no longer hardcoded here — the API is
/// the source of truth (see [Subscription]) so RevenueCat/voucher/manual
/// grants can change them without a client release. What's left on the
/// enum is purely cosmetic or not yet sent by the API.
enum Plan {
  free,
  pro;

  String get label => switch (this) {
    free => 'Free',
    pro => 'Pro',
  };

  int get siteLimit => switch (this) {
    free => 3,
    pro => 10,
  };
  bool get sheets => this == pro;
}

/// Where the current plan came from. `none` for plain Free.
enum SubscriptionSource {
  none,
  voucher,
  revenuecat,
  manual;

  static SubscriptionSource parse(String? v) =>
      SubscriptionSource.values.firstWhere((s) => s.name == v, orElse: () => SubscriptionSource.none);
}

class Subscription {
  const Subscription({
    this.plan = Plan.free,
    this.searchesUsed = 0,
    this.searchLimit = 1,
    this.period = 'day',
    this.renewsAt,
    this.source = SubscriptionSource.none,
    this.entitlementActive = false,
  });

  final Plan plan;

  /// Searches used in the current period (a day on both plans).
  final int searchesUsed;

  /// Searches allowed per [period]. Backend-driven; today's numbers are
  /// free 1/day, pro 5/day, but the client never hardcodes that any more.
  final int searchLimit;

  /// "day" or "hour" — whatever period the backend is counting against.
  final String period;
  final DateTime? renewsAt;

  /// How the current plan was granted — a store purchase, a voucher, a
  /// manual grant, or nothing (plain Free).
  final SubscriptionSource source;

  /// True when [plan] came from RevenueCat and the entitlement hasn't
  /// expired. Drives whether "Restore purchases" is worth showing as active.
  final bool entitlementActive;

  int get searchesLeft => (searchLimit - searchesUsed).clamp(0, searchLimit);
  bool get canSearch => searchesLeft > 0;
  bool get isPro => plan == Plan.pro;

  String get periodLabel => switch (period) {
    'hour' => 'this hour',
    _ => 'today',
  };

  factory Subscription.fromJson(Map<String, dynamic> j) {
    final plan = Plan.values.byName(j['plan'] ?? 'free');
    // Fall back to today's numbers when an older API build hasn't sent
    // searchLimit/period yet, so the app never shows a bogus "of 0".
    final fallbackLimit = plan == Plan.pro ? 5 : 1;
    const fallbackPeriod = 'day';
    return Subscription(
      plan: plan,
      searchesUsed: j['searchesUsed'] ?? 0,
      searchLimit: j['searchLimit'] ?? fallbackLimit,
      period: j['period'] ?? fallbackPeriod,
      renewsAt: j['renewsAt'] == null ? null : DateTime.tryParse(j['renewsAt']),
      source: SubscriptionSource.parse(j['source'] as String?),
      entitlementActive: j['entitlementActive'] == true,
    );
  }

  Subscription copyWith({
    Plan? plan,
    int? searchesUsed,
    int? searchLimit,
    String? period,
    DateTime? renewsAt,
    SubscriptionSource? source,
    bool? entitlementActive,
  }) => Subscription(
    plan: plan ?? this.plan,
    searchesUsed: searchesUsed ?? this.searchesUsed,
    searchLimit: searchLimit ?? this.searchLimit,
    period: period ?? this.period,
    renewsAt: renewsAt ?? this.renewsAt,
    source: source ?? this.source,
    entitlementActive: entitlementActive ?? this.entitlementActive,
  );
}

/// How long one Pro purchase lasts. Mirrors the two store products
/// (`jobsmator_pro_monthly`, `jobsmator_pro_yearly`).
enum ProTerm {
  monthly,
  yearly;

  String get label => switch (this) { monthly => 'Monthly', yearly => 'Yearly' };
  String get unit => switch (this) { monthly => 'month', yearly => 'year' };
}

/// One purchasable Pro option as the paywall shows it. Comes from the
/// store (localised price) when RevenueCat is configured, else from
/// [fallbackProOffers] so the screen still reads right in previews.
class ProOffer {
  const ProOffer({required this.term, required this.price, this.perMonth, this.savings});
  final ProTerm term;
  /// Localised, e.g. "₱299".
  final String price;
  /// Yearly only: what it works out to per month, e.g. "₱167".
  final String? perMonth;
  /// Yearly only: "Save 44%".
  final String? savings;
}

/// Store prices shown before the store has answered (or without RevenueCat).
/// Billing itself goes through the platform store; the API only learns the
/// resulting plan.
const fallbackProOffers = [
  ProOffer(term: ProTerm.monthly, price: '₱299'),
  ProOffer(term: ProTerm.yearly, price: '₱1,999', perMonth: '₱167', savings: 'Save 44%'),
];
