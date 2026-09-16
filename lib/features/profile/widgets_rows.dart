import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// A grouped list of settings rows with the guide's label above.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.label, required this.children, this.trailing});
  final String label;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: JmLabel(label, color: c.muted)),
            ?trailing,
          ],
        ),
        const SizedBox(height: JmSpace.x2),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: JmRadius.lgR,
            border: Border.all(color: c.line),
          ),
          child: Column(
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0) Divider(indent: 14, endIndent: 14, color: c.line),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.label, this.value, this.icon, this.onTap, this.valueColor});
  final String label;
  final String? value;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return InkWell(
      onTap: onTap,
      borderRadius: JmRadius.lgR,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 20, color: c.muted), const SizedBox(width: 12)],
            Text(label, style: context.type.ui),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? '',
                style: context.type.meta.copyWith(fontSize: 14, color: valueColor),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: c.faint),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({super.key, required this.label, this.subtitle, required this.value, required this.onChanged});
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    title: Text(label, style: context.type.ui),
    subtitle: subtitle == null ? null : Text(subtitle!, style: context.type.meta),
    value: value,
    onChanged: onChanged,
  );
}
