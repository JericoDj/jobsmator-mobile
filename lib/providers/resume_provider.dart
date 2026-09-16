import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/config.dart';
import '../core/models/resume.dart';

/// The user's resumes. Upload goes straight to Firebase Storage with
/// progress, then the file is registered with the API.
class ResumeProvider extends ChangeNotifier {
  ResumeProvider(this._api, {required this.uid});

  final ApiClient _api;
  final String? uid;

  List<Resume> _resumes = const [];
  bool _loaded = false;
  bool _uploading = false;
  double _progress = 0;

  List<Resume> get resumes => _resumes;
  Resume? get latest => _resumes.isEmpty ? null : _resumes.first;
  bool get loaded => _loaded;
  bool get uploading => _uploading;
  double get uploadProgress => _progress;

  Future<void> load() async {
    final res = await _api.get('/v1/resumes');
    _resumes = (res['items'] as List).map((j) => Resume.fromJson((j as Map).cast<String, dynamic>())).toList();
    _loaded = true;
    notifyListeners();
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
        final task = FirebaseStorage.instance.ref(path).putFile(file);
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

  Future<void> remove(Resume resume) async {
    await _api.delete('/v1/resumes/${resume.id}');
    _resumes = _resumes.where((r) => r.id != resume.id).toList();
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
