import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/interests_controller.dart';
import '../../core/models/user_defaults.dart';
import '../../providers/preferences_provider.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/selection_chip.dart';
import '../shared/widgets/step_header.dart';

const _suggestions = [
  'Flutter Developer',
  'Mobile Engineer',
  'Frontend Developer',
  'Software Engineer',
  'Backend Developer',
  'Full Stack Developer',
  'React Developer',
  'iOS Developer',
  'Android Developer',
];

/// Step 2. Pre-filled from saved defaults — the user edits, not types.
class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final _field = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String value) {
    if (context.read<InterestsController>().add(value)) {
      _field.clear();
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<InterestsController>();
    final prefs = context.watch<PreferencesProvider>();
    final c = context.jm;
    final suggestions = _suggestions
        .where((s) => !prefs.interests.any((i) => i.toLowerCase() == s.toLowerCase()))
        .take(6);

    return JmPage(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go(AppRoutes.upload))),
      bottom: PrimaryButton(
        label: 'Next: choose job sites',
        large: true,
        icon: Icons.arrow_forward_rounded,
        onPressed: ctrl.canContinue ? () => context.go(AppRoutes.sites) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StepHeader(
            step: 2,
            title: 'What are you looking for?',
            lede: 'Up to $maxInterests job titles. We search each one on every site and rank everything together.',
          ),
          const SizedBox(height: JmSpace.x6),
          TextField(
            controller: _field,
            focusNode: _focus,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            enabled: ctrl.remaining > 0,
            onSubmitted: _add,
            decoration: InputDecoration(
              labelText: 'Add a job title',
              hintText: 'Flutter Developer',
              helperText: ctrl.hint ?? (ctrl.remaining == 0 ? 'Five is the limit.' : '${ctrl.remaining} more'),
              helperStyle: context.type.meta.copyWith(color: ctrl.hint == null ? c.muted : c.warn),
              suffixIcon: IconButton(
                tooltip: 'Add',
                onPressed: ctrl.remaining > 0 ? () => _add(_field.text) : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ),
          const SizedBox(height: JmSpace.x4),
          AnimatedSize(
            duration: JmMotion.enterExit,
            curve: JmMotion.ease,
            alignment: Alignment.topLeft,
            child: prefs.interests.isEmpty
                ? Text('Nothing yet — add one above or pick a suggestion.', style: context.type.meta)
                : Wrap(
                    spacing: JmSpace.x2,
                    runSpacing: JmSpace.x2,
                    children: [
                      for (final i in prefs.interests)
                        SelectionChip(label: i, selected: true, onChanged: null, onDeleted: () => ctrl.remove(i)),
                    ],
                  ),
          ),
          if (suggestions.isNotEmpty && ctrl.remaining > 0) ...[
            const SizedBox(height: JmSpace.x8),
            JmLabel('Suggestions', color: c.muted),
            const SizedBox(height: JmSpace.x3),
            Wrap(
              spacing: JmSpace.x2,
              runSpacing: JmSpace.x2,
              children: [
                for (final s in suggestions) SelectionChip(label: s, selected: false, onChanged: (_) => ctrl.add(s)),
              ],
            ),
          ],
          const SizedBox(height: JmSpace.x8),
          Text(
            'Tip: be specific. "Senior Flutter Developer" beats "Developer" — the ranking uses the title to judge fit.',
            style: context.type.meta,
          ),
        ],
      ),
    );
  }
}
