/// The assistant behind the AI tab and the Tools tab.
///
/// Today this is a stub with canned replies; the real service will call the
/// API (which fronts the LLM) with the user's profile as context.
abstract class AiService {
  Future<String> chat(List<AiMessage> history, String prompt);
  Future<String> runTool(String toolId, String input);
}

enum AiRole { user, assistant }

class AiMessage {
  const AiMessage({required this.role, required this.text, required this.at});
  final AiRole role;
  final String text;
  final DateTime at;
}

class MockAiService implements AiService {
  const MockAiService();

  @override
  Future<String> chat(List<AiMessage> history, String prompt) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final p = prompt.toLowerCase();
    if (p.contains('remote') && p.contains('flutter')) {
      return 'I found 4 remote Flutter roles from your last search. Two are above your minimum rate: '
          'Mobile Engineer at GCash (84) and Flutter Developer at Maya (81). Want me to open them in Jobs, '
          'or draft an application for the top one?';
    }
    if (p.contains('resume')) {
      return 'Your resume reads well for senior Flutter roles. The gap recruiters will notice: no numbers on impact. '
          'Add one metric to each of your last two roles and your match scores should rise 3–5 points.';
    }
    if (p.contains('interview')) {
      return 'For a Flutter interview at a fintech, expect questions on state management trade-offs, offline sync, '
          'and secure storage. I can run a mock round — pick a listing from Jobs and say "prepare me".';
    }
    if (p.contains('apply') || p.contains('application')) {
      return 'Three jobs look worth applying to today: Senior Flutter Developer at Sprout (87), '
          'Mobile Engineer at GCash (84), Flutter Developer at Maya (81). Say which one and I will draft the email.';
    }
    return 'I can search jobs, score a listing against your resume, draft applications, or prep you for an '
        'interview. Try "find me remote Flutter jobs" or "analyze my resume".';
  }

  @override
  Future<String> runTool(String toolId, String input) async {
    await Future.delayed(const Duration(milliseconds: 1400));
    return switch (toolId) {
      'resume-analyzer' =>
        '**Strong:** 3 years of Flutter, Firebase and REST integration read clearly.\n\n'
            '**Fix first:** no metrics on impact. Add one number per role (users, crash-free %, release cadence).\n\n'
            '**Missing keywords for ${input.isEmpty ? 'senior Flutter roles' : input}:** CI/CD, state management '
            'rationale, accessibility.',
      'cover-letter' =>
        'Dear Hiring Team,\n\nYour listing asks for a Flutter engineer who ships to both stores '
            'and owns the release process. That has been my job for three years at Kalibrr…\n\n'
            '(Full letter uses your resume and the listing you pasted.)',
      'application-email' =>
        'Subject: Flutter Developer — application\n\nHi,\n\nI am applying for the Flutter '
            'Developer role. I have shipped three Flutter apps to both stores, most recently a fintech onboarding '
            'flow at Kalibrr. Resume attached; happy to walk through the code.\n\nJerico',
      'job-match' =>
        '**Score: 82 — Strong.**\n\nMatches your Flutter, Firebase and REST experience. '
            'Wants Kotlin familiarity you have less of.\n\n**Watch out for:** salary hidden.',
      'salary' =>
        'For ${input.isEmpty ? 'a mid-level Flutter developer in Manila' : input}: '
            '**₱70k–₱110k / month** (remote roles for foreign companies: ₱120k–₱180k). '
            'Listings with hidden salary in this range cluster around ₱85k.',
      'resume-builder' =>
        'Draft outline for ${input.isEmpty ? 'your target role' : input}:\n\n'
            '1. Headline with the role and three strongest skills\n2. Impact bullets (number first)\n'
            '3. Projects with store links\n4. Education last.',
      'interview-prep' =>
        '**Likely questions**\n\n1. How do you choose between Provider and Riverpod?\n'
            '2. Walk me through an offline-first sync you built.\n3. How do you keep releases predictable?\n\n'
            'Answer each with a situation, what you did, and the number that changed.',
      'jd-analyzer' =>
        '**They actually want:** a Flutter dev who can own releases without a lead.\n\n'
            '**Must-haves:** 3+ years Flutter, Firebase, REST.\n\n**Red flags:** "fast-paced" appears twice; '
            'no salary; on-site 3 days.',
      _ => 'Done.',
    };
  }
}
