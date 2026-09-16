/// What the engine learned from the resume. Read-only in the app for now;
/// the user edits the resume, not the profile.
class CareerProfile {
  const CareerProfile({
    this.headline = '',
    this.skills = const [],
    this.experience = const [],
    this.education = const [],
    this.yearsExperience,
  });

  final String headline;
  final List<String> skills;
  final List<ExperienceEntry> experience;
  final List<EducationEntry> education;
  final int? yearsExperience;

  bool get isEmpty => skills.isEmpty && experience.isEmpty && education.isEmpty;

  factory CareerProfile.fromJson(Map<String, dynamic> j) => CareerProfile(
    headline: j['headline'] ?? '',
    skills: (j['skills'] as List? ?? const []).cast<String>(),
    experience: (j['experience'] as List? ?? const [])
        .map((e) => ExperienceEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    education: (j['education'] as List? ?? const [])
        .map((e) => EducationEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    yearsExperience: j['yearsExperience'],
  );
}

class ExperienceEntry {
  const ExperienceEntry({required this.title, required this.company, required this.period, this.summary = ''});
  final String title, company, period, summary;
  factory ExperienceEntry.fromJson(Map<String, dynamic> j) => ExperienceEntry(
    title: j['title'] ?? '',
    company: j['company'] ?? '',
    period: j['period'] ?? '',
    summary: j['summary'] ?? '',
  );
}

class EducationEntry {
  const EducationEntry({required this.school, required this.degree, required this.period});
  final String school, degree, period;
  factory EducationEntry.fromJson(Map<String, dynamic> j) =>
      EducationEntry(school: j['school'] ?? '', degree: j['degree'] ?? '', period: j['period'] ?? '');
}
