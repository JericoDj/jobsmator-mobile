import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/onboarding_controller.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_logo_mark.dart';
import 'widgets/onboarding_art.dart';

/// Three slides: one picture, one line each. Swipe or tap Next; the last
/// slide hands off to sign-up, with a quiet way in for returning users.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _leave(BuildContext context, String route) async {
    await context.read<OnboardingController>().finish();
    if (context.mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<OnboardingController>();
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
                // Wordmark left, Skip right — Skip fades out on the last slide.
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter + 4, JmSpace.x3, gutter, 0),
                  child: Row(
                    children: [
                      const JmWordmark(size: 24),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: ctrl.isLast ? 0 : 1,
                        duration: JmMotion.enterExit,
                        child: TextButton(
                          onPressed: ctrl.isLast ? null : () => _leave(context, AppRoutes.login),
                          style: TextButton.styleFrom(foregroundColor: c.muted),
                          child: const Text('Skip'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: ctrl.page,
                    onPageChanged: ctrl.onPageChanged,
                    itemCount: ctrl.count,
                    itemBuilder: (_, i) => _Slide(index: i, gutter: gutter),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 0, gutter, JmSpace.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Dots(count: ctrl.count, index: ctrl.index),
                      const SizedBox(height: JmSpace.x6),
                      AnimatedSwitcher(
                        duration: JmMotion.enterExit,
                        switchInCurve: JmMotion.ease,
                        switchOutCurve: JmMotion.ease,
                        child: ctrl.isLast
                            ? Column(
                                key: const ValueKey('last'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PrimaryButton(
                                    label: 'Create an account',
                                    large: true,
                                    onPressed: () => _leave(context, AppRoutes.register),
                                  ),
                                  const SizedBox(height: JmSpace.x2),
                                  TextButton(
                                    onPressed: () => _leave(context, AppRoutes.login),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(0, 44),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('I already have an account'),
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey('next'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PrimaryButton(label: 'Next', large: true, onPressed: ctrl.next),
                                  // Keeps the button from jumping when the text link appears.
                                  const SizedBox(height: JmSpace.x2 + 44),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.index, required this.gutter});
  final int index;
  final double gutter;

  @override
  Widget build(BuildContext context) {
    final s = onboardingSlides[index];
    final c = context.jm;
    return LayoutBuilder(
      builder: (context, box) {
        // Art takes what the height allows, never more than the width.
        final artSize = (box.maxHeight * .5).clamp(180.0, box.maxWidth - gutter * 2);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: SizedBox(width: artSize, child: OnboardingArt(index: index))),
              const SizedBox(height: JmSpace.x8),
              JmLabel(s.eyebrow, color: c.oceanDeep),
              const SizedBox(height: JmSpace.x2),
              Text(s.title, style: context.type.display.copyWith(fontSize: 28)),
              const SizedBox(height: JmSpace.x3),
              Text(s.body, style: context.type.body.copyWith(color: c.muted)),
            ],
          ),
        );
      },
    );
  }
}

/// Page indicator: the current dot stretches into a Cobalt pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count, index;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: JmMotion.enterExit,
            curve: JmMotion.ease,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(color: i == index ? c.ocean : c.line, borderRadius: JmRadius.pillR),
          ),
      ],
    );
  }
}
