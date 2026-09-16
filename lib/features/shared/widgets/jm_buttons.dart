import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// The one Cobalt primary per view. `large` is the 48px CTA on the upload
/// screen; `busyLabel` replaces the label while [busy] ("Searching…").
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel,
    this.large = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy, large;
  final String? busyLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: Size(0, large ? 48 : 40),
      padding: EdgeInsets.symmetric(horizontal: large ? 24 : 18),
      textStyle: context.type.uiStrong.copyWith(fontSize: large ? 16 : 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(large ? 12 : JmRadius.md)),
    );
    final child = AnimatedSwitcher(
      duration: JmMotion.state,
      child: busy
          ? Row(
              key: const ValueKey('busy'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(busyLabel ?? label),
              ],
            )
          : Row(
              key: const ValueKey('idle'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(label),
              ],
            ),
    );
    return FilledButton(style: style, onPressed: busy ? null : onPressed, child: child);
  }
}

/// Outlined secondary: "Change sites", "Edit interests".
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Text(label),
      ],
    ),
  );
}

/// Danger text button: "Remove resume". Outline only, never a red fill.
class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: c.danger,
        side: BorderSide(color: c.danger),
      ),
      child: Text(label),
    );
  }
}
