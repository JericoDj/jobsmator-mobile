import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/activity.dart';
import '../../../core/copy.dart';

/// Icon · title/detail · relative time. Used by Home's Recent activity and
/// the notifications dropdown.
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.item, this.dense = false});
  final Activity item;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final (icon, color) = switch (item.kind) {
      ActivityKind.run => (Icons.search_rounded, c.match),
      ActivityKind.failed => (Icons.error_outline_rounded, c.danger),
      ActivityKind.applied => (Icons.send_rounded, c.ocean),
      ActivityKind.automation => (Icons.bolt_rounded, c.sky),
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(14, dense ? 10 : 12, 14, dense ? 10 : 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: context.type.uiStrong.copyWith(fontSize: 14)),
                Text(item.detail, style: context.type.meta, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(JmCopy.relative(item.at), style: context.type.meta.copyWith(color: c.faint, fontSize: 12)),
        ],
      ),
    );
  }
}
