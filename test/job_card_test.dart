import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobsmator_mobile/app/theme/theme.dart';
import 'package:jobsmator_mobile/core/models/job.dart';
import 'package:jobsmator_mobile/features/results/widgets/job_card.dart';

const _job = Job(
  id: 'j1',
  rank: 1,
  score: 87,
  tier: Tier.strong,
  title: 'Senior Flutter Developer',
  company: 'Sprout Solutions',
  location: 'Makati',
  remote: false,
  salary: '₱85–110k',
  url: 'https://example.com',
  site: 'Kalibrr',
  matchedInterest: 'Flutter Developer',
  why: 'Matches your Flutter and Firebase experience.',
  redFlags: ['Requires on-site 3 days'],
  saved: false,
  hidden: false,
  applied: false,
);

void main() {
  // Fonts are fetched at runtime in the app; tests use the fallback stack.
  setUpAll(() => JmText.useGoogleFonts = false);

  testWidgets('job card shows source, title, why, red flag and one primary action', (tester) async {
    final semantics = tester.ensureSemantics();
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: JobCard(
            job: _job,
            interests: const ['Flutter Developer'],
            animateRing: false,
            onOpen: () => opened++,
            onSave: () {},
            onHide: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kalibrr'), findsOneWidget);
    expect(find.text('Senior Flutter Developer'), findsOneWidget);
    expect(find.text('Strong'), findsOneWidget);
    expect(find.text('Requires on-site 3 days'), findsOneWidget);
    expect(find.bySemanticsLabel('Match score 87 of 100, strong'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Open on Kalibrr'), findsOneWidget);

    await tester.tap(find.text('Open on Kalibrr'));
    expect(opened, 1);
    semantics.dispose();
  });
}
