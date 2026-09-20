/// strong ≥ 70 · good ≥ minScore · skip below. The word "skip" never appears
/// in the UI — those jobs are collapsed under "Show N weaker matches".
enum Tier {
  strong,
  good,
  skip;

  String get label => switch (this) {
    strong => 'Strong',
    good => 'Good',
    skip => 'Weaker',
  };
}

class Job {
  const Job({
    required this.id,
    this.runId,
    required this.rank,
    required this.score,
    required this.tier,
    required this.title,
    required this.company,
    required this.location,
    required this.remote,
    this.salary,
    this.postedAt,
    required this.url,
    required this.site,
    required this.matchedInterest,
    this.industry = '',
    this.expired = false,
    required this.why,
    required this.redFlags,
    required this.saved,
    required this.hidden,
    required this.applied,
    this.responded = false,
    this.interview = false,
    this.coverLetter,
  });

  final String id;
  final String? runId;
  final int rank, score;
  final Tier tier;
  final String title, company, location, url, site, matchedInterest, why;

  /// Broad sector label from the API ("Software & IT", "Healthcare"…); '' when unknown.
  final String industry;

  /// The source listing was gone (404/410) when the API last checked.
  final bool expired;
  final bool remote, saved, hidden, applied;

  /// Application tracking after [applied]: the company replied; you had an
  /// interview.
  final bool responded, interview;
  final String? salary;
  final String? coverLetter;
  final DateTime? postedAt;
  final List<String> redFlags;

  factory Job.fromJson(Map<String, dynamic> j) {
    final int score = j['score'];
    final backendTier = Tier.values.byName(j['tier'] ?? 'skip');

    // Always enforce the 70+ rule on the client side, so old jobs update
    // instantly without needing a database migration.
    final tier = backendTier == Tier.skip
        ? Tier.skip
        : score >= 70
        ? Tier.strong
        : Tier.good;

    return Job(
      id: j['id'],
      runId: j['runId'],
      rank: j['rank'],
      score: score,
      tier: tier,
      title: j['title'],
      company: j['company'] ?? '',
      location: j['location'] ?? '',
      remote: j['remote'] ?? false,
      salary: j['salary'],
      coverLetter: j['coverLetter'],
      postedAt: j['postedAt'] == null ? null : DateTime.tryParse(j['postedAt']),
      url: j['url'],
      site: j['site'],
      matchedInterest: j['matchedInterest'] ?? '',
      industry: j['industry'] ?? '',
      expired: j['expired'] == true,
      why: j['why'] ?? '',
      redFlags: (j['redFlags'] as List? ?? const []).cast<String>(),
      saved: j['saved'] ?? false,
      hidden: j['hidden'] ?? false,
      applied: j['applied'] ?? false,
      responded: j['responded'] ?? false,
      interview: j['interview'] ?? false,
    );
  }

  Job copyWith({
    bool? saved,
    bool? hidden,
    bool? applied,
    bool? responded,
    bool? interview,
    String? coverLetter,
  }) => Job(
    id: id,
    runId: runId,
    rank: rank,
    score: score,
    tier: tier,
    title: title,
    company: company,
    location: location,
    remote: remote,
    salary: salary,
    coverLetter: coverLetter ?? this.coverLetter,
    postedAt: postedAt,
    url: url,
    site: site,
    matchedInterest: matchedInterest,
    industry: industry,
    expired: expired,
    why: why,
    redFlags: redFlags,
    saved: saved ?? this.saved,
    hidden: hidden ?? this.hidden,
    applied: applied ?? this.applied,
    responded: responded ?? this.responded,
    interview: interview ?? this.interview,
  );
}
