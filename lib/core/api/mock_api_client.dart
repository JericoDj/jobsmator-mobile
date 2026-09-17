import 'dart:math';

import 'api_client.dart';
import '../models/user_defaults.dart';

/// Fixture-backed [ApiClient] for `--dart-define=PREVIEW=true`.
///
/// Mirrors the API surface in ARCHITECTURE.md §5.2 closely enough to walk the
/// whole core flow without a backend. A run "takes" [runDuration] so the
/// search-progress state is visible.
class MockApiClient implements ApiClient {
  MockApiClient({this.runDuration = const Duration(seconds: 9)});

  final Duration runDuration;
  final _latency = const Duration(milliseconds: 250);

  Map<String, dynamic> _defaults = const UserDefaults(interests: ['Flutter Developer', 'Mobile Engineer']).toJson();
  Map<String, dynamic> _subscription = {'plan': 'free', 'searchesUsed': 0, 'renewsAt': null};
  Map<String, dynamic> _settings = {};
  final List<Map<String, dynamic>> _automations = [
    {
      'id': 'auto_1',
      'name': 'Daily Flutter search',
      'schedule': 'Every day · 8:00',
      'enabled': true,
      'lastRunAt': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      'nextRunAt': DateTime.now().add(const Duration(hours: 18)).toIso8601String(),
      'lastResultCount': 12,
    },
    {
      'id': 'auto_2',
      'name': 'Weekly remote roundup',
      'schedule': 'Mondays · 9:00',
      'enabled': true,
      'lastRunAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'nextRunAt': DateTime.now().add(const Duration(days: 6)).toIso8601String(),
      'lastResultCount': 5,
    },
    {
      'id': 'auto_3',
      'name': 'Salary alerts above ₱100k',
      'schedule': 'Every day · 18:00',
      'enabled': false,
      'lastRunAt': null,
      'nextRunAt': null,
      'lastResultCount': null,
    },
  ];
  final List<Map<String, dynamic>> _resumes = [];
  final Map<String, ({DateTime startedAt, Map<String, dynamic> request})> _runs = {};
  final Map<String, Map<String, dynamic>> _jobs = {
    for (final j in _fixtureJobs) j['id'] as String: {...j},
  };

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    await Future.delayed(_latency);
    if (path == '/v1/me') {
      return {
        'id': 'u_1',
        'email': 'jerico@example.com',
        'displayName': 'Jerico De Jesus',
        'defaults': _defaults,
        'subscription': _subscription,
        'sheetId': null,
        'profile': _careerProfile,
        'automations': _automations,
        'settings': _settings,
      };
    }
    if (path == '/v1/jobs') return {'items': _jobs.values.toList(), 'nextCursor': null};
    if (path == '/v1/jobs/feed') {
      final all = _jobs.values.toList()..shuffle(Random());
      return {'items': all.take(int.tryParse('${query?['limit'] ?? 12}') ?? 12).toList(), 'nextCursor': null};
    }
    final one = RegExp(r'^/v1/jobs/([^/]+)$').firstMatch(path);
    if (one != null && _jobs[one.group(1)!] != null) return _jobs[one.group(1)!]!;
    if (path == '/v1/jobs/saved') return {'items': _jobs.values.where((j) => j['saved'] == true).toList()};
    if (path == '/v1/runs') {
      return {
        'items': [for (final id in _runs.keys) _run(id), ..._pastRuns],
      };
    }
    if (path == '/v1/resumes') return {'items': _resumes.reversed.toList()};
    final runJobs = RegExp(r'^/v1/runs/([^/]+)/jobs$').firstMatch(path);
    if (runJobs != null) {
      final items = _jobs.values.toList()..sort((a, b) => a['rank'].compareTo(b['rank']));
      return {'items': items, 'nextCursor': null};
    }
    final run = RegExp(r'^/v1/runs/([^/]+)$').firstMatch(path);
    if (run != null) return _run(run.group(1)!);
    throw ApiException('not_found', 'No mock for GET $path', status: 404);
  }

  @override
  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    await Future.delayed(_latency);
    final b = (body as Map?)?.cast<String, dynamic>() ?? const {};
    if (path == '/v1/automations') {
      const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      final freq = b['frequency'] as String;
      final when = freq == 'daily' ? 'Every day' : freq == 'weekdays' ? 'Weekdays' : '${days[b['weekday'] ?? 1]}s';
      final time = '${b['hour']}:${(b['minute'] ?? 0).toString().padLeft(2, '0')}';
      final a = {
        'id': 'auto_${DateTime.now().millisecondsSinceEpoch}',
        'name': b['name'] ?? '$when search for ${(b['interests'] as List).first}',
        'schedule': '$when · $time',
        'enabled': true,
        'lastRunAt': null,
        'nextRunAt': DateTime.now().add(const Duration(hours: 12)).toIso8601String(),
        'lastResultCount': null,
      };
      _automations.insert(0, a);
      return a;
    }
    if (path == '/v1/auth/register') {
      final name = b['displayName'] as String? ?? 'Jerico De Jesus';
      final email = b['email'] as String? ?? 'jerico@example.com';
      return {
        'token': 'mock-auth-token',
        'user': {
          'id': 'u_${DateTime.now().millisecondsSinceEpoch}',
          'email': email,
          'displayName': name,
          'defaults': _defaults,
          'subscription': _subscription,
          'sheetId': null,
          'profile': _careerProfile,
          'automations': _automations,
          'settings': _settings,
        },
      };
    }
    if (path == '/v1/me') {
      return {
        'id': 'u_1',
        'email': 'jerico@example.com',
        'displayName': b['displayName'] ?? 'Jerico De Jesus',
        'defaults': _defaults,
        'subscription': _subscription,
        'sheetId': null,
        'profile': _careerProfile,
        'automations': _automations,
        'settings': _settings,
      };
    }
    if (path == '/v1/resumes') {
      final id = 'r_${_resumes.length + 1}';
      _resumes.add({
        'id': id,
        'filename': b['filename'],
        'sizeBytes': b['sizeBytes'],
        'createdAt': DateTime.now().toIso8601String(),
      });
      return {'resumeId': id};
    }
    if (path == '/v1/runs') {
      if ((b['interests'] as List).isEmpty || (b['sites'] as List).isEmpty) {
        throw ApiException('invalid_request', 'Pick at least one job site and one interest to search.', status: 400);
      }
      final id = 'run_${_runs.length + 1}';
      _runs[id] = (startedAt: DateTime.now(), request: {...b}..remove('resumeId'));
      _subscription = {..._subscription, 'searchesUsed': (_subscription['searchesUsed'] as int) + 1};
      return {'runId': id};
    }
    if (path == '/v1/billing/checkout') {
      final plan = b['plan'] as String? ?? 'free';
      _subscription = {
        'plan': plan,
        'searchesUsed': 0,
        'renewsAt': plan == 'pro' ? DateTime.now().add(const Duration(days: 30)).toIso8601String() : null,
      };
      return {'subscription': _subscription};
    }
    final action = RegExp(r'^/v1/jobs/([^/]+)/(save|hide|applied|responded|interview)$').firstMatch(path);
    if (action != null) {
      final job = _jobs[action.group(1)!];
      if (job != null) {
        final key = switch (action.group(2)) {
          'save' => 'saved',
          'hide' => 'hidden',
          final a => a!,
        };
        job[key] = !(job[key] as bool? ?? false);
      }
      return const {};
    }
    if (RegExp(r'^/v1/runs/[^/]+/export$').hasMatch(path)) {
      await Future.delayed(const Duration(milliseconds: 900));
      return {
        'sheet': {'id': 'sheet_1', 'url': 'https://docs.google.com/spreadsheets/d/mock', 'rowsAdded': 50},
      };
    }
    throw ApiException('not_found', 'No mock for POST $path', status: 404);
  }

  @override
  Future<Map<String, dynamic>> patch(String path, {Object? body}) async {
    await Future.delayed(_latency);
    if (path == '/v1/me') {
      final b = (body as Map).cast<String, dynamic>();
      if (b['settings'] is Map) {
        _settings = {..._settings, ...(b['settings'] as Map).cast<String, dynamic>()};
      } else {
        _defaults = {..._defaults, ...b};
      }
      return {'defaults': _defaults, 'settings': _settings};
    }
    final auto = RegExp(r'^/v1/automations/([^/]+)$').firstMatch(path);
    if (auto != null) {
      final i = _automations.indexWhere((a) => a['id'] == auto.group(1));
      if (i >= 0) _automations[i] = {..._automations[i], ...(body as Map).cast<String, dynamic>()};
      return const {};
    }
    throw ApiException('not_found', 'No mock for PATCH $path', status: 404);
  }

  @override
  Future<void> delete(String path) async {
    await Future.delayed(_latency);
    _resumes.removeWhere((r) => path.endsWith(r['id'] as String));
    if (path.startsWith('/v1/automations/')) _automations.removeWhere((a) => path.endsWith(a['id'] as String));
  }

  Map<String, dynamic> _run(String id) {
    final r = _runs[id];
    if (r == null) throw ApiException('not_found', 'Run not found', status: 404);
    final elapsed = DateTime.now().difference(r.startedAt);
    final status = elapsed < const Duration(seconds: 1)
        ? 'queued'
        : elapsed < runDuration
        ? 'running'
        : 'done';
    final done = status == 'done';
    return {
      'id': id,
      'status': status,
      'resumeId': _resumes.isEmpty ? 'r_0' : _resumes.last['id'],
      'request': r.request,
      'stats': done
          ? {
              'fetched_unique': 143,
              'already_processed': 12,
              'scored': 131,
              'recommended': _jobs.values.where((j) => j['tier'] != 'skip').length,
              'recommended_per_site': {'LinkedIn': 5, 'JobStreet': 3, 'Kalibrr': 4, 'Indeed': 2, 'OnlineJobs.ph': 1},
            }
          : null,
      'sheet': null,
      'errorCode': null,
      'startedAt': r.startedAt.toIso8601String(),
      'finishedAt': done ? r.startedAt.add(runDuration).toIso8601String() : null,
    };
  }
}

