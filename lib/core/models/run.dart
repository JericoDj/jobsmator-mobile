enum RunStatus { queued, running, done, failed }

class RunStats {
  const RunStats({
    required this.fetchedUnique,
    required this.alreadyProcessed,
    required this.scored,
    required this.recommended,
    required this.perSite,
  });
  final int fetchedUnique, alreadyProcessed, scored, recommended;
  final Map<String, int> perSite;

  factory RunStats.fromJson(Map<String, dynamic> j) => RunStats(
    fetchedUnique: j['fetched_unique'] ?? 0,
    alreadyProcessed: j['already_processed'] ?? 0,
    scored: j['scored'] ?? 0,
    recommended: j['recommended'] ?? 0,
    perSite: (j['recommended_per_site'] as Map? ?? const {}).map((k, v) => MapEntry(k as String, v as int)),
  );
}

/// What the run was asked to do — the request body minus resumeId.
class RunRequest {
  const RunRequest({
    required this.interests,
    required this.sites,
    required this.jobsPerSite,
    this.minScore = 60,
    this.remoteOnly = false,
  });
  final List<String> interests, sites;
  final int jobsPerSite, minScore;
  final bool remoteOnly;

  factory RunRequest.fromJson(Map<String, dynamic> j) => RunRequest(
    interests: (j['interests'] as List? ?? const []).cast<String>(),
    sites: (j['sites'] as List? ?? const []).cast<String>(),
    jobsPerSite: j['jobsPerSite'] ?? 20,
    minScore: j['minScore'] ?? 60,
    remoteOnly: j['remoteOnly'] ?? false,
  );
}

class RunSheet {
  const RunSheet({this.id, this.url, this.rowsAdded});
  final String? id, url;
  final int? rowsAdded;

  factory RunSheet.fromJson(Map<String, dynamic> j) => RunSheet(id: j['id'], url: j['url'], rowsAdded: j['rowsAdded']);
}

class Run {
  const Run({
    required this.id,
    required this.status,
    required this.resumeId,
    required this.request,
    this.stats,
    this.sheet,
    this.errorCode,
    required this.startedAt,
    this.finishedAt,
  });

  final String id, resumeId;
  final RunStatus status;
  final RunRequest request;
  final RunStats? stats;
  final RunSheet? sheet;
  final String? errorCode;
  final DateTime startedAt;
  final DateTime? finishedAt;

  bool get isActive => status == RunStatus.queued || status == RunStatus.running;
  bool get isDone => status == RunStatus.done;
  bool get isFailed => status == RunStatus.failed;

  factory Run.fromJson(Map<String, dynamic> j) => Run(
    id: j['id'],
    status: RunStatus.values.byName(j['status']),
    resumeId: j['resumeId'],
    request: RunRequest.fromJson((j['request'] as Map? ?? const {}).cast<String, dynamic>()),
    stats: j['stats'] == null ? null : RunStats.fromJson((j['stats'] as Map).cast<String, dynamic>()),
    sheet: j['sheet'] == null ? null : RunSheet.fromJson((j['sheet'] as Map).cast<String, dynamic>()),
    errorCode: j['errorCode'],
    startedAt: DateTime.parse(j['startedAt']),
    finishedAt: j['finishedAt'] == null ? null : DateTime.parse(j['finishedAt']),
  );
}
