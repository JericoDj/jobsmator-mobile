import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';

enum ToastTone { success, error, info }

/// Navy toast with a tone dot, a bold title, a quieter body and one action.
void showJmToast(
  BuildContext context, {
  required String title,
  String? body,
  ToastTone tone = ToastTone.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final c = context.jm;
  final dot = switch (tone) {
    ToastTone.success => c.match,
    ToastTone.error => const Color(0xFFFF6B6B),
    ToastTone.info => c.sky,
  };
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: Duration(seconds: actionLabel == null ? 4 : 7),
      padding: EdgeInsets.zero,
      content: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: body == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: body == null ? 0 : 6),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: context.type.uiStrong.copyWith(color: Colors.white, fontSize: 14.5)),
                  if (body != null) ...[
                    const SizedBox(height: 2),
                    Text(body, style: context.type.meta.copyWith(color: JmColors.navyText, fontSize: 13.5)),
                  ],
                ],
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onAction?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: c.sky,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: Text(actionLabel),
              ),
          ],
        ),
      ),
    ),
  );
}
