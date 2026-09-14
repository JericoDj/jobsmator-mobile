import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/preferences_provider.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});
  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prefs = context.read<PreferencesProvider>();
    if (!prefs.loaded) prefs.load();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('What are you looking for?')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 2 of 3 · up to 5 job titles', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Add a job title', hintText: 'Flutter Developer'),
              onSubmitted: (v) {
                if (v.trim().isEmpty) return;
                prefs.setInterests([...prefs.interests, v.trim()]);
                _controller.clear();
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final i in prefs.interests)
                  InputChip(label: Text(i), onDeleted: () => prefs.setInterests(prefs.interests.where((x) => x != i).toList())),
              ],
            ),
            const Spacer(),
            FilledButton(onPressed: prefs.interests.isEmpty ? null : () => context.go('/sites'), child: const Text('Next: job sites')),
          ],
        ),
      ),
    );
  }
}
