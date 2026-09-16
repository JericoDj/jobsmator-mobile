import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/copy.dart';
import '../../../core/models/job.dart';
import '../../shared/widgets/badges.dart';
import '../../shared/widgets/highlighted_text.dart';
import 'score_ring.dart';

/// The product. Top to bottom: where it came from → what it is → why it fits
/// (matched interests highlighted) → what to watch out for → one primary action.
/// The score ring sits beside the text; actions span the full card width so
/// they stay on one line at phone widths.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.interests,
    required this.onOpen,
    required this.onSave,
    required this.onHide,
    this.animateRing = true,
  });

  final Job job;
  final List<String> interests;
  final VoidCallback onOpen, onSave, onHide;
  final bool animateRing;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final meta = [
      if (job.location.isNotEmpty) job.location,
      if (job.remote) 'Remote',
      if (job.postedAt != null) JmCopy.relative(job.postedAt),
    ];
    final terms = {
      ...interests,
      job.matchedInterest,
      ...interests.expand((i) => i.split(RegExp(r'\s+'))),
    }.where((t) => t.length > 2).toList();

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: JmRadius.lgR,
        border: Border.all(color: c.line),
        boxShadow: c.shadow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Where it came from
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          job.site,
                          style: context.type.meta.copyWith(fontWeight: FontWeight.w600, color: c.text),
                        ),
                        if (meta.isNotEmpty) Text('· ${meta.join(' · ')}', style: context.type.meta),
                        TierBadge(tier: job.tier),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // What it is
                    Text(job.title, style: context.type.heading),
                    const SizedBox(height: 2),
                    Text(
                      job.salary == null ? job.company : '${job.company} · ${job.salary}',
                      style: context.type.ui.copyWith(color: c.text, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: JmSpace.x4),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ScoreRing(score: job.score, animate: animateRing),
              ),
            ],
          ),
          // Why it fits
          if (job.why.isNotEmpty) ...[
            const SizedBox(height: 10),
            HighlightedText(
              job.why,
              terms: terms,
              style: context.type.body.copyWith(fontSize: 15, height: 1.5, color: c.text),
            ),
          ],
          // What to watch out for — always visible, never behind a disclosure
          if (job.redFlags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final f in job.redFlags) FlagChip(f)]),
          ],
          const SizedBox(height: 14),
          // One primary action
          Row(
            children: [
              Flexible(
                child: FilledButton(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text('Open on ${job.site}', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: onSave,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  foregroundColor: job.saved ? c.oceanDeep : c.text,
                ),
                icon: Icon(job.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: 18),
                label: Text(job.saved ? 'Saved' : 'Save'),
              ),
              TextButton(
                onPressed: onHide,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Hide'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
