/// Plans. Limits are what the app enforces for UX; the API's rate limit
/// (5 runs / hour) is the hard ceiling either way.
enum Plan {
  free,
  pro;

  String get label => switch (this) {
    free => 'Free',
    pro => 'Pro',
  };

  /// Searches allowed per period.
  int get searchLimit => switch (this) {
    free => 1,
    pro => 5,
  };
  String get period => switch (this) {
    free => 'day',
    pro => 'hour',
  };
  String get periodLabel => switch (this) {
    free => 'today',
    pro => 'this hour',
  };
  int get siteLimit => switch (this) {
    free => 3,
    pro => 10,
  };
  bool get sheets => this == pro;
}

class Subscription {
  const Subscription({this.plan = Plan.free, this.searchesUsed = 0, this.renewsAt});

  final Plan plan;

  /// Searches used in the current period (day for Free, hour for Pro).
  final int searchesUsed;
  final DateTime? renewsAt;

  int get searchesLeft => (plan.searchLimit - searchesUsed).clamp(0, plan.searchLimit);
  bool get canSearch => searchesLeft > 0;
  bool get isPro => plan == Plan.pro;

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    plan: Plan.values.byName(j['plan'] ?? 'free'),
    searchesUsed: j['searchesUsed'] ?? 0,
    renewsAt: j['renewsAt'] == null ? null : DateTime.tryParse(j['renewsAt']),
  );

  Subscription copyWith({Plan? plan, int? searchesUsed, DateTime? renewsAt}) => Subscription(
    plan: plan ?? this.plan,
    searchesUsed: searchesUsed ?? this.searchesUsed,
    renewsAt: renewsAt ?? this.renewsAt,
  );
}

/// Store price shown on the paywall. Billing itself goes through the
/// platform store; the API only learns the resulting plan.
const proPriceLabel = '₱299';
const proPricePeriod = 'month';
