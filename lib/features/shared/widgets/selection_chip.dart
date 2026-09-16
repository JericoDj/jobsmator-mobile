import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Multi-select chip. Selected = Cobalt border + tint + checkmark, so the
/// state survives grayscale. Vertical padding brings it to a 44pt target.
class SelectionChip extends StatelessWidget {
  const SelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.onDeleted,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final fg = selected ? c.oceanDeep : c.text;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: JmRadius.pillR,
          focusColor: c.sky.withValues(alpha: .25),
          onTap: onChanged == null ? null : () => onChanged!(!selected),
          child: AnimatedContainer(
            duration: JmMotion.state,
            curve: JmMotion.ease,
            constraints: const BoxConstraints(minHeight: JmLayout.touchTarget),
            padding: EdgeInsets.only(left: selected ? 12 : 16, right: onDeleted == null ? 16 : 8),
            decoration: BoxDecoration(
              color: selected ? c.oceanTint : c.card,
              borderRadius: JmRadius.pillR,
              border: Border.all(color: selected ? c.ocean : c.lineStrong, width: selected ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: JmMotion.state,
                  curve: JmMotion.ease,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.check_rounded, size: 16, color: fg),
                        )
                      : const SizedBox.shrink(),
                ),
                Text(
                  label,
                  style: (selected ? context.type.uiStrong : context.type.ui).copyWith(color: fg, fontSize: 14),
                ),
                if (onDeleted != null) ...[
                  const SizedBox(width: 2),
                  IconButton(
                    onPressed: onDeleted,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    color: fg,
                    tooltip: 'Remove $label',
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
