import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../core/models/run.dart';
import '../shared/widgets/section_header.dart';

/// Consecutive days (ending today or yesterday) with at least one search.
int searchStreak(List<Run> runs) {
  if (runs.isEmpty) return 0;
  final days = runs
      .map(
        (r) => DateTime(r.startedAt.year, r.startedAt.month, r.startedAt.day),
      )
      .toSet();
  final now = DateTime.now();
  var day = DateTime(now.year, now.month, now.day);
  if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
  var streak = 0;
  while (days.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Four numbers in a bordered strip: searches, jobs found, applied, interviews.
class ProfileStats extends StatelessWidget {
  const ProfileStats({
    super.key,
    required this.searches,
    required this.jobs,
    required this.applied,
    required this.interviews,
  });
  final int searches, jobs, applied, interviews;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final cells = [
      (searches, 'Searches', c.ocean),
      (jobs, 'Jobs found', c.sky),
      (applied, 'Applied', c.match),
      (interviews, 'Interviews', c.volt),
    ];
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: JmRadius.lgR,
        border: Border.all(color: c.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, (value, label, color)) in cells.indexed) ...[
              if (i > 0) VerticalDivider(width: 1, color: c.line),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: JmSpace.x3),
                  child: Column(
                    children: [
                      Text(
                        '$value',
                        style: context.type.stat.copyWith(
                          fontSize: 22,
                          color: value == 0 ? c.faint : c.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            label,
                            style: context.type.meta.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Streak flame + a weekly application goal with a bar. Gives the user a
/// reason to come back tomorrow.
class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.streak,
    required this.appliedThisWeek,
    this.weeklyGoal = 5,
  });
  final int streak, appliedThisWeek, weeklyGoal;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final share = (appliedThisWeek / weeklyGoal).clamp(0.0, 1.0);
    final done = appliedThisWeek >= weeklyGoal;
    return Container(
      padding: const EdgeInsets.all(JmSpace.x4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: JmRadius.lgR,
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: streak > 0 ? c.warnTint : c.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: streak > 0 ? c.warn : c.faint,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak == 0 ? 'Start a streak' : '$streak-day streak',
                  style: context.type.uiStrong,
                ),
                Text(
                  streak == 0
                      ? 'Run a search today to begin.'
                      : 'Search again tomorrow to keep it going.',
                  style: context.type.meta,
                ),
                const SizedBox(height: JmSpace.x3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Weekly goal',
                        style: context.type.meta.copyWith(fontSize: 12),
                      ),
                    ),
                    Text(
                      done
                          ? 'Done ✓'
                          : '$appliedThisWeek of $weeklyGoal applied',
                      style: context.type.meta.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: done ? c.matchDeep : c.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Positioned.fill(child: ColoredBox(color: c.surface2)),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: share,
                              heightFactor: 1,
                              child: ColoredBox(
                                color: done ? c.match : c.ocean,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.applied,
    this.isYou = false,
  });
  final String name;
  final int applied;
  final bool isYou;
}

/// Sample peers until the backend exposes a leaderboard endpoint. Kept
/// small and plausible so the layout reads as real.
const sampleLeaderboard = [
  LeaderboardEntry(name: 'Marielle S.', applied: 14),
  LeaderboardEntry(name: 'Kenji T.', applied: 11),
  LeaderboardEntry(name: 'Dana R.', applied: 9),
  LeaderboardEntry(name: 'Paulo M.', applied: 6),
  LeaderboardEntry(name: 'Ana L.', applied: 4),
];

/// Weekly ranking by applications, the user's row highlighted.
class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key, required this.entries, this.sample = false});
  final List<LeaderboardEntry> entries;
  final bool sample;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final sorted = [...entries]..sort((a, b) => b.applied.compareTo(a.applied));
    final top = sorted.isEmpty ? 1 : sorted.first.applied.clamp(1, 1 << 30);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: 'This week', badge: sample ? 'Sample' : null),
        const SizedBox(height: JmSpace.x3),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: JmRadius.lgR,
            border: Border.all(color: c.line),
          ),
          child: Column(
            children: [
              for (final (i, e) in sorted.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.line),
                _LeaderRow(rank: i + 1, entry: e, share: e.applied / top),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.rank,
    required this.entry,
    required this.share,
  });
  final int rank;
  final LeaderboardEntry entry;
  final double share;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final medal = switch (rank) {
      1 => c.volt,
      2 => c.muted,
      3 => c.warn,
      _ => null,
    };
    return Container(
      color: entry.isYou ? c.oceanTint.withValues(alpha: .35) : null,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: medal == null
                ? Text(
                    '$rank',
                    style: context.type.stat.copyWith(
                      fontSize: 14,
                      color: c.muted,
                    ),
                  )
                : Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: medal.withValues(alpha: .18),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$rank',
                      style: context.type.stat.copyWith(
                        fontSize: 12,
                        color: c.ink,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: entry.isYou ? c.ocean : c.surface2,
            child: Text(
              entry.name.characters.first.toUpperCase(),
              style: context.type.uiStrong.copyWith(
                fontSize: 12,
                color: entry.isYou ? Colors.white : c.text,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isYou ? '${entry.name} (you)' : entry.name,
                  style: context.type.uiStrong.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 4,
                    child: Stack(
                      children: [
                        Positioned.fill(child: ColoredBox(color: c.surface2)),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: share.clamp(0.0, 1.0),
                              heightFactor: 1,
                              child: ColoredBox(
                                color: entry.isYou ? c.ocean : c.sky,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${entry.applied}',
            style: context.type.stat.copyWith(fontSize: 15, color: c.ink),
          ),
          const SizedBox(width: 4),
          Text('applied', style: context.type.meta.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
