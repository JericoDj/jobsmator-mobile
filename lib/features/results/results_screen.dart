import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/models/job.dart';
import '../../core/models/run.dart';
import '../../providers/jobs_provider.dart';
import '../../providers/run_provider.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.runId});
  final String runId;
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  RunStatus? _last;

  @override
  void initState() {
    super.initState();
    final rp = context.read<RunProvider>();
    if (rp.current?.id != widget.runId) rp.watch(widget.runId);
  }

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunProvider>().current;
    final jobs = context.watch<JobsProvider>();

    if (run != null && run.status == RunStatus.done && _last != RunStatus.done) {
      _last = RunStatus.done;
      WidgetsBinding.instance.addPostFrameCallback((_) => jobs.loadForRun(widget.runId));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your matches')),
      body: switch (run?.status) {
        null || RunStatus.queued || RunStatus.running => const _Searching(),
        RunStatus.failed => _Failed(code: run!.errorCode),
        RunStatus.done => jobs.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _JobCard(job: jobs.visible[i]),
              ),
      },
    );
  }
}

class _Searching extends StatelessWidget {
  const _Searching();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Searching job sites… this takes about a minute.'),
        ]),
      );
}

class _Failed extends StatelessWidget {
  const _Failed({this.code});
  final String? code;
  @override
  Widget build(BuildContext context) {
    final message = switch (code) {
      'resume_unreadable' => "We couldn't read that resume. Try a text-based PDF instead of a scan.",
      'invalid_request' => 'Pick at least one job site and one interest to search.',
      _ => 'Job sites are slow right now. Try again in a minute.',
    };
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center)));
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final tiers = Theme.of(context).extension<JmTierColors>()!;
    final (bg, fg) = switch (job.tier) {
      Tier.strong => (tiers.strongBg, tiers.strongFg),
      Tier.good => (tiers.goodBg, tiers.goodFg),
      Tier.skip => (tiers.skipBg, tiers.skipFg),
    };
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Theme.of(context).colorScheme.outline)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('${job.site} · ${job.location}', style: Theme.of(context).textTheme.bodySmall)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                child: Text('${job.score} · ${job.tier.name}', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(job.title, style: Theme.of(context).textTheme.titleMedium),
            Text(job.company),
            const SizedBox(height: 8),
            Text(job.why),
            if (job.redFlags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [for (final f in job.redFlags) Chip(label: Text(f), visualDensity: VisualDensity.compact)]),
            ],
            const SizedBox(height: 12),
            Row(children: [
              FilledButton(onPressed: () => launchUrl(Uri.parse(job.url), mode: LaunchMode.externalApplication), child: Text('Open on ${job.site}')),
              const SizedBox(width: 8),
              TextButton(onPressed: () => context.read<JobsProvider>().toggleSaved(job), child: Text(job.saved ? 'Saved' : 'Save')),
              TextButton(onPressed: () => context.read<JobsProvider>().toggleHidden(job), child: const Text('Hide')),
            ]),
          ],
        ),
      ),
    );
  }
}
