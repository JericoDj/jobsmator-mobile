import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/copy.dart';
import '../../core/models/automation.dart';
import '../../providers/preferences_provider.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/jm_toast.dart';
import '../shared/widgets/selection_chip.dart';
import 'widgets_rows.dart';

/// Schedules, notifications and how the assistant writes.
class AutomationSettingsScreen extends StatelessWidget {
  const AutomationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final s = prefs.settings;
    final c = context.jm;

    void update(AutomationSettings next) => prefs.updateSettings(next).catchError((_) {
      if (context.mounted) showJmToast(context, title: "Couldn't save that", tone: ToastTone.error);
    });

    return JmPage(
      appBar: AppBar(title: const Text('Automation')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsGroup(
            label: 'Schedules',
            trailing: TextButton.icon(
              onPressed: () => context.push(AppRoutes.schedule),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: c.oceanDeep,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
            children: [
              if (prefs.automations.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('No schedules yet.', style: context.type.meta),
                )
              else
                for (final a in prefs.automations)
                  // Long-press a schedule to delete it.
                  GestureDetector(
                    onLongPress: () => _confirmDelete(context, prefs, a),
                    child: SettingsSwitch(
                      label: a.name,
                      subtitle: a.enabled
                          ? '${a.schedule}${a.nextRunAt == null ? '' : ' · next ${JmCopy.relativeFuture(a.nextRunAt!)}'}'
                          : 'Paused · ${a.schedule}',
                      value: a.enabled,
                      onChanged: (v) => prefs.toggleAutomation(a, v).catchError((_) {
                        if (!context.mounted) return;
                        showJmToast(context, title: "Couldn't update the schedule", tone: ToastTone.error);
                      }),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: JmSpace.x3),
          Text(
            'Scheduled searches count against your plan the same as manual ones. Long-press one to delete it.',
            style: context.type.meta,
          ),
          const SizedBox(height: JmSpace.x6),
          SettingsGroup(
            label: 'Notifications',
            children: [
              SettingsSwitch(
                label: 'New strong matches',
                subtitle: 'As soon as a scheduled search finds one.',
                value: s.notifyNewMatches,
                onChanged: (v) => update(s.copyWith(notifyNewMatches: v)),
              ),
              SettingsSwitch(
                label: 'Application reminders',
                subtitle: 'A nudge when a saved job has been sitting for 3 days.',
                value: s.notifyApplications,
                onChanged: (v) => update(s.copyWith(notifyApplications: v)),
              ),
              SettingsSwitch(
                label: 'Daily digest',
                subtitle: 'One summary at ${s.digestHour}:00 instead of individual alerts.',
                value: s.dailyDigest,
                onChanged: (v) => update(s.copyWith(dailyDigest: v)),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x6),
          JmLabel('AI preferences', color: c.muted),
          const SizedBox(height: JmSpace.x2),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: JmRadius.lgR,
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Writing tone', style: context.type.ui),
                const SizedBox(height: 2),
                Text('Used for cover letters, emails and interview answers.', style: context.type.meta),
                const SizedBox(height: JmSpace.x3),
                Wrap(
                  spacing: JmSpace.x2,
                  runSpacing: JmSpace.x2,
                  children: [
                    for (final t in AutomationSettings.tones)
                      SelectionChip(
                        label: t,
                        selected: s.aiTone == t,
                        onChanged: (_) => update(s.copyWith(aiTone: t)),
                      ),
                  ],
                ),
                const Divider(height: JmSpace.x6),
                SettingsSwitch(
                  label: 'Draft applications automatically',
                  subtitle: 'Prepare an email for every new strong match. Nothing is sent without you.',
                  value: s.autoApplyDrafts,
                  onChanged: (v) => update(s.copyWith(autoApplyDrafts: v)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, PreferencesProvider prefs, Automation a) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this schedule?'),
      content: Text(a.name),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: context.jm.danger),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (yes != true || !context.mounted) return;
  prefs.deleteAutomation(a).catchError((_) {
    if (context.mounted) showJmToast(context, title: "Couldn't delete the schedule", tone: ToastTone.error);
  });
}
