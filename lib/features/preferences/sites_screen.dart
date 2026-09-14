import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/preferences_provider.dart';
import '../../providers/resume_provider.dart';
import '../../providers/run_provider.dart';

class SitesScreen extends StatelessWidget {
  const SitesScreen({super.key});

  Future<void> _start(BuildContext context) async {
    final prefs = context.read<PreferencesProvider>();
    final runs = context.read<RunProvider>();
    final resume = context.read<ResumeProvider>().latest;
    if (resume == null) return context.go('/upload');
    await prefs.save();
    final id = await runs.start(
          resumeId: resume.id, interests: prefs.interests, sites: prefs.sites.toList(),
          jobsPerSite: prefs.jobsPerSite, remoteOnly: prefs.remoteOnly, minScore: prefs.minScore,
        );
    if (id != null && context.mounted) context.go('/runs/$id');
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    final run = context.watch<RunProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Where should we look?')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 3 of 3', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                for (final s in jobSites)
                  FilterChip(label: Text(s), selected: prefs.sites.contains(s), onSelected: (_) => prefs.toggleSite(s)),
              ],
            ),
            if (run.error != null) ...[
              const SizedBox(height: 16),
              Text(run.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const Spacer(),
            FilledButton(onPressed: prefs.sites.isEmpty ? null : () => _start(context), child: const Text('Find matching jobs')),
          ],
        ),
      ),
    );
  }
}
