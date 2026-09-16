import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/copy.dart';
import '../../providers/job_catalog_provider.dart';
import '../results/widgets/empty_state.dart';
import '../../providers/run_provider.dart';
import '../../providers/subscription_provider.dart';
import '../shared/widgets/cta_card.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/selection_chip.dart';
import '../shared/widgets/tab_header.dart';
import 'widgets/job_row.dart';

/// The job database: everything JobsMator has found, searchable and
/// filterable, best score first. New searches start from here.
class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    final catalog = context.read<JobCatalogProvider>();
    _search = TextEditingController(text: catalog.query);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!catalog.loaded) catalog.load().catchError((_) {});
      final runs = context.read<RunProvider>();
      if (!runs.historyLoaded) runs.loadHistory().catchError((_) {});
      final subs = context.read<SubscriptionProvider>();
      if (!subs.loaded) subs.load().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<JobCatalogProvider>();
    final runs = context.watch<RunProvider>();
    final subs = context.watch<SubscriptionProvider>();
    final c = context.jm;
    final jobs = catalog.visible;
    final lastRun = runs.history.where((r) => !r.isActive).firstOrNull;
    final running = runs.current?.isActive ?? false;

    return JmPage(
      maxWidth: JmLayout.results,
      padding: JmPage.tabPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabHeader(
            title: 'Jobs',
            subtitle: jobs.isEmpty ? 'Every match, ranked with a reason.' : '${JmCopy.plural(catalog.all.length, 'job', 'jobs')} found · ${JmCopy.plural(catalog.newMatches, 'new match', 'new matches')}',
          ),
          const SizedBox(height: JmSpace.x6),
          CtaCard(
            navy: false,
            eyebrow: running ? 'Searching now' : 'Your job database',
            title: running
                ? 'New matches on the way'
                : catalog.newMatches == 0
                ? 'Nothing new since your last search'
                : '${JmCopy.plural(catalog.newMatches, 'match', 'matches')} waiting for you',
            body: running
                ? 'Ten sites are being searched and ranked right now.'
                : lastRun == null
                ? 'Run a search and every match lands here, ranked with a reason.'
                : 'Last search ${JmCopy.relative(lastRun.finishedAt ?? lastRun.startedAt)} · ${JmCopy.plural(lastRun.request.sites.length, 'site')} · ${lastRun.stats?.scored ?? 0} listings scored.',
            facts: [
              (Icons.bookmark_border_rounded, JmCopy.plural(catalog.savedCount, 'saved job')),
              (Icons.send_outlined, JmCopy.plural(catalog.applied, 'application')),
              (
                Icons.confirmation_number_outlined,
                '${JmCopy.plural(subs.searchesLeft, 'search', 'searches')} left ${subs.plan.periodLabel}',
              ),
            ],
            actionLabel: running ? 'See progress' : 'Find new jobs',
            actionIcon: running ? Icons.timelapse_rounded : Icons.search_rounded,
            onAction: () => context.go(running ? AppRoutes.run(runs.current!.id) : AppRoutes.upload),
            secondaryLabel: catalog.savedCount > 0 ? 'Saved' : null,
            onSecondary: catalog.savedCount > 0 ? () => catalog.setFilter(JobFilter.saved) : null,
          ),
          const SizedBox(height: JmSpace.x6),
          TextField(
            controller: _search,
            onChanged: catalog.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search title, company, site or city',
              prefixIcon: Icon(Icons.search_rounded, color: c.muted),
              suffixIcon: catalog.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _search.clear();
                        catalog.setQuery('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: JmSpace.x3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final f in JobFilter.values) ...[
                  SelectionChip(
                    label: f == JobFilter.all ? f.label : '${f.label} ${catalog.countFor(f)}',
                    selected: catalog.filter == f,
                    onChanged: (_) => catalog.setFilter(f),
                  ),
                  const SizedBox(width: JmSpace.x2),
                ],
              ],
            ),
          ),
          const SizedBox(height: JmSpace.x4),
          if (!catalog.loaded && catalog.loading)
            const Padding(
              padding: EdgeInsets.only(top: JmSpace.x12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (catalog.all.isEmpty)
            EmptyState(
              icon: Icons.work_outline_rounded,
              title: 'No jobs yet',
              body: 'Run your first search and every match lands here, ranked with a reason.',
              action: SecondaryButton(label: 'Find matching jobs', onPressed: () => context.go(AppRoutes.upload)),
            )
          else if (jobs.isEmpty)
            EmptyState(
              title: 'Nothing matches that',
              body:
                  'Try another word, or clear the ${catalog.filter == JobFilter.all ? 'search' : '${catalog.filter.label} filter'}.',
              action: SecondaryButton(
                label: 'Show all jobs',
                onPressed: () {
                  _search.clear();
                  catalog.setQuery('');
                  catalog.setFilter(JobFilter.all);
                },
              ),
            )
          else ...[
            Text(JmCopy.plural(jobs.length, 'job'), style: context.type.meta),
            const SizedBox(height: JmSpace.x2),
            for (final (i, job) in jobs.indexed) ...[
              if (i > 0) const SizedBox(height: JmSpace.x2),
              JobRow(job: job, onTap: () => context.push(AppRoutes.job(job.id))),
            ],
          ],
        ],
      ),
    );
  }
}
