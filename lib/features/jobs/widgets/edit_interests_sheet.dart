import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/user_defaults.dart';
import '../../../providers/job_catalog_provider.dart';
import '../../../providers/preferences_provider.dart';
import '../../preferences/interests_screen.dart' show interestSuggestions;
import '../../shared/widgets/jm_buttons.dart';
import '../../shared/widgets/jm_toast.dart';
import '../../shared/widgets/selection_chip.dart';

/// Edit interests in place and save them to the account. The board is
/// picked from these, so it reloads on save. Nothing is written until Save.
Future<void> showEditInterestsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.jm.ground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _EditInterestsSheet(),
  );
}

class _EditInterestsSheet extends StatefulWidget {
  const _EditInterestsSheet();

  @override
  State<_EditInterestsSheet> createState() => _EditInterestsSheetState();
}

class _EditInterestsSheetState extends State<_EditInterestsSheet> {
  late List<String> _draft = List.of(
    context.read<PreferencesProvider>().interests,
  );
  final _field = TextEditingController();
  String? _hint;
  var _saving = false;

  int get _remaining => maxInterests - _draft.length;
  bool get _dirty {
    final saved = context.read<PreferencesProvider>().interests;
    return saved.length != _draft.length ||
        saved.asMap().entries.any((e) => e.value != _draft[e.key]);
  }

  void _add(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return;
    setState(() {
      if (_remaining <= 0) {
        _hint = 'Five is the limit.';
      } else if (_draft.any((i) => i.toLowerCase() == v.toLowerCase())) {
        _hint = 'Already on the list.';
      } else {
        _draft = [..._draft, v];
        _hint = null;
        _field.clear();
      }
    });
  }

  Future<void> _save() async {
    if (_draft.isEmpty) {
      setState(() => _hint = 'Add at least one job title.');
      return;
    }
    setState(() => _saving = true);
    final prefs = context.read<PreferencesProvider>();
    final before = List.of(prefs.interests);
    prefs.setInterests(_draft);
    try {
      await prefs.save();
      if (!mounted) return;
      Navigator.of(context).pop();
      // New interests, new picks.
      context.read<JobCatalogProvider>().loadFeed().catchError((_) {});
      showJmToast(context, title: 'Interests saved', tone: ToastTone.success);
    } catch (e) {
      prefs.setInterests(before);
      if (mounted) {
        setState(() => _saving = false);
        showJmToast(
          context,
          title: "Couldn't save",
          body: messageOf(e),
          tone: ToastTone.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final suggestions = interestSuggestions
        .where((s) => !_draft.any((i) => i.toLowerCase() == s.toLowerCase()))
        .toList();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          JmSpace.x4,
          JmSpace.x3,
          JmSpace.x4,
          JmSpace.x4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your interests', style: context.type.heading),
            const SizedBox(height: 2),
            Text(
              'Up to $maxInterests job titles. The board and every search use these.',
              style: context.type.meta,
            ),
            const SizedBox(height: JmSpace.x4),
            TextField(
              controller: _field,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              enabled: _remaining > 0 && !_saving,
              onSubmitted: _add,
              decoration: InputDecoration(
                labelText: 'Add a job title',
                hintText: 'Flutter Developer',
                helperText:
                    _hint ??
                    (_remaining == 0
                        ? 'Five is the limit.'
                        : '$_remaining more'),
                helperStyle: context.type.meta.copyWith(
                  color: _hint == null ? c.muted : c.warn,
                ),
                suffixIcon: IconButton(
                  tooltip: 'Add',
                  onPressed: _remaining > 0 ? () => _add(_field.text) : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
            ),
            const SizedBox(height: JmSpace.x3),
            if (_draft.isEmpty)
              Text(
                'Nothing yet — add one above or pick a suggestion.',
                style: context.type.meta,
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final i in _draft)
                    SelectionChip(
                      label: i,
                      selected: true,
                      onChanged: null,
                      onDeleted: () => setState(() {
                        _draft = _draft.where((x) => x != i).toList();
                        _hint = null;
                      }),
                    ),
                ],
              ),
            if (suggestions.isNotEmpty && _remaining > 0) ...[
              const SizedBox(height: JmSpace.x4),
              JmLabel('Suggestions', color: c.muted),
              const SizedBox(height: JmSpace.x2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in suggestions.take(8))
                    SelectionChip(
                      label: s,
                      selected: false,
                      onChanged: (_) => _add(s),
                    ),
                ],
              ),
            ],
            const SizedBox(height: JmSpace.x6),
            PrimaryButton(
              label: _saving ? 'Saving…' : 'Save',
              icon: Icons.check_rounded,
              onPressed: _saving || !_dirty ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
