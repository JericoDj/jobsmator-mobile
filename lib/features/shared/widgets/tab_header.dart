import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// The header every tab page opens with: a 22px title, one muted line
/// under it, and an optional control on the right (Home's bell). Keeps the
/// five tabs reading as one app.
class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.title, required this.subtitle, this.trailing});
  final String title, subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.type.title.copyWith(fontSize: 22)),
              const SizedBox(height: 2),
              Text(subtitle, style: context.type.body.copyWith(color: c.muted, fontSize: 14)),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: JmSpace.x2), trailing!],
      ],
    );
  }
}
