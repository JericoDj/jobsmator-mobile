enum Tier { strong, good, skip }

class Job {
  Job({
    required this.id, required this.rank, required this.score, required this.tier, required this.title,
    required this.company, required this.location, required this.remote, this.salary, this.postedAt,
    required this.url, required this.site, required this.matchedInterest, required this.why,
    required this.redFlags, required this.saved, required this.hidden,
  });

  final String id;
  final int rank, score;
  final Tier tier;
  final String title, company, location, url, site, matchedInterest, why;
  final bool remote, saved, hidden;
  final String? salary;
  final DateTime? postedAt;
  final List<String> redFlags;

  factory Job.fromJson(Map<String, dynamic> j) => Job(
        id: j['id'], rank: j['rank'], score: j['score'],
        tier: Tier.values.byName(j['tier']),
        title: j['title'], company: j['company'] ?? '', location: j['location'] ?? '',
        remote: j['remote'] ?? false, salary: j['salary'],
        postedAt: j['postedAt'] == null ? null : DateTime.tryParse(j['postedAt']),
        url: j['url'], site: j['site'], matchedInterest: j['matchedInterest'] ?? '', why: j['why'] ?? '',
        redFlags: (j['redFlags'] as List? ?? const []).cast<String>(),
        saved: j['saved'] ?? false, hidden: j['hidden'] ?? false,
      );

  Job copyWith({bool? saved, bool? hidden}) => Job(
        id: id, rank: rank, score: score, tier: tier, title: title, company: company, location: location,
        remote: remote, salary: salary, postedAt: postedAt, url: url, site: site, matchedInterest: matchedInterest,
        why: why, redFlags: redFlags, saved: saved ?? this.saved, hidden: hidden ?? this.hidden,
      );
}
