import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/models/user_defaults.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/subscription_provider.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/jm_toast.dart';
import '../shared/widgets/selection_chip.dart';

/// Schedule a search: pick how often and when, confirm what it looks for,
/// and JobsMator runs it while you're away. Uses the latest resume and the
/// saved interests/sites; each run spends one credit like a manual search.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _frequency = 'daily';
  int _weekday = DateTime.now().weekday % 7; // 0 = Sunday, matches the API
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  final _name = TextEditingController();
  bool _saving = false;

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    final resumes = context.read<ResumeProvider>();
    if (!resumes.loaded) resumes.load().catchError((_) {});
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    final prefs = context.read<PreferencesProvider>();
    final resume = context.read<ResumeProvider>().latest;
    if (resume == null) {
      showJmToast(
        context,
        title: 'Upload a resume first',
        tone: ToastTone.error,
      );
      return;
    }
    if (prefs.interests.isEmpty) {
      showJmToast(
        context,
        title: 'Add at least one job interest',
        tone: ToastTone.error,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await prefs.createAutomation(
        resumeId: resume.id,
        interests: prefs.interests,
        sites: prefs.sites,
        frequency: _frequency,
        hour: _time.hour,
        minute: _time.minute,
        weekday: _frequency == 'weekly' ? _weekday : null,
        name: _name.text,
      );
      if (!mounted) return;
      showJmToast(
        context,
        title: 'Scheduled',
        body: 'JobsMator will search on its own from now on.',
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      showJmToast(
        context,
        title: "Couldn't save the schedule",
        tone: ToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final prefs = context.watch<PreferencesProvider>();
    final subs = context.watch<SubscriptionProvider>();
    final resume = context.watch<ResumeProvider>().latest;
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(_time);

    return JmPage(
      appBar: AppBar(title: const Text('Schedule a search')),
      bottom: JmBottomBar(
        child: PrimaryButton(
          label: 'Schedule',
          busy: _saving,
          busyLabel: 'Saving…',
          icon: Icons.bolt_rounded,
          onPressed: _saving ? null : _save,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Let it run while you sleep',
            style: context.type.title.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            'Each scheduled run spends one credit, same as a manual search. '
            'You have ${subs.searchesLeft} left ${subs.plan.periodLabel} on the ${subs.plan.label} plan.',
            style: context.type.body.copyWith(color: c.muted, fontSize: 14),
          ),
          const SizedBox(height: JmSpace.x6),

          JmLabel('How often', color: c.muted),
          const SizedBox(height: JmSpace.x3),
          Wrap(
            spacing: JmSpace.x2,
            runSpacing: JmSpace.x2,
            children: [
              for (final (id, label) in const [
                ('daily', 'Every day'),
                ('weekdays', 'Weekdays'),
                ('weekly', 'Once a week'),
              ])
                SelectionChip(
                  label: label,
                  selected: _frequency == id,
                  onChanged: (_) => setState(() => _frequency = id),
                ),
            ],
          ),
          if (_frequency == 'weekly') ...[
            const SizedBox(height: JmSpace.x3),
            Wrap(
              spacing: JmSpace.x2,
              runSpacing: JmSpace.x2,
              children: [
                for (var i = 0; i < 7; i++)
                  SelectionChip(
                    label: _days[i],
                    selected: _weekday == i,
                    onChanged: (_) => setState(() => _weekday = i),
                  ),
              ],
            ),
          ],
          const SizedBox(height: JmSpace.x6),

          JmLabel('At what time', color: c.muted),
          const SizedBox(height: JmSpace.x3),
          _Row(
            icon: Icons.schedule_rounded,
            title: timeLabel,
            subtitle: 'Your local time',
            trailing: Icon(Icons.chevron_right_rounded, color: c.faint),
            onTap: _pickTime,
          ),
          const SizedBox(height: JmSpace.x6),

          JmLabel('What it searches', color: c.muted),
          const SizedBox(height: JmSpace.x3),
          _Row(
            icon: Icons.description_outlined,
            title: resume?.filename ?? 'No resume yet',
            subtitle: resume == null
                ? 'Upload one to schedule searches'
                : 'Latest resume',
            trailing: Icon(Icons.chevron_right_rounded, color: c.faint),
            onTap: () => context.go(AppRoutes.upload),
          ),
          const SizedBox(height: JmSpace.x2),
          _Row(
            icon: Icons.interests_outlined,
            title: prefs.interests.isEmpty
                ? 'No interests yet'
                : prefs.interests.join(', '),
            subtitle: 'Job interests',
            trailing: Icon(Icons.chevron_right_rounded, color: c.faint),
            onTap: () => context.push(AppRoutes.jobPreferences),
          ),
          const SizedBox(height: JmSpace.x2),
          _Row(
            icon: Icons.language_rounded,
            title: prefs.sites.length == jobSites.length
                ? 'All ${jobSites.length} job sites'
                : prefs.sites.join(', '),
            subtitle: 'Job sites',
            trailing: Icon(Icons.chevron_right_rounded, color: c.faint),
            onTap: () => context.push(AppRoutes.jobPreferences),
          ),
          const SizedBox(height: JmSpace.x6),

          JmLabel('Name (optional)', color: c.muted),
          const SizedBox(height: JmSpace.x3),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: prefs.interests.isEmpty
                  ? 'Daily search'
                  : 'Daily search for ${prefs.interests.first}',
            ),
          ),
          const SizedBox(height: JmSpace.x6),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Material(
      color: c.card,
      borderRadius: JmRadius.mdR,
      child: InkWell(
        onTap: onTap,
        borderRadius: JmRadius.mdR,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: JmRadius.mdR,
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: c.oceanDeep),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.type.uiStrong,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(subtitle, style: context.type.meta),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
