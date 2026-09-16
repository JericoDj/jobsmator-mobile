import 'package:flutter/material.dart';

import '../providers/onboarding_provider.dart';

/// One slide of the welcome tour.
class OnboardingSlide {
  const OnboardingSlide({required this.eyebrow, required this.title, required this.body});
  final String eyebrow, title, body;
}

const onboardingSlides = [
  OnboardingSlide(
    eyebrow: 'Step one',
    title: 'Upload your resume once.',
    body: 'We read it so you never retype your experience into another form.',
  ),
  OnboardingSlide(
    eyebrow: 'Step two',
    title: 'Ten job sites, one search.',
    body: 'Indeed, LinkedIn, JobStreet and more — searched together, in the background.',
  ),
  OnboardingSlide(
    eyebrow: 'Step three',
    title: 'Every match, ranked honestly.',
    body: 'Each job gets a score and a plain-language reason, so you only apply where it counts.',
  ),
];

/// Which slide is showing. Owns the [PageController] so the screen stays
/// stateless; finishing marks the tour as seen in [OnboardingProvider].
class OnboardingController extends ChangeNotifier {
  OnboardingController(this._onboarding);

  final OnboardingProvider _onboarding;
  final page = PageController();

  int _index = 0;
  int get index => _index;
  int get count => onboardingSlides.length;
  bool get isLast => _index == count - 1;
  OnboardingSlide get slide => onboardingSlides[_index];

  void onPageChanged(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }

  void next() {
    if (isLast) return;
    page.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Future<void> finish() => _onboarding.markSeen();

  @override
  void dispose() {
    page.dispose();
    super.dispose();
  }
}
