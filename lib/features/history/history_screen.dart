import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/copy.dart';
import '../../core/models/run.dart';
import '../../providers/run_provider.dart';
import '../results/widgets/empty_state.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';

/// Past searches, newest first. Tap one to open its results.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<RunProvider>().loadHistory().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final runs = context.watch<RunProvider>();
    final c = context.jm;

    return JmPage(
      appBar: AppBar(title: const Text('History')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!runs.historyLoaded)
            const Padding(
              padding: EdgeInsets.only(top: JmSpace.x16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (runs.history.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: JmSpace.x8),
              child: EmptyState(
                icon: Icons.history_rounded,
                title: 'No searches yet',
                body: 'Every search you run shows up here with its stats, so you can reopen the results any time.',
                action: SecondaryButton(label: 'Find matching jobs', onPressed: () => context.go(AppRoutes.upload)),
              ),
            )
          else ...[
            Text(
              JmCopy.plural(runs.history.length, 'search', 'searches'),
              style: context.type.body.copyWith(color: c.muted),
            ),
            const SizedBox(height: JmSpace.x4),
            for (final (i, run) in runs.history.indexed) ...[
              if (i > 0) const SizedBox(height: JmSpace.x2),
              _RunTile(run: run, onTap: () => context.go(AppRoutes.run(run.id))),
            ],
          ],
        ],
      ),
    );
  }
}

class _RunTile extends StatelessWidget {
  const _RunTile({required this.run, required this.onTap});
  final Run run;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final (dot, status) = switch (run.status) {
      RunStatus.done => (c.match, '${run.stats?.recommended ?? 0} matches · ${run.stats?.scored ?? 0} scored'),
      RunStatus.failed => (c.danger, JmCopy.forError(run.errorCode)),
      RunStatus.running || RunStatus.queued => (c.ocean, 'Searching…'),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: JmRadius.lgR,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: JmRadius.lgR,
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      run.request.interests.join(', '),
                      style: context.type.uiStrong,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(status, style: context.type.meta, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${JmCopy.relative(run.startedAt)} · ${JmCopy.plural(run.request.sites.length, 'site')}'
                      '${run.sheet?.url != null ? ' · on Sheets' : ''}',
                      style: context.type.meta.copyWith(color: c.faint),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.faint),
            ],
          ),
        ),
      ),
    );
  }
}
