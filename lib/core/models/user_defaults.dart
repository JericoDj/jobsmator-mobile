/// Job sites the engine can search, in the order the guide shows them.
const jobSites = [
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

const maxInterests = 5;

enum WorkMode {
  any,
  remote,
  hybrid,
  onsite;

  String get label => switch (this) {
    any => 'Any',
    remote => 'Remote',
    hybrid => 'Hybrid',
    onsite => 'On-site',
  };
}

enum EmploymentType {
  any,
  fullTime,
  partTime,
  contract;

  String get label => switch (this) {
    any => 'Any',
    fullTime => 'Full-time',
    partTime => 'Part-time',
    contract => 'Contract',
  };
}

/// Saved search preferences from `GET /v1/me`.
class UserDefaults {
  const UserDefaults({
    this.interests = const [],
    this.sites = jobSites,
    this.jobsPerSite = 20,
    this.location = 'Philippines',
    this.remoteOnly = false,
    this.minScore = 60,
    this.salaryMin,
    this.workMode = WorkMode.any,
    this.employmentType = EmploymentType.any,
  });

  final List<String> interests, sites;
  final int jobsPerSite, minScore;
  final String location;
  final bool remoteOnly;

  /// Monthly, in the user's currency (₱ for now). Null = no floor.
  final int? salaryMin;
  final WorkMode workMode;
  final EmploymentType employmentType;

  factory UserDefaults.fromJson(Map<String, dynamic> j) {
    final sites = (j['sites'] as List?)?.cast<String>();
    return UserDefaults(
      interests: (j['interests'] as List? ?? const []).cast<String>(),
      sites: sites == null || sites.isEmpty ? jobSites : sites,
      jobsPerSite: j['jobsPerSite'] ?? 20,
      location: j['location'] ?? 'Philippines',
      remoteOnly: j['remoteOnly'] ?? false,
      minScore: j['minScore'] ?? 60,
      salaryMin: j['salaryMin'],
      workMode: WorkMode.values.byName(j['workMode'] ?? 'any'),
      employmentType: EmploymentType.values.byName(j['employmentType'] ?? 'any'),
    );
  }

  Map<String, dynamic> toJson() => {
    'interests': interests,
    'sites': sites,
    'jobsPerSite': jobsPerSite,
    'location': location,
    'remoteOnly': remoteOnly,
    'minScore': minScore,
  };

  UserDefaults copyWith({
    List<String>? interests,
    List<String>? sites,
    int? jobsPerSite,
    String? location,
    bool? remoteOnly,
    int? minScore,
    int? salaryMin,
    bool clearSalary = false,
    WorkMode? workMode,
    EmploymentType? employmentType,
  }) => UserDefaults(
    interests: interests ?? this.interests,
    sites: sites ?? this.sites,
    jobsPerSite: jobsPerSite ?? this.jobsPerSite,
    location: location ?? this.location,
    remoteOnly: remoteOnly ?? this.remoteOnly,
    minScore: minScore ?? this.minScore,
  );
}
