import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/copy.dart';
import '../../core/models/subscription.dart';
import '../../core/models/user_defaults.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_catalog_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/run_provider.dart';
import '../../providers/subscription_provider.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../auth/widgets/auth_scaffold.dart';
import 'profile_stats.dart';
import 'share_progress.dart';
import 'widgets_rows.dart';

/// Everything about the user's career profile and how JobsMator works for
/// them. Rows lead to the existing flow screens wherever one exists.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = context.read<PreferencesProvider>();
      if (!prefs.loaded) prefs.load().catchError((_) {});
      final subs = context.read<SubscriptionProvider>();
      if (!subs.loaded) subs.load().catchError((_) {});
      final resumes = context.read<ResumeProvider>();
      if (!resumes.loaded) resumes.load().catchError((_) {});
      final runs = context.read<RunProvider>();
      if (!runs.historyLoaded) runs.loadHistory().catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prefs = context.watch<PreferencesProvider>();
    final subs = context.watch<SubscriptionProvider>();
    final resume = context.watch<ResumeProvider>().latest;
    final catalog = context.watch<JobCatalogProvider>();
    final runs = context.watch<RunProvider>();
    final c = context.jm;
    final user = auth.user;
    final career = prefs.career;
    final d = prefs.defaults;
    final salary = d.salaryMin == null
        ? 'No minimum'
        : '₱${_k(d.salaryMin!)}+ / month';

    // Stats run on the live catalogue; the leaderboard is sample peers plus
    // the user's own applied count until there's an endpoint for it.
    final live = catalog.all.where((j) => !j.hidden).toList();
    // Job has no applied-at yet, so "this week" is all applications for now.
    final appliedThisWeek = catalog.applied;
    final finishedRuns = runs.history.where((r) => r.isDone).toList();
    final board = [
      ...sampleLeaderboard,
      LeaderboardEntry(
        name: user?.firstName ?? 'You',
        applied: appliedThisWeek,
        isYou: true,
      ),
    ];

    return JmPage(
      maxWidth: JmLayout.results,
      padding: JmPage.tabPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Identity + plan
          Container(
            padding: const EdgeInsets.all(JmSpace.x4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: JmRadius.lgR,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: c.oceanTint,
                  foregroundImage: user?.photoUrl == null
                      ? null
                      : NetworkImage(user!.photoUrl!),
                  child: Text(
                    (user?.firstName ?? '?').characters.first.toUpperCase(),
                    style: context.type.heading.copyWith(color: c.oceanDeep),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? user?.email ?? 'Signed in',
                        style: context.type.uiStrong,
                      ),
                      Text(
                        career.headline.isEmpty
                            ? (user?.email ?? '')
                            : career.headline,
                        style: context.type.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PlanPill(
                  plan: subs.plan,
                  onTap: () => context.push(AppRoutes.subscribe),
                ),
              ],
            ),
          ),
          const SizedBox(height: JmSpace.x6),

          // Progress
          Row(
            children: [
              Expanded(child: JmLabel('Your progress', color: c.muted)),
              TextButton.icon(
                onPressed: () => context.push(
                  AppRoutes.shareProgress,
                  extra: ProgressSnapshot(
                    name: user?.firstName ?? 'My',
                    searches: finishedRuns.length,
                    jobs: live.length,
                    applied: catalog.applied,
                    interviews: catalog.interviews,
                    streak: searchStreak(finishedRuns),
                    applyRate: live.isEmpty ? 0 : catalog.applied / live.length,
                  ),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 16),
                label: const Text('Share'),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x2),
          ProfileStats(
            searches: finishedRuns.length,
            jobs: live.length,
            applied: catalog.applied,
            interviews: catalog.interviews,
          ),
          const SizedBox(height: JmSpace.x3),
          StreakCard(
            streak: searchStreak(finishedRuns),
            appliedThisWeek: appliedThisWeek,
          ),
          const SizedBox(height: JmSpace.x6),
          Leaderboard(entries: board, sample: true),
          const SizedBox(height: JmSpace.x8),

          SettingsGroup(
            label: 'Your AI profile',
            trailing: TextButton(
              onPressed: () => context.push(AppRoutes.career),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: const Text('View'),
            ),
            children: [
              SettingsRow(
                icon: Icons.description_outlined,
                label: 'Resume',
                value: resume?.filename ?? 'None yet',
                onTap: () => context.go(AppRoutes.upload),
              ),
              SettingsRow(
                icon: Icons.psychology_outlined,
                label: 'Skills',
                value: career.skills.isEmpty
                    ? '—'
                    : JmCopy.plural(career.skills.length, 'skill'),
                onTap: () => context.push(AppRoutes.career),
              ),
              SettingsRow(
                icon: Icons.work_outline_rounded,
                label: 'Experience',
                value: career.experience.isEmpty
                    ? '—'
                    : '${career.yearsExperience ?? career.experience.length} years',
                onTap: () => context.push(AppRoutes.career),
              ),
              SettingsRow(
                icon: Icons.school_outlined,
                label: 'Education',
                value: career.education.isEmpty
                    ? '—'
                    : career.education.first.degree,
                onTap: () => context.push(AppRoutes.career),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x6),

          SettingsGroup(
            label: 'Job preferences',
            children: [
              SettingsRow(
                icon: Icons.badge_outlined,
                label: 'Roles',
                value: d.interests.isEmpty
                    ? 'None yet'
                    : d.interests.join(', '),
                onTap: () => context.go(AppRoutes.interests),
              ),
              SettingsRow(
                icon: Icons.payments_outlined,
                label: 'Salary',
                value: salary,
                onTap: () => context.push(AppRoutes.jobPreferences),
              ),
              SettingsRow(
                icon: Icons.place_outlined,
                label: 'Location',
                value: d.location,
                onTap: () => context.push(AppRoutes.jobPreferences),
              ),
              SettingsRow(
                icon: Icons.home_work_outlined,
                label: 'Work setup',
                value: d.workMode == WorkMode.any
                    ? 'Remote, hybrid or on-site'
                    : d.workMode.label,
                onTap: () => context.push(AppRoutes.jobPreferences),
              ),
              SettingsRow(
                icon: Icons.schedule_outlined,
                label: 'Employment',
                value: d.employmentType == EmploymentType.any
                    ? 'Full-time or part-time'
                    : d.employmentType.label,
                onTap: () => context.push(AppRoutes.jobPreferences),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x6),

          SettingsGroup(
            label: 'Job sources',
            children: [
              SettingsRow(
                icon: Icons.public_rounded,
                label: 'Sites',
                value: '${d.sites.length} of ${jobSites.length} on',
                onTap: () => context.go(AppRoutes.sites),
              ),
              SettingsRow(
                icon: Icons.tune_rounded,
                label: 'Jobs per site',
                value: '${d.jobsPerSite}',
                onTap: () => context.go(AppRoutes.sites),
              ),
              SettingsRow(
                icon: Icons.speed_rounded,
                label: 'Minimum score',
                value: '${d.minScore}',
                onTap: () => context.go(AppRoutes.sites),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x6),

          SettingsGroup(
            label: 'Automation settings',
            children: [
              SettingsRow(
                icon: Icons.bolt_rounded,
                label: 'Schedules',
                value: '${prefs.automationsRunning} running',
                onTap: () => context.push(AppRoutes.automation),
              ),
              SettingsRow(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                value: prefs.settings.notifyNewMatches ? 'On' : 'Off',
                onTap: () => context.push(AppRoutes.automation),
              ),
              SettingsRow(
                icon: Icons.auto_awesome_outlined,
                label: 'AI preferences',
                value: prefs.settings.aiTone,
                onTap: () => context.push(AppRoutes.automation),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x6),

          SettingsGroup(
            label: 'Account',
            children: [
              SettingsRow(
                icon: Icons.workspace_premium_outlined,
                label: 'Plan',
                value: subs.isPro
                    ? 'Pro · ${subs.searchesLeft} searches left this hour'
                    : 'Free · ${subs.searchesLeft} search left today',
                onTap: () => context.push(AppRoutes.subscribe),
              ),
              SettingsRow(
                icon: Icons.history_rounded,
                label: 'Search history',
                onTap: () => context.push(AppRoutes.history),
              ),
              SettingsRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: user?.email ?? '—',
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x8),
          DangerButton(label: 'Sign out', onPressed: auth.signOut),
          const SizedBox(height: JmSpace.x4),
          const AppVersionLabel(prefix: 'JobsMator · '),
        ],
      ),
    );
  }

  String _k(int n) => n >= 1000
      ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k'
      : '$n';
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.plan, required this.onTap});
  final Plan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final pro = plan == Plan.pro;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: JmRadius.pillR,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: pro ? c.matchTint : c.card,
            borderRadius: JmRadius.pillR,
            border: Border.all(color: pro ? c.match : c.lineStrong),
          ),
          child: Text(
            pro ? 'Pro' : 'Upgrade',
            style: context.type.meta.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: pro ? c.matchDeep : c.oceanDeep,
            ),
          ),
        ),
      ),
    );
  }
}