final _rng = Random(7);

const _careerProfile = {
  'headline': 'Flutter developer · 3 years · fintech and HR tech',
  'yearsExperience': 3,
  'skills': ['Flutter', 'Dart', 'Firebase', 'Provider', 'REST APIs', 'CI/CD', 'Kotlin (basic)', 'SQL'],
  'experience': [
    {
      'title': 'Flutter Developer',
      'company': 'Kalibrr',
      'period': '2024 – now',
      'summary':
          'Owned the candidate app: onboarding, job search, offline sync. Shipped to both stores every two weeks.',
    },
    {
      'title': 'Junior Mobile Developer',
      'company': 'Xurpas',
      'period': '2023 – 2024',
      'summary': 'Built Flutter Web marketing sites and an internal HR tool with Firebase Auth.',
    },
  ],
  'education': [
    {
      'school': 'Polytechnic University of the Philippines',
      'degree': 'BS Information Technology',
      'period': '2019 – 2023',
    },
  ],
};

/// Two finished runs from earlier in the week, for the History tab.
final List<Map<String, dynamic>> _pastRuns = [
  {
    'id': 'run_past_1',
    'status': 'done',
    'resumeId': 'r_0',
    'request': {
      'interests': ['Flutter Developer', 'Mobile Engineer'],
      'sites': _sitesAll,
      'jobsPerSite': 20,
      'minScore': 60,
    },
    'stats': {
      'fetched_unique': 158,
      'already_processed': 0,
      'scored': 158,
      'recommended': 37,
      'recommended_per_site': {},
    },
    'sheet': {'id': 'sheet_1', 'url': 'https://docs.google.com/spreadsheets/d/mock', 'rowsAdded': 37},
    'errorCode': null,
    'startedAt': DateTime.now().subtract(const Duration(days: 3, hours: 2)).toIso8601String(),
    'finishedAt': DateTime.now().subtract(const Duration(days: 3, hours: 2, minutes: -1)).toIso8601String(),
  },
  {
    'id': 'run_past_2',
    'status': 'failed',
    'resumeId': 'r_0',
    'request': {
      'interests': ['Flutter Developer'],
      'sites': ['LinkedIn', 'JobStreet', 'Kalibrr'],
      'jobsPerSite': 20,
      'minScore': 60,
    },
    'stats': null,
    'sheet': null,
    'errorCode': 'engine_unavailable',
    'startedAt': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
    'finishedAt': DateTime.now().subtract(const Duration(days: 6, minutes: -2)).toIso8601String(),
  },
];

