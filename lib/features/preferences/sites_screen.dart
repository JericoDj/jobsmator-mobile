import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/copy.dart';
import '../../controllers/sites_controller.dart';
import '../../core/models/user_defaults.dart';
import '../../providers/preferences_provider.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/selection_chip.dart';
import '../shared/widgets/step_header.dart';

/// Step 3. All ten sites on by default, jobs-per-site at 20. One tap to start.
class SitesScreen extends StatelessWidget {
  const SitesScreen({super.key});

  /// Plan limits are enforced here, not by disabling the button: the paywall
  /// explains what changes, and if the user upgrades we start right away.
  Future<void> _start(BuildContext context) async {
    final ctrl = context.read<SitesController>();
    if (ctrl.needsUpgrade) {
      await context.push(AppRoutes.subscribe);
      if (!context.mounted || ctrl.needsUpgrade) return;
    }
    final id = await ctrl.start();
    if (id != null && context.mounted) context.go(AppRoutes.run(id));
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SitesController>();
    final prefs = context.watch<PreferencesProvider>();
    final c = context.jm;
    final allOn = prefs.sites.length == jobSites.length;

    return JmPage(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go(AppRoutes.interests))),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ctrl.error != null) ...[ErrorLine(ctrl.error!), const SizedBox(height: JmSpace.x3)],
          PrimaryButton(
            label: 'Find matching jobs',
            busyLabel: 'Starting search…',
            busy: ctrl.starting,
            large: true,
            icon: Icons.search_rounded,
            onPressed: ctrl.canStart ? () => _start(context) : null,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepHeader(
            step: 3,
            title: 'Where should we look?',
            lede: "All ten sites are on. It's faster to remove one than to add it later.",
          ),
          const SizedBox(height: JmSpace.x6),
          Row(
            children: [
              Expanded(child: JmLabel('Job sites · ${prefs.sites.length} of ${jobSites.length}', color: c.muted)),
              TextButton(
                onPressed: () => prefs.setAllSites(!allOn),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(allOn ? 'Clear all' : 'Select all'),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x2),
          Wrap(
            spacing: JmSpace.x2,
            runSpacing: JmSpace.x2,
            children: [
              for (final s in jobSites)
                SelectionChip(label: s, selected: prefs.sites.contains(s), onChanged: (_) => prefs.toggleSite(s)),
            ],
          ),
          const SizedBox(height: JmSpace.x8),
          _LimitsCard(prefs: prefs, ctrl: ctrl),
          const SizedBox(height: JmSpace.x6),
          Text(
            'Searches take 30–90 seconds. '
            '${ctrl.planLabel}: ${JmCopy.plural(ctrl.searchesLeft, 'search', 'searches')} left'
            '${ctrl.overSiteLimit ? ' · up to ${ctrl.siteLimit} sites on ${ctrl.planLabel}' : ''}.',
            style: context.type.meta.copyWith(color: ctrl.needsUpgrade ? c.warn : null),
          ),
        ],
      ),
    );
  }
}

class _LimitsCard extends StatelessWidget {
  const _LimitsCard({required this.prefs, required this.ctrl});
  final PreferencesProvider prefs;
  final SitesController ctrl;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final tabular = context.type.stat.copyWith(fontSize: 20);
    return Container(
      padding: const EdgeInsets.fromLTRB(JmSpace.x4, JmSpace.x4, JmSpace.x4, JmSpace.x2),
      decoration: BoxDecoration(color: c.surface, borderRadius: JmRadius.lgR),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JmLabel('Limits', color: c.muted),
          const SizedBox(height: JmSpace.x3),
          _SliderRow(
            label: 'Jobs per site',
            hint: 'Between 5 and 50. More takes longer.',
            value: prefs.jobsPerSite.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            display: Text('${prefs.jobsPerSite}', style: tabular),
            onChanged: (v) => prefs.setJobsPerSite(v.round()),
          ),
          _SliderRow(
            label: 'Minimum score',
            hint: 'Anything below this is a weaker match and collapsed.',
            value: prefs.minScore.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            display: Text('${prefs.minScore}', style: tabular),
            onChanged: (v) => prefs.setMinScore(v.round()),
          ),
          const Divider(height: JmSpace.x4),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('Remote only', style: context.type.uiStrong),
            subtitle: Text('Skip listings that need you on site.', style: context.type.meta),
            value: prefs.remoteOnly,
            onChanged: prefs.setRemoteOnly,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('Save to Google Sheets', style: context.type.uiStrong),
            subtitle: Text(
              ctrl.sheetsAllowed
                  ? 'Adds every match to "JobsMator — ${prefs.profile?.firstName ?? 'you'}".'
                  : 'Pro feature — turning it on opens the plans.',
              style: context.type.meta,
            ),
            value: ctrl.saveToSheet,
            onChanged: ctrl.setSaveToSheet,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.hint,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });
  final String label, hint;
  final double value, min, max;
  final int divisions;
  final Widget display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.type.uiStrong),
                Text(hint, style: context.type.meta),
              ],
            ),
          ),
          const SizedBox(width: 12),
          display,
        ],
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(padding: const EdgeInsets.symmetric(vertical: 8)),
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          label: '${value.round()}',
        ),
      ),
    ],
  );
}
