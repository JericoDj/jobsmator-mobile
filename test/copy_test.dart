import 'package:flutter_test/flutter_test.dart';
import 'package:jobsmator_mobile/core/copy.dart';

void main() {
  test('error codes map to the guide wording', () {
    expect(JmCopy.forError('invalid_request'), 'Pick at least one job site and one interest to search.');
    expect(JmCopy.forError('resume_unreadable'), startsWith("We couldn't read that resume."));
    expect(JmCopy.forError('engine_unavailable'), 'Job sites are slow right now. Try again in a minute.');
    expect(JmCopy.forError('too_many_runs', retryAt: DateTime(2026, 1, 1, 14, 32)), contains('14:32'));
    expect(JmCopy.forError('nope'), 'Something went wrong. Try again.');
  });

  test('headline and weaker link never say skip', () {
    expect(JmCopy.resultsHeadline(14, 'Flutter Developer'), '14 strong matches for Flutter Developer');
    expect(JmCopy.resultsHeadline(1, 'QA'), '1 strong match for QA');
    expect(JmCopy.resultsHeadline(0, 'QA'), 'No strong matches yet');
    expect(JmCopy.weakerLink(12), 'Show 12 weaker matches');
    expect(JmCopy.weakerLink(1), 'Show 1 weaker match');
  });

  test('relative time', () {
    final now = DateTime(2026, 9, 16, 12);
    expect(JmCopy.relative(now.subtract(const Duration(days: 2)), now: now), '2 days ago');
    expect(JmCopy.relative(now.subtract(const Duration(hours: 1)), now: now), '1 hour ago');
    expect(JmCopy.relative(now.subtract(const Duration(days: 9)), now: now), '1 week ago');
    expect(JmCopy.relative(null), '');
  });
}