const _sitesAll = [
  'LinkedIn',
  'JobStreet',
  'Kalibrr',
  'Indeed',
  'OnlineJobs.ph',
  'BossJob',
  'Glassdoor',
  'ZipRecruiter',
  'Google Jobs',
  'Wellfound',
];
DateTime _ago(int days) => DateTime.now().subtract(Duration(days: days, hours: _rng.nextInt(20)));

/// Sample listings, also used by Home as placeholder content while the
/// real catalogue and job board are empty.
List<Map<String, dynamic>> get fixtureJobs => _fixtureJobs;

final List<Map<String, dynamic>> _fixtureJobs = [
  {
    'id': 'j1',
    'rank': 1,
    'score': 87,
    'tier': 'strong',
    'title': 'Senior Flutter Developer',
    'company': 'Sprout Solutions',
    'location': 'Makati',
    'remote': false,
    'salary': '₱85–110k',
    'postedAt': _ago(2).toIso8601String(),
    'url': 'https://www.kalibrr.com/c/sprout/jobs/1',
    'site': 'Kalibrr',
    'matchedInterest': 'Flutter Developer',
    'why':
        'Matches your Flutter and Firebase experience and the REST API integration work at your last role. Salary listed at ₱85–110k, within your range.',
    'redFlags': ['Requires on-site 3 days'],
    'saved': false,
    'hidden': false,
    'applied': false,
  },
  {
    'id': 'j2',
    'rank': 2,
    'score': 84,
    'tier': 'strong',
    'title': 'Mobile Engineer (Flutter)',
    'company': 'GCash',
    'location': 'Taguig',
    'remote': true,
    'salary': null,
    'postedAt': _ago(1).toIso8601String(),
    'url': 'https://www.linkedin.com/jobs/view/2',
    'site': 'LinkedIn',
    'matchedInterest': 'Mobile Engineer',
    'why':
        'Asks for 3+ years of Flutter, state management with Provider, and shipping to both stores — all on your resume. Fully remote within the Philippines.',
    'redFlags': ['Salary hidden'],
    'saved': true,
    'hidden': false,
    'applied': true,
    'responded': true,
    'interview': true,
  },
  {
    'id': 'j3',
    'rank': 3,
    'score': 81,
    'tier': 'strong',
    'title': 'Flutter Developer',
    'company': 'Maya',
    'location': 'Pasig',
    'remote': true,
    'salary': '₱70–95k',
    'postedAt': _ago(3).toIso8601String(),
    'url': 'https://www.jobstreet.com.ph/job/3',
    'site': 'JobStreet',
    'matchedInterest': 'Flutter Developer',
    'why':
        'Your Firebase Auth and Cloud Functions work maps directly to their stack. They mention Dart null-safety migration, which you led at Kalibrr.',
    'redFlags': [],
    'saved': false,
    'hidden': false,
    'applied': true,
  },
  {
    'id': 'j4',
    'rank': 4,
    'score': 74,
    'tier': 'good',
    'title': 'Software Engineer, Mobile',
    'company': 'Grab',
    'location': 'BGC',
    'remote': false,
    'salary': null,
    'postedAt': _ago(5).toIso8601String(),
    'url': 'https://www.indeed.com/viewjob?jk=4',
    'site': 'Indeed',
    'matchedInterest': 'Mobile Engineer',
    'why':
        'Strong on Flutter and CI/CD, but the listing leans Kotlin-first and wants Android-native experience you have less of.',
    'redFlags': ['Salary hidden', 'Kotlin preferred'],
    'saved': false,
    'hidden': false,
    'applied': false,
  },
  {
    'id': 'j5',
    'rank': 5,
    'score': 68,
    'tier': 'good',
    'title': 'Frontend Developer (Flutter Web)',
    'company': 'Xurpas',
    'location': 'Manila',
    'remote': true,
    'salary': '₱55–70k',
    'postedAt': _ago(6).toIso8601String(),
    'url': 'https://www.onlinejobs.ph/jobseekers/job/5',
    'site': 'OnlineJobs.ph',
    'matchedInterest': 'Flutter Developer',
    'why': 'Flutter Web is a match, but the role is mostly marketing sites and the salary sits under your range.',
    'redFlags': ['Below your salary range'],
    'saved': false,
    'hidden': false,
    'applied': false,
  },
  {
    'id': 'j6',
    'rank': 6,
    'score': 63,
    'tier': 'good',
    'title': 'React Native Developer',
    'company': 'Accenture',
    'location': 'Mandaluyong',
    'remote': false,
    'salary': null,
    'postedAt': _ago(9).toIso8601String(),
    'url': 'https://www.glassdoor.com/job/6',
    'site': 'Glassdoor',
    'matchedInterest': 'Mobile Engineer',
    'why':
        'Mobile experience carries over, but they want React Native specifically and your resume is Flutter throughout.',
    'redFlags': ['Different framework'],
    'saved': false,
    'hidden': false,
    'applied': false,
  },
  {
    'id': 'j7',
    'rank': 7,
    'score': 41,
    'tier': 'skip',
    'title': 'Junior Web Developer',
    'company': 'Startup PH',
    'location': 'Cebu',
    'remote': false,
    'salary': '₱25k',
    'postedAt': _ago(12).toIso8601String(),
    'url': 'https://bossjob.ph/job/7',
    'site': 'BossJob',
    'matchedInterest': 'Flutter Developer',
    'why': 'Entry-level PHP role. Your seniority and stack do not line up.',
    'redFlags': ['Unpaid trial task'],
    'saved': false,
    'hidden': false,
    'applied': false,
  },
  {
    'id': 'j8',
    'rank': 8,
    'score': 35,
    'tier': 'skip',
    'title': 'iOS Developer (Swift)',
    'company': 'Zalora',
    'location': 'Makati',
    'remote': false,
    'salary': null,
    'postedAt': _ago(14).toIso8601String(),
    'url': 'https://www.ziprecruiter.com/job/8',
    'site': 'ZipRecruiter',
    'matchedInterest': 'Mobile Engineer',
    'why': 'Swift-only. Nothing in the listing references cross-platform work.',
    'redFlags': [],
    'saved': false,
    'hidden': false,
    'applied': false,
  },
];
