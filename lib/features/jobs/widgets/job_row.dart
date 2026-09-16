import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/copy.dart';
import '../../../core/models/job.dart';

/// Compact, scannable row for lists of many jobs (Jobs tab, Home).
/// Score as a small ring + number; tier dot; applied/saved marks.
class JobRow extends StatelessWidget {
  const JobRow({super.key, required this.job, required this.onTap, this.dense = false});
  final Job job;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final t = context.tiers;
    final ring = job.score >= 80
        ? c.match
        : job.score >= 60
        ? c.ocean
        : c.faint;
    final dot = switch (job.tier) {
      Tier.strong => t.strongDot,
      Tier.good => t.goodDot,
      Tier.skip => t.skipDot,
    };
    final meta = [job.company, job.site, if (job.remote) 'Remote' else if (job.location.isNotEmpty) job.location];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: JmRadius.mdR,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: dense ? 10 : 12, horizontal: 12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: JmRadius.mdR,
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              _MiniRing(
                score: job.score,
                color: ring,
                track: c.surface2,
                textStyle: context.type.stat.copyWith(fontSize: 13),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: context.type.uiStrong,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (job.applied) ...[
                          const SizedBox(width: 6),
                          _Tag('Applied', bg: c.matchTint, fg: c.matchDeep),
                        ] else if (job.saved) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.bookmark_rounded, size: 16, color: c.oceanDeep),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${meta.join(' · ')}${job.postedAt == null ? '' : ' · ${JmCopy.relative(job.postedAt)}'}',
                            style: context.type.meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, size: 20, color: c.faint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {required this.bg, required this.fg});
  final String text;
  final Color bg, fg;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: JmRadius.pillR),
    child: Text(
      text,
      style: context.type.meta.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: fg, height: 1.2),
    ),
  );
}

class _MiniRing extends StatelessWidget {
  const _MiniRing({required this.score, required this.color, required this.track, required this.textStyle});
  final int score;
  final Color color, track;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 40,
    child: Stack(
      fit: StackFit.expand,
      children: [
        CircularProgressIndicator(
          value: score / 100,
          strokeWidth: 3.5,
          color: color,
          backgroundColor: track,
          strokeCap: StrokeCap.round,
        ),
        Center(child: Text('$score', style: textStyle)),
      ],
    ),
  );
}
