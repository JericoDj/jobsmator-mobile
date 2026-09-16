import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../providers/preferences_provider.dart';
import '../results/widgets/empty_state.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/selection_chip.dart';

/// What the engine read from the resume. Read-only: to change it, upload
/// a new resume.
class CareerProfileScreen extends StatelessWidget {
  const CareerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final career = context.watch<PreferencesProvider>().career;
    final c = context.jm;

    return JmPage(
      appBar: AppBar(title: const Text('Your AI profile')),
      bottom: SecondaryButton(
        label: 'Upload a new resume',
        icon: Icons.upload_file_rounded,
        onPressed: () => context.go(AppRoutes.upload),
      ),
      child: career.isEmpty
          ? EmptyState(
              icon: Icons.description_outlined,
              title: 'Nothing here yet',
              body: 'Upload a resume and run a search. JobsMator fills this in from what it reads.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
