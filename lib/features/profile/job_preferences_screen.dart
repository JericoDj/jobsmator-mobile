import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme/theme.dart';
import '../../controllers/job_preferences_controller.dart';
import '../../core/models/user_defaults.dart';
import '../../providers/preferences_provider.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/jm_toast.dart';
import '../shared/widgets/selection_chip.dart';

/// Salary floor, location, work setup and employment type. Roles and
/// sites keep their own step screens.
class JobPreferencesScreen extends StatelessWidget {
  const JobPreferencesScreen({super.key});

  Future<void> _save(BuildContext context) async {
    final ok = await context.read<JobPreferencesController>().save();
    if (!context.mounted) return;
    ok
        ? showJmToast(context, title: 'Preferences saved', tone: ToastTone.success)
        : showJmToast(context, title: "Couldn't save", body: 'Check your connection and try again.', tone: ToastTone.error);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final ctrl = context.watch<JobPreferencesController>();
    final d = prefs.defaults;
    final c = context.jm;

    return JmPage(
      appBar: AppBar(title: const Text('Job preferences')),
      bottom: PrimaryButton(
        label: 'Save preferences',
        busyLabel: 'Saving…',
        busy: ctrl.saving,
        large: true,
        onPressed: () => _save(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'The ranking uses these to score fit and flag listings that miss.',
            style: context.type.body.copyWith(color: c.muted),
          ),
          const SizedBox(height: JmSpace.x6),
          TextField(
            controller: ctrl.salary,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Minimum salary (₱ / month)',
              hintText: '80000',
              helperText: 'Listings below this get a "below your range" flag. Leave empty for none.',
            ),
          ),
          const SizedBox(height: JmSpace.x4),
          TextField(
            controller: ctrl.location,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Location', hintText: 'Metro Manila'),
          ),
          const SizedBox(height: JmSpace.x8),
          JmLabel('Work setup', color: c.muted),
          const SizedBox(height: JmSpace.x3),
          Wrap(
            spacing: JmSpace.x2,
            runSpacing: JmSpace.x2,
            children: [
              for (final m in WorkMode.values)
                SelectionChip(label: m.label, selected: d.workMode == m, onChanged: (_) => prefs.setWorkMode(m)),
            ],
          ),
          const SizedBox(height: JmSpace.x8),
          JmLabel('Employment', color: c.muted),
          const SizedBox(height: JmSpace.x3),
          Wrap(
            spacing: JmSpace.x2,
            runSpacing: JmSpace.x2,
            children: [
              for (final t in EmploymentType.values)
                SelectionChip(
                  label: t.label,
                  selected: d.employmentType == t,
                  onChanged: (_) => prefs.setEmploymentType(t),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
