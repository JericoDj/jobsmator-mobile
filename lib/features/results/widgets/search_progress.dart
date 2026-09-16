import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../controllers/results_controller.dart';
import '../../shared/widgets/step_header.dart';

/// "Searching JobStreet… · 3 of 10 sites". Named sites and a pulsing
/// current segment make a 30–90 s wait feel like progress, not a spinner.
class SearchProgressView extends StatelessWidget {
  const SearchProgressView({super.key, required this.progress, required this.queued, required this.interests});
  final SearchProgress progress;
  final bool queued;
  final List<String> interests;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final total = progress.total == 0 ? 10 : progress.total;
    final step = queued ? 1 : progress.index + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: JmSpace.x8),
        Text(
          interests.isEmpty ? 'Finding your matches' : 'Finding ${interests.first} roles',
          style: context.type.title,
        ),
        const SizedBox(height: JmSpace.x2),
        Text(
          'Reading your resume, searching ${total == 1 ? 'one site' : '$total sites'}, then ranking every listing with a reason. Usually under a minute.',
          style: context.type.body.copyWith(color: c.muted),
        ),
        const SizedBox(height: JmSpace.x8),
        Container(
          padding: const EdgeInsets.all(JmSpace.x4),
          decoration: BoxDecoration(color: c.surface, borderRadius: JmRadius.lgR),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepBars(step: step, total: total, pulse: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: JmMotion.enterExit,
                      switchInCurve: JmMotion.ease,
                      layoutBuilder: (current, previous) =>
                          Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                      child: Text(
                        queued ? 'Reading your resume…' : 'Searching ${progress.currentSite}…',
                        key: ValueKey(queued ? 'queued' : progress.currentSite),
                        style: context.type.uiStrong,
                      ),
                    ),
                  ),
                  Text(
                    '${queued ? 0 : progress.done} of $total sites',
                    style: context.type.meta.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: JmSpace.x6),
        Text(
          'You can leave this screen — the search keeps running and your results will be here.',
          style: context.type.meta,
        ),
      ],
    );
  }
}
