import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/config.dart';
import '../core/models/resume.dart';

/// The user's resumes. Upload goes straight to Firebase Storage with
/// progress, then the file is registered with the API. Also owns which
/// resume Home's Matches section is scoped to (persisted locally, since
/// the backend has no concept of a "selected" resume).
class ResumeProvider extends ChangeNotifier {
  ResumeProvider(this._api, this._prefs, {required this.uid}) : _selectedId = _prefs.getString(_selectedKey);

  static const _selectedKey = 'selected_resume_id';

  final ApiClient _api;
  final SharedPreferences _prefs;
  final String? uid;

  List<Resume> _resumes = const [];
  bool _loaded = false;
  bool _uploading = false;
  double _progress = 0;
  String? _selectedId;
  final Map<String, ResumeMatches> _matchesCache = {};

  List<Resume> get resumes => _resumes;
  Resume? get latest => _resumes.isEmpty ? null : _resumes.first;
  bool get loaded => _loaded;
  bool get uploading => _uploading;
  double get uploadProgress => _progress;

  Resume? byId(String id) => _resumes.where((r) => r.id == id).firstOrNull;

  /// The resume Matches is scoped to: whatever was explicitly picked, or
  /// the latest upload while nothing has been.
  String? get selectedId => _selectedId ?? latest?.id;
  Resume? get selected => selectedId == null ? null : byId(selectedId!);

  Future<void> select(String id) async {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
    await _prefs.setString(_selectedKey, id);
  }

  Future<void> load() async {
    final res = await _api.get('/v1/resumes');
    _resumes = (res['items'] as List).map((j) => Resume.fromJson((j as Map).cast<String, dynamic>())).toList();
    _loaded = true;
    notifyListeners();
  }

  /// Re-fetches a single resume — used while polling `analysisStatus`.
  Future<Resume> fetchOne(String id) async {
    final r = Resume.fromJson(await _api.get('/v1/resumes/$id'));
    _resumes = [for (final x in _resumes) x.id == id ? r : x];
    notifyListeners();
    return r;
  }

  /// `POST /v1/resumes/:id/analyze` — awaits a fresh analysis.
  Future<Resume> analyze(String id) async {
    final r = Resume.fromJson(await _api.post('/v1/resumes/$id/analyze'));
    _resumes = [for (final x in _resumes) x.id == id ? r : x];
    _matchesCache.remove(id); // tags likely changed
    notifyListeners();
    return r;
  }

  ResumeMatches? cachedMatches(String id) => _matchesCache[id];

  /// `GET /v1/resumes/:id/matches`. Cached per resume; pass [force] to
  /// refetch (e.g. after a re-analysis).
  Future<ResumeMatches> loadMatches(String id, {bool force = false}) async {
    if (!force) {
      final cached = _matchesCache[id];
      if (cached != null) return cached;
    }
    final res = await _api.get('/v1/resumes/$id/matches', query: {'limit': '10'});
    final m = ResumeMatches.fromJson(res);
    _matchesCache[id] = m;
    notifyListeners();
    return m;
  }

  /// Throws [ApiException] on API failure; storage errors surface as-is.
  Future<Resume> upload(File file, String filename) async {
    _uploading = true;
    _progress = 0;
    notifyListeners();
    try {
      final size = await file.length();
      final path = 'resumes/$uid/${DateTime.now().millisecondsSinceEpoch}.${filename.split('.').last.toLowerCase()}';
      if (AppConfig.preview) {
        await _fakeProgress();
      } else {
        final contentType = filename.toLowerCase().endsWith('.pdf') 
            ? 'application/pdf' 
            : (filename.toLowerCase().endsWith('.docx') ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' : null);
        final task = FirebaseStorage.instance.ref(path).putFile(
          file,
          contentType != null ? SettableMetadata(contentType: contentType) : null,
        );
        final sub = task.snapshotEvents.listen((s) {
          _progress = s.totalBytes == 0 ? 0 : s.bytesTransferred / s.totalBytes;
          notifyListeners();
        });
        await task;
        await sub.cancel();
      }
      final res = await _api.post('/v1/resumes', body: {'storagePath': path, 'filename': filename, 'sizeBytes': size});
      await load();
      return _resumes.firstWhere((r) => r.id == res['resumeId'], orElse: () => _resumes.first);
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  Future<Resume> addUrl(String url) async {
    _uploading = true;
    notifyListeners();
    try {
      final uri = Uri.parse(url);
      final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'resume.pdf';
      final res = await _api.post('/v1/resumes', body: {'url': url, 'filename': filename});
      await load();
      return _resumes.firstWhere((r) => r.id == res['resumeId'], orElse: () => _resumes.first);
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }

  Future<void> remove(Resume resume) async {
    await _api.delete('/v1/resumes/${resume.id}');
    _resumes = _resumes.where((r) => r.id != resume.id).toList();
    _matchesCache.remove(resume.id);
    if (_selectedId == resume.id) {
      _selectedId = null;
      await _prefs.remove(_selectedKey);
    }
    notifyListeners();
  }

  Future<void> _fakeProgress() async {
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 90));
      _progress = i / 10;
      notifyListeners();
    }
  }
}
