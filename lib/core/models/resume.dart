import 'job.dart';

/// Where a resume's AI read stands. Missing on old API responses reads as
/// `pending` (or `failed` if the server already reported an error), never
/// as `done` — the UI should never claim an analysis it hasn't seen.
enum ResumeAnalysisStatus {
  pending,
  done,
  failed;

  static ResumeAnalysisStatus parse(String? v) =>
      ResumeAnalysisStatus.values.firstWhere((s) => s.name == v, orElse: () => ResumeAnalysisStatus.pending);
}

/// What the engine read out of a resume — see PLAN.md "Shared API
/// contracts". Every list is capped server-side; parsed defensively here
/// too since the model behind it can misbehave.
class ResumeAnalysis {
  const ResumeAnalysis({
    this.summary = '',
    this.headline = '',
    this.seniority = '',
    this.strengths = const [],
    this.fixes = const [],
    this.skills = const [],
    this.roles = const [],
    this.tags = const [],
    this.industries = const [],
  });

  final String summary, headline, seniority;
  final List<String> strengths, fixes, skills, roles, tags, industries;

  factory ResumeAnalysis.fromJson(Map<String, dynamic> j) => ResumeAnalysis(
    summary: j['summary'] as String? ?? '',
    headline: j['headline'] as String? ?? '',
    seniority: j['seniority'] as String? ?? '',
    strengths: (j['strengths'] as List? ?? const []).cast<String>(),
    fixes: (j['fixes'] as List? ?? const []).cast<String>(),
    skills: (j['skills'] as List? ?? const []).cast<String>(),
    roles: (j['roles'] as List? ?? const []).cast<String>(),
    tags: (j['tags'] as List? ?? const []).cast<String>(),
    industries: (j['industries'] as List? ?? const []).cast<String>(),
  );
}

class Resume {
  const Resume({
    required this.id,
    required this.filename,
    this.sizeBytes,
    required this.createdAt,
    this.analysis,
    this.analyzedAt,
    this.analysisStatus = ResumeAnalysisStatus.pending,
  });
  final String id, filename;
  final int? sizeBytes;
  final DateTime createdAt;
  final ResumeAnalysis? analysis;
  final DateTime? analyzedAt;
  final ResumeAnalysisStatus analysisStatus;

  String get extension => filename.contains('.') ? filename.split('.').last.toUpperCase() : 'LINK';

  String get sizeLabel {
    if (sizeBytes == null) return 'LINK';
    if (sizeBytes! < 1024) return '$sizeBytes B';
    if (sizeBytes! < 1024 * 1024) return '${(sizeBytes! / 1024).round()} KB';
    return '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Resume.fromJson(Map<String, dynamic> j) {
    final rawAnalysis = j['analysis'];
    final analysis = rawAnalysis is Map ? ResumeAnalysis.fromJson(rawAnalysis.cast<String, dynamic>()) : null;
    // Older/partial payloads may not send analysisStatus at all — infer it
    // from what else is on the resume rather than assuming success.
    final status = j['analysisStatus'] != null
        ? ResumeAnalysisStatus.parse(j['analysisStatus'] as String)
        : j['analysisError'] != null
        ? ResumeAnalysisStatus.failed
        : analysis != null
        ? ResumeAnalysisStatus.done
        : ResumeAnalysisStatus.pending;
    return Resume(
      id: j['id'],
      filename: j['filename'],
      sizeBytes: j['sizeBytes'],
      createdAt: DateTime.parse(j['createdAt']),
      analysis: analysis,
      analyzedAt: j['analyzedAt'] == null ? null : DateTime.tryParse(j['analyzedAt']),
      analysisStatus: status,
    );
  }
}

/// `GET /v1/resumes/:id/matches` — jobs ranked against one resume's tags.
class ResumeMatches {
  const ResumeMatches({this.items = const [], this.tags = const []});
  final List<Job> items;
  final List<String> tags;

  factory ResumeMatches.fromJson(Map<String, dynamic> j) => ResumeMatches(
    items: (j['items'] as List? ?? const [])
        .map((e) => Job.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    tags: (j['tags'] as List? ?? const []).cast<String>(),
  );
}
