import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/copy.dart';
import '../../../core/models/resume.dart';

/// A resume already on file. The latest one is what a run uses.
class ResumeTile extends StatelessWidget {
  const ResumeTile({super.key, required this.resume, required this.current, this.onUse, this.onRemove});
  final Resume resume;
  final bool current;
  final VoidCallback? onUse, onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: current ? c.oceanTint : c.card,
        borderRadius: JmRadius.mdR,
        border: Border.all(color: current ? c.ocean : c.line, width: current ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 44,
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(6)),
            alignment: Alignment.center,
            child: Text(
              resume.extension,
              style: context.type.code.copyWith(fontSize: 10, fontWeight: FontWeight.w500, color: c.muted),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resume.filename, style: context.type.uiStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${resume.sizeLabel} · uploaded ${JmCopy.relative(resume.createdAt)}${current ? ' · in use' : ''}',
                  style: context.type.meta,
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              tooltip: 'Remove resume',
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: c.muted,
            ),
        ],
      ),
    );
  }
}
