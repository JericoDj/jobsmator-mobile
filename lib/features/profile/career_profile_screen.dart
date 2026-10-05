import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/models/resume.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/resume_provider.dart';
import '../results/widgets/empty_state.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/jm_toast.dart';
import '../shared/widgets/selection_chip.dart';

/// What the engine read from the resume. The top section is what the AI
/// analysis found on the currently selected resume (see `ResumeProvider`);
/// below it, the broader career profile built up from `/v1/me`. Both are
/// read-only: to change either, upload a new resume, or re-analyze this one.
class CareerProfileScreen extends StatefulWidget {
  const CareerProfileScreen({super.key});

  @override
  State<CareerProfileScreen> createState() => _CareerProfileScreenState();
}

class _CareerProfileScreenState extends State<CareerProfileScreen> {
  bool _reanalyzing = false;

  Future<void> _reanalyze(Resume resume) async {
    setState(() => _reanalyzing = true);
    try {
      await context.read<ResumeProvider>().analyze(resume.id);
      if (!mounted) return;
      showJmToast(context, title: 'Resume re-analyzed', tone: ToastTone.success);
    } catch (e) {
      if (!mounted) return;
      showJmToast(context, title: "Couldn't re-analyze", body: messageOf(e), tone: ToastTone.error);
    } finally {
      if (mounted) setState(() => _reanalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final career = context.watch<PreferencesProvider>().career;
    final resume = context.watch<ResumeProvider>().selected;
    final c = context.jm;

    return JmPage(
      appBar: AppBar(title: const Text('Your AI profile')),
      bottom: SecondaryButton(
        label: 'Upload a new resume',
        icon: Icons.upload_file_rounded,
        onPressed: () => context.go(AppRoutes.upload),
      ),
      child: career.isEmpty && resume == null
          ? EmptyState(
              icon: Icons.description_outlined,
              title: 'Nothing here yet',
              body: 'Upload a resume and run a search. JobsMator fills this in from what it reads.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (resume != null) ...[
                  _ResumeAnalysisSection(
                    resume: resume,
                    busy: _reanalyzing,
                    onReanalyze: () => _reanalyze(resume),
                  ),
                  const SizedBox(height: JmSpace.x8),
                ],
                if (career.headline.isNotEmpty) ...[
                  Text(career.headline, style: context.type.title),
                  const SizedBox(height: JmSpace.x2),
                ],
                Text(
                  'Built from your resume. Every match is scored against this.',
                  style: context.type.body.copyWith(color: c.muted),
                ),
                const SizedBox(height: JmSpace.x8),
                JmLabel('Skills', color: c.muted),
                const SizedBox(height: JmSpace.x3),
                Wrap(
                  spacing: JmSpace.x2,
                  runSpacing: JmSpace.x2,
                  children: [for (final s in career.skills) SelectionChip(label: s, selected: false, onChanged: null)],
                ),
                const SizedBox(height: JmSpace.x8),
                JmLabel('Experience', color: c.muted),
                const SizedBox(height: JmSpace.x3),
                for (final e in career.experience) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: JmSpace.x2),
                    padding: const EdgeInsets.all(JmSpace.x4),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: JmRadius.mdR,
                      border: Border.all(color: c.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title, style: context.type.uiStrong),
                        Text('${e.company} · ${e.period}', style: context.type.meta),
                        if (e.summary.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(e.summary, style: context.type.body.copyWith(fontSize: 14, color: c.text)),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: JmSpace.x6),
                JmLabel('Education', color: c.muted),
                const SizedBox(height: JmSpace.x3),
                for (final e in career.education)
                  Container(
                    margin: const EdgeInsets.only(bottom: JmSpace.x2),
                    padding: const EdgeInsets.all(JmSpace.x4),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: JmRadius.mdR,
                      border: Border.all(color: c.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.degree, style: context.type.uiStrong),
                        Text('${e.school} · ${e.period}', style: context.type.meta),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// The AI's read on one resume: headline, a two-sentence summary,
/// strengths, what to fix first, and a Re-analyze action.
class _ResumeAnalysisSection extends StatelessWidget {
  const _ResumeAnalysisSection({required this.resume, required this.busy, required this.onReanalyze});
  final Resume resume;
  final bool busy;
  final VoidCallback onReanalyze;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final analysis = resume.analysis;

    return Container(
      padding: const EdgeInsets.all(JmSpace.x4),
      decoration: BoxDecoration(color: c.card, borderRadius: JmRadius.lgR, border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(resume.filename, style: context.type.uiStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              TextButton.icon(
                onPressed: busy ? null : onReanalyze,
                icon: busy
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: c.oceanDeep))
                    : const Icon(Icons.refresh_rounded, size: 16),
                label: Text(busy ? 'Analyzing…' : 'Re-analyze'),
                style: TextButton.styleFrom(foregroundColor: c.oceanDeep, padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ],
          ),
          if (resume.analysisStatus == ResumeAnalysisStatus.pending) ...[
            const SizedBox(height: JmSpace.x2),
            Text('Analyzing this resume…', style: context.type.meta),
          ] else if (resume.analysisStatus == ResumeAnalysisStatus.failed) ...[
            const SizedBox(height: JmSpace.x2),
            Text("Couldn't analyze this resume. Try again.", style: context.type.meta.copyWith(color: c.warn)),
          ] else if (analysis != null) ...[
            if (analysis.headline.isNotEmpty) ...[
              const SizedBox(height: JmSpace.x2),
              Text(analysis.headline, style: context.type.title.copyWith(fontSize: 18)),
            ],
            if (analysis.summary.isNotEmpty) ...[
              const SizedBox(height: JmSpace.x2),
              Text(analysis.summary, style: context.type.body.copyWith(fontSize: 14, color: c.text)),
            ],
            if (analysis.strengths.isNotEmpty) ...[
              const SizedBox(height: JmSpace.x4),
              JmLabel('Strengths', color: c.muted),
              const SizedBox(height: JmSpace.x2),
              for (final s in analysis.strengths) _Bullet(text: s, color: c.match),
            ],
            if (analysis.fixes.isNotEmpty) ...[
              const SizedBox(height: JmSpace.x4),
              JmLabel('Fix first', color: c.muted),
              const SizedBox(height: JmSpace.x2),
              for (final f in analysis.fixes) _Bullet(text: f, color: c.warn),
            ],
            if (analysis.skills.isNotEmpty) ...[
              const SizedBox(height: JmSpace.x4),
              JmLabel('Skills the AI found', color: c.muted),
              const SizedBox(height: JmSpace.x2),
              Wrap(
                spacing: JmSpace.x2,
                runSpacing: JmSpace.x2,
                children: [for (final s in analysis.skills) SelectionChip(label: s, selected: false, onChanged: null)],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: context.type.body.copyWith(fontSize: 14))),
      ],
    ),
  );
}
