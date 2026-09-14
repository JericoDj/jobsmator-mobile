class Resume {
  Resume({required this.id, required this.filename, required this.sizeBytes, required this.createdAt});
  final String id, filename;
  final int sizeBytes;
  final DateTime createdAt;
  factory Resume.fromJson(Map<String, dynamic> j) =>
      Resume(id: j['id'], filename: j['filename'], sizeBytes: j['sizeBytes'], createdAt: DateTime.parse(j['createdAt']));
}
