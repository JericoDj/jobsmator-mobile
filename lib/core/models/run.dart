enum RunStatus { queued, running, done, failed }

class RunStats {
  RunStats({required this.fetchedUnique, required this.scored, required this.recommended, required this.perSite});
  final int fetchedUnique, scored, recommended;
  final Map<String, int> perSite;
  factory RunStats.fromJson(Map<String, dynamic> j) => RunStats(
        fetchedUnique: j['fetched_unique'] ?? 0, scored: j['scored'] ?? 0, recommended: j['recommended'] ?? 0,
        perSite: (j['recommended_per_site'] as Map? ?? const {}).cast<String, int>(),
      );
}

class Run {
  Run({required this.id, required this.status, required this.resumeId, this.stats, this.errorCode, this.sheetUrl, required this.startedAt, this.finishedAt});
  final String id, resumeId;
  final RunStatus status;
  final RunStats? stats;
  final String? errorCode, sheetUrl;
  final DateTime startedAt;
  final DateTime? finishedAt;

  bool get isActive => status == RunStatus.queued || status == RunStatus.running;

  factory Run.fromJson(Map<String, dynamic> j) => Run(
        id: j['id'], status: RunStatus.values.byName(j['status']), resumeId: j['resumeId'],
        stats: j['stats'] == null ? null : RunStats.fromJson(j['stats']),
        errorCode: j['errorCode'], sheetUrl: (j['sheet'] as Map?)?['url'],
        startedAt: DateTime.parse(j['startedAt']),
        finishedAt: j['finishedAt'] == null ? null : DateTime.parse(j['finishedAt']),
      );
}
