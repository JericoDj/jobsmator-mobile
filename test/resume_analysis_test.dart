import 'package:flutter_test/flutter_test.dart';
import 'package:jobsmator_mobile/core/models/resume.dart';

void main() {
  test('ResumeAnalysis.fromJson parses every field, defensively', () {
    final a = ResumeAnalysis.fromJson({
      'summary': 'Two sentences about who this person is.',
      'headline': 'Mid-level Flutter developer, 3 yrs',
      'seniority': 'mid',
      'strengths': ['Shipped to both stores', 'Owns features end to end'],
      'fixes': ['Add measurable impact'],
      'skills': ['flutter', 'firebase'],
      'roles': ['Flutter Developer'],
      'tags': ['flutter developer', 'flutter', 'firebase'],
      'industries': ['Software & IT'],
    });
    expect(a.headline, 'Mid-level Flutter developer, 3 yrs');
    expect(a.seniority, 'mid');
    expect(a.strengths, hasLength(2));
    expect(a.fixes, ['Add measurable impact']);
    expect(a.skills, ['flutter', 'firebase']);
    expect(a.tags, ['flutter developer', 'flutter', 'firebase']);
  });

  test('ResumeAnalysis.fromJson defaults missing fields instead of throwing', () {
    final a = ResumeAnalysis.fromJson(const {});
    expect(a.summary, '');
    expect(a.strengths, isEmpty);
    expect(a.tags, isEmpty);
  });

  test('Resume.fromJson: no analysis and no status reads as pending', () {
    final r = Resume.fromJson({
      'id': 'r1',
      'filename': 'resume.pdf',
      'createdAt': '2026-01-01T00:00:00Z',
    });
    expect(r.analysis, isNull);
    expect(r.analysisStatus, ResumeAnalysisStatus.pending);
  });

  test('Resume.fromJson: analysisError with no status reads as failed', () {
    final r = Resume.fromJson({
      'id': 'r1',
      'filename': 'resume.pdf',
      'createdAt': '2026-01-01T00:00:00Z',
      'analysisError': 'model timed out',
    });
    expect(r.analysisStatus, ResumeAnalysisStatus.failed);
  });

  test('Resume.fromJson: an analysis payload with no explicit status reads as done', () {
    final r = Resume.fromJson({
      'id': 'r1',
      'filename': 'resume.pdf',
      'createdAt': '2026-01-01T00:00:00Z',
      'analysis': {'headline': 'Mid-level Flutter developer, 3 yrs'},
    });
    expect(r.analysisStatus, ResumeAnalysisStatus.done);
    expect(r.analysis!.headline, 'Mid-level Flutter developer, 3 yrs');
  });

  test('Resume.fromJson: an explicit analysisStatus wins over inference', () {
    final r = Resume.fromJson({
      'id': 'r1',
      'filename': 'resume.pdf',
      'createdAt': '2026-01-01T00:00:00Z',
      'analysisStatus': 'pending',
      'analysis': {'headline': 'stale from a previous run'},
    });
    expect(r.analysisStatus, ResumeAnalysisStatus.pending);
  });

  test('ResumeMatches.fromJson parses items and tags', () {
    final m = ResumeMatches.fromJson({
      'items': [
        {
          'id': 'j1',
          'rank': 1,
          'score': 80,
          'tier': 'strong',
          'title': 'Flutter Developer',
          'company': 'Acme',
          'location': 'Manila',
          'remote': true,
          'url': 'https://example.com',
          'site': 'LinkedIn',
          'matchedInterest': 'Flutter Developer',
          'why': 'Matches skills',
          'redFlags': [],
          'saved': false,
          'hidden': false,
          'applied': false,
        },
      ],
      'tags': ['flutter', 'firebase'],
    });
    expect(m.items, hasLength(1));
    expect(m.items.first.title, 'Flutter Developer');
    expect(m.tags, ['flutter', 'firebase']);
  });
}
