import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme/theme.dart';
import '../../core/copy.dart';
import '../../providers/job_catalog_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/run_provider.dart';
import '../../providers/subscription_provider.dart';
import '../shared/widgets/jm_ticker.dart';

/// The navy strip that runs under the notch on every tab: short headlines
/// about what JobsMator is doing for you, scrolling past like a news ticker.
/// Reads the app-level providers directly so it needs no controller.
class AnnouncementBar extends StatelessWidget {
  const AnnouncementBar({super.key});

  static List<String> items({
    required JobCatalogProvider catalog,
    required RunProvider runs,
    required PreferencesProvider prefs,
    required SubscriptionProvider subs,
  }) {
    final out = <String>[];
    if (runs.current?.isActive ?? false) out.add('Search running now');
    final matches = catalog.newMatches;
    if (matches > 0) out.add('$matches new ${matches == 1 ? 'match' : 'matches'}');

    final next = prefs.automations.where((a) => a.enabled && a.nextRunAt != null).map((a) => a.nextRunAt!).toList()
      ..sort();
    if (next.isNotEmpty) out.add('Next auto run ${JmCopy.relativeFuture(next.first)}');

    out.add('${JmCopy.plural(subs.searchesLeft, 'search', 'searches')} left ${subs.plan.periodLabel}');

    for (final r in runs.history.where((r) => !r.isActive).take(3)) {
      final when = JmCopy.relative(r.finishedAt ?? r.startedAt);
      out.add(r.isFailed ? 'Search failed $when' : '${r.stats?.recommended ?? 0} matches found $when');
    }
    final running = prefs.automationsRunning;
    if (running > 0) out.add('$running automation${running == 1 ? '' : 's'} running');
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final list = items(
      catalog: context.watch<JobCatalogProvider>(),
      runs: context.watch<RunProvider>(),
      prefs: context.watch<PreferencesProvider>(),
      subs: context.watch<SubscriptionProvider>(),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: JmColors.navy,
        child: SafeArea(
          bottom: false,
          child: JmTicker(items: list),
        ),
      ),
    );
  }
}
