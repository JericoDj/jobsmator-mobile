import fs from 'fs';

const path = 'lib/features/jobs/job_detail_screen.dart';
let code = fs.readFileSync(path, 'utf8');

// 1. Add `final inFeed` logic after `final job = catalog.byId(ctrl.jobId);`
code = code.replace(
  'final job = catalog.byId(ctrl.jobId);\n    final c = context.jm;',
  `final job = catalog.byId(ctrl.jobId);\n    final c = context.jm;\n    final isFeedOnly = catalog.feed.any((j) => j.id == job?.id) && !catalog.all.any((j) => j.id == job?.id);`
);

// 2. Hide TierBadge if isFeedOnly
code = code.replace(
  'TierBadge(tier: job.tier),',
  'if (!isFeedOnly) TierBadge(tier: job.tier),'
);

// 3. Hide ScoreRing if isFeedOnly
code = code.replace(
  'ScoreRing(score: job.score, size: 72),',
  'if (!isFeedOnly) ScoreRing(score: job.score, size: 72),'
);

// 4. Replace the "Why it fits" section with an if/else
const sectionToReplace = `          const SizedBox(height: JmSpace.x6),
          JmLabel('Why it fits', color: c.muted),
          const SizedBox(height: JmSpace.x2),
          HighlightedText(job.why.isEmpty ? 'No reason recorded for this listing.' : job.why, terms: terms),
          if (job.redFlags.isNotEmpty) ...[
            const SizedBox(height: JmSpace.x6),
            JmLabel('Watch out for', color: c.muted),
            const SizedBox(height: JmSpace.x2),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final f in job.redFlags) FlagChip(f)]),
          ],
          const SizedBox(height: JmSpace.x6),
          JmLabel('Matched interest', color: c.muted),
          const SizedBox(height: JmSpace.x2),
          Text(job.matchedInterest.isEmpty ? '—' : job.matchedInterest, style: context.type.body),`;

const replacement = `          const SizedBox(height: JmSpace.x6),
          if (isFeedOnly)
            Container(
              padding: const EdgeInsets.all(JmSpace.x4),
              decoration: BoxDecoration(color: c.surface, borderRadius: JmRadius.lgR),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('This job is from the global board.', style: context.type.uiStrong),
                  const SizedBox(height: JmSpace.x2),
                  Text('Find out how well it fits your resume and interests.', style: context.type.body.copyWith(color: c.muted)),
                  const SizedBox(height: JmSpace.x4),
                  PrimaryButton(
                    label: 'Score this job (1 credit)',
                    icon: Icons.auto_awesome,
                    onPressed: () async {
                      try {
                        // We assume scoreJob is added to catalog provider
                        final newJob = await catalog.scoreJob(job.id);
                        if (context.mounted) {
                          context.pushReplacement(AppRoutes.job(newJob.id));
                        }
                      } catch (e) {
                        if (context.mounted) showJmToast(context, title: e.toString(), tone: ToastTone.error);
                      }
                    },
                  ),
                ],
              ),
            )
          else ...[
            JmLabel('Why it fits', color: c.muted),
            const SizedBox(height: JmSpace.x2),
            HighlightedText(job.why.isEmpty ? 'No reason recorded for this listing.' : job.why, terms: terms),
            if (job.redFlags.isNotEmpty) ...[
              const SizedBox(height: JmSpace.x6),
              JmLabel('Watch out for', color: c.muted),
              const SizedBox(height: JmSpace.x2),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final f in job.redFlags) FlagChip(f)]),
            ],
            const SizedBox(height: JmSpace.x6),
            JmLabel('Matched interest', color: c.muted),
            const SizedBox(height: JmSpace.x2),
            Text(job.matchedInterest.isEmpty ? '—' : job.matchedInterest, style: context.type.body),
          ],`;

code = code.replace(sectionToReplace, replacement);

fs.writeFileSync(path, code);
console.log("Patched JobDetailScreen");
