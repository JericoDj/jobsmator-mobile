import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

/// Centered art + title + one sentence of help + one secondary action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.search_off_rounded,
    this.action,
  });
  final String title, body;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(18)),
                child: Icon(icon, size: 28, color: c.muted),
              ),
              const SizedBox(height: 12),
              Text(title, style: context.type.heading, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(body, style: context.type.meta.copyWith(fontSize: 14), textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 14), action!],
            ],
          ),
        ),
      ),
    );
  }
}
