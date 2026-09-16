import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/theme/theme.dart';
import '../../shared/widgets/jm_logo_mark.dart';

/// The auth pages share one quiet layout: the mark, a title, one line,
/// the form, and a single footer link pinned to the bottom. The pitch
/// lives in the welcome tour, so nothing here competes with the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.lede,
    required this.children,
    this.footer,
    this.onBack,
  });

  final String title, lede;
  final List<Widget> children;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final gutter = JmSpace.gutter(MediaQuery.sizeOf(context).width);
    return Scaffold(
      backgroundColor: c.ground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      if (onBack != null)
                        Padding(
                          padding: EdgeInsets.only(left: gutter - 12),
                          child: IconButton(
                            onPressed: onBack,
                            tooltip: 'Back',
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: c.ink,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(gutter, JmSpace.x4, gutter, JmSpace.x6),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: JmLogoMark(size: 48)),
                          const SizedBox(height: JmSpace.x6),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: context.type.display.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: JmSpace.x2),
                          Text(lede, textAlign: TextAlign.center, style: context.type.body.copyWith(color: c.muted)),
                          const SizedBox(height: JmSpace.x8),
                          ...children,
                        ],
                      ),
                    ),
                  ),
                ),
                if (footer != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, JmSpace.x2),
                    child: footer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A hairline with one word in it. Used once per page, between the form
/// and the Google button.
class OrDivider extends StatelessWidget {
  const OrDivider([this.text = 'or', Key? key]) : super(key: key);
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(text, style: context.type.meta.copyWith(color: context.jm.faint)),
      ),
      const Expanded(child: Divider()),
    ],
  );
}

/// One-line "Question? Action" link for the bottom of an auth page.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({super.key, required this.question, required this.action, required this.onPressed});
  final String question, action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
      child: Text.rich(
        TextSpan(
          text: '$question ',
          style: context.type.ui.copyWith(color: c.muted, fontWeight: FontWeight.w400),
          children: [
            TextSpan(
              text: action,
              style: TextStyle(color: c.oceanDeep, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, this.label = 'Continue with Google'});
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 48),
      foregroundColor: context.jm.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    icon: const GoogleG(),
    label: Text(label),
  );
}

/// Apple only asks for its button on Apple platforms; App Review requires it
/// there whenever another third-party sign-in is offered.
bool get showAppleSignIn => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

class AppleButton extends StatelessWidget {
  const AppleButton({super.key, required this.onPressed, this.label = 'Continue with Apple'});
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 48),
      foregroundColor: context.jm.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    icon: const Icon(Icons.apple, size: 22),
    label: Text(label),
  );
}

/// "v1.2.3 (45)" in the quietest text on the page. Reads the version from
/// the platform bundle so pubspec stays the single source of truth.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key, this.prefix = ''});

  /// Text before the version, e.g. 'JobsMator · '.
  final String prefix;

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snap) {
      final info = snap.data;
      if (info == null) return const SizedBox(height: 18);
      return Text(
        '${prefix}v${info.version} (${info.buildNumber})',
        textAlign: TextAlign.center,
        style: context.type.meta.copyWith(color: context.jm.faint, fontSize: 12),
      );
    },
  );
}

class GoogleG extends StatelessWidget {
  const GoogleG({super.key, this.size = 18});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _GPainter()),
  );
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .22;
    final arc = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    // Angles clockwise from 3 o'clock; the G opens between red and blue.
    const segs = [
      (Color(0xFF4285F4), 0.0, math.pi / 4),
      (Color(0xFF34A853), math.pi / 4, math.pi / 2),
      (Color(0xFFFBBC05), 3 * math.pi / 4, math.pi / 2),
      (Color(0xFFEA4335), 5 * math.pi / 4, math.pi * .55),
    ];
    for (final (color, start, sweep) in segs) {
      canvas.drawArc(arc, start, sweep, false, paint..color = color);
    }
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, size.height / 2 - stroke / 2, size.width / 2, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
