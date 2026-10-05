import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:intl/intl.dart';

import '../config.dart';
import '../models/subscription.dart';

/// Thin wrapper over RevenueCat's `purchases_flutter`.
///
/// Every call is a no-op (or returns a "nothing happened" result) until
/// [configure] actually turns the SDK on — which only happens outside
/// preview builds and only when this platform has a dart-define key. That
/// lets every call site call through unconditionally and fall back to the
/// mock `/v1/billing/checkout` flow when [configured] is false, instead of
/// littering `if (AppConfig.preview)` checks everywhere.
abstract final class StoreBilling {
  static bool _configured = false;
  static bool get configured => _configured;

  static String get _apiKey => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => AppConfig.rcApiKeyIos,
    TargetPlatform.android => AppConfig.rcApiKeyAndroid,
    _ => '',
  };

  /// Call once at startup, after Firebase. Silently does nothing in
  /// preview builds or when no key is set for this platform.
  static Future<void> configure() async {
    if (AppConfig.preview || _configured) return;
    final key = _apiKey;
    if (key.isEmpty) return;
    try {
      await Purchases.configure(PurchasesConfiguration(key));
      _configured = true;
    } catch (e) {
      if (kDebugMode) debugPrint('StoreBilling.configure failed: $e');
    }
  }

  /// Links the store identity to our Firebase uid so RevenueCat and our
  /// backend agree on who bought what.
  static Future<void> logIn(String uid) async {
    if (!_configured) return;
    try {
      await Purchases.logIn(uid);
    } catch (e) {
      if (kDebugMode) debugPrint('StoreBilling.logIn failed: $e');
    }
  }

  static Future<void> logOut() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      if (kDebugMode) debugPrint('StoreBilling.logOut failed: $e');
    }
  }

  /// The current offering's monthly/yearly packages as paywall offers, with
  /// the store's localised prices. Null when the store hasn't been asked
  /// (not configured, or no offering yet) so the caller can show fallbacks.
  static Future<List<ProOffer>?> offers() async {
    if (!_configured) return null;
    final packages = (await Purchases.getOfferings()).current?.availablePackages ?? const <Package>[];
    if (packages.isEmpty) return null;
    final monthly = _find(packages, ProTerm.monthly);
    final yearly = _find(packages, ProTerm.yearly);
    final out = <ProOffer>[];
    if (monthly != null) out.add(ProOffer(term: ProTerm.monthly, price: monthly.storeProduct.priceString));
    if (yearly != null) {
      final y = yearly.storeProduct;
      // Whole units when it divides cleanly (₱167), cents otherwise ($2.50).
      final monthlyPrice = y.price / 12;
      final wholeish = (monthlyPrice - monthlyPrice.roundToDouble()).abs() < 0.05 || monthlyPrice >= 100;
      final fmt = NumberFormat.simpleCurrency(name: y.currencyCode, decimalDigits: wholeish ? 0 : 2);
      final perMonth = fmt.format(monthlyPrice);
      final m = monthly?.storeProduct;
      final savings = m != null && m.price > 0 ? 'Save ${((1 - y.price / (m.price * 12)) * 100).round()}%' : null;
      out.add(ProOffer(term: ProTerm.yearly, price: y.priceString, perMonth: perMonth, savings: savings));
    }
    return out.isEmpty ? null : out;
  }

  /// Matches a package to a term by RevenueCat's package type first, then
  /// by the product id (`…_monthly` / `…_yearly`) for custom packages.
  static Package? _find(List<Package> packages, ProTerm term) {
    final type = term == ProTerm.monthly ? PackageType.monthly : PackageType.annual;
    final byType = packages.where((p) => p.packageType == type).firstOrNull;
    if (byType != null) return byType;
    final needle = term == ProTerm.monthly ? 'monthly' : 'year';
    return packages.where((p) => p.storeProduct.identifier.toLowerCase().contains(needle)).firstOrNull;
  }

  /// Buys the `pro` entitlement for [term]. Returns whether it's active
  /// afterwards; a user-cancelled purchase resolves to `false` rather than
  /// throwing. Any other failure (network, misconfigured offering…)
  /// rethrows as an [Exception] with a message safe to surface to the user.
  static Future<bool> purchasePro(ProTerm term) async {
    if (!_configured) return false;
    final offerings = await Purchases.getOfferings();
    final packages = offerings.current?.availablePackages ?? const <Package>[];
    final pkg = _find(packages, term) ?? packages.firstOrNull;
    if (pkg == null) {
      throw Exception('Pro is not available for purchase right now.');
    }
    try {
      final result = await Purchases.purchase(PurchaseParams.package(pkg));
      return result.customerInfo.entitlements.active.containsKey('pro');
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      throw Exception("We couldn't complete that purchase. You haven't been charged.");
    }
  }

  /// Opens the App Store / Play Store subscription screen. Cancelling has to
  /// happen there — clearing our own record would leave the store still
  /// billing, so this is what "switch to Free" does for a paid subscriber.
  /// RevenueCat hands back the right deep link per store; the plain store
  /// URLs are the fallback when it has none (e.g. no active subscription).
  static Future<void> manageSubscriptions() async {
    String? url;
    if (_configured) {
      try {
        url = (await Purchases.getCustomerInfo()).managementURL;
      } catch (e) {
        if (kDebugMode) debugPrint('StoreBilling.manageSubscriptions lookup failed: $e');
      }
    }
    url ??= defaultTargetPlatform == TargetPlatform.android
        ? 'https://play.google.com/store/account/subscriptions'
        : 'https://apps.apple.com/account/subscriptions';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// `Purchases.restorePurchases()` — for the "Restore purchases" button.
  static Future<bool> restore() async {
    if (!_configured) return false;
    final info = await Purchases.restorePurchases();
    return info.entitlements.active.containsKey('pro');
  }
}
