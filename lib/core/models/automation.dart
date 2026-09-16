/// A scheduled search the engine runs on the user's behalf.
class Automation {
  const Automation({
    required this.id,
    required this.name,
    required this.schedule,
    required this.enabled,
    this.lastRunAt,
    this.nextRunAt,
    this.lastResultCount,
  });

  final String id, name, schedule;
  final bool enabled;
  final DateTime? lastRunAt, nextRunAt;
  final int? lastResultCount;

  factory Automation.fromJson(Map<String, dynamic> j) => Automation(
    id: j['id'],
    name: j['name'] ?? '',
    schedule: j['schedule'] ?? '',
    enabled: j['enabled'] ?? false,
    lastRunAt: j['lastRunAt'] == null ? null : DateTime.tryParse(j['lastRunAt']),
    nextRunAt: j['nextRunAt'] == null ? null : DateTime.tryParse(j['nextRunAt']),
    lastResultCount: j['lastResultCount'],
  );

  Automation copyWith({bool? enabled}) => Automation(
    id: id,
    name: name,
    schedule: schedule,
    enabled: enabled ?? this.enabled,
    lastRunAt: lastRunAt,
    nextRunAt: nextRunAt,
    lastResultCount: lastResultCount,
  );
}

/// Notification + AI preferences (Profile › Automation settings).
class AutomationSettings {
  const AutomationSettings({
    this.notifyNewMatches = true,
    this.notifyApplications = true,
    this.dailyDigest = false,
    this.digestHour = 8,
    this.aiTone = 'Direct',
    this.autoApplyDrafts = false,
  });

  final bool notifyNewMatches, notifyApplications, dailyDigest, autoApplyDrafts;
  final int digestHour;
  final String aiTone;

  static const tones = ['Direct', 'Warm', 'Formal'];

  factory AutomationSettings.fromJson(Map<String, dynamic> j) => AutomationSettings(
    notifyNewMatches: j['notifyNewMatches'] ?? true,
    notifyApplications: j['notifyApplications'] ?? true,
    dailyDigest: j['dailyDigest'] ?? false,
    digestHour: j['digestHour'] ?? 8,
    aiTone: j['aiTone'] ?? 'Direct',
    autoApplyDrafts: j['autoApplyDrafts'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'notifyNewMatches': notifyNewMatches,
    'notifyApplications': notifyApplications,
    'dailyDigest': dailyDigest,
    'digestHour': digestHour,
    'aiTone': aiTone,
    'autoApplyDrafts': autoApplyDrafts,
  };

  AutomationSettings copyWith({
    bool? notifyNewMatches,
    bool? notifyApplications,
    bool? dailyDigest,
    int? digestHour,
    String? aiTone,
    bool? autoApplyDrafts,
  }) => AutomationSettings(
    notifyNewMatches: notifyNewMatches ?? this.notifyNewMatches,
    notifyApplications: notifyApplications ?? this.notifyApplications,
    dailyDigest: dailyDigest ?? this.dailyDigest,
    digestHour: digestHour ?? this.digestHour,
    aiTone: aiTone ?? this.aiTone,
    autoApplyDrafts: autoApplyDrafts ?? this.autoApplyDrafts,
  );
}
