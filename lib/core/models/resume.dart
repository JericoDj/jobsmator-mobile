class Resume {
  const Resume({required this.id, required this.filename, required this.sizeBytes, required this.createdAt});
  final String id, filename;
  final int sizeBytes;
  final DateTime createdAt;

  String get extension => filename.contains('.') ? filename.split('.').last.toUpperCase() : 'FILE';

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).round()} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Resume.fromJson(Map<String, dynamic> j) => Resume(
    id: j['id'],
    filename: j['filename'],
    sizeBytes: j['sizeBytes'],
    createdAt: DateTime.parse(j['createdAt']),
  );
}
