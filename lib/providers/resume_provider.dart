import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/models/resume.dart';

class ResumeProvider extends ChangeNotifier {
  late ApiClient api;

  List<Resume> resumes = [];
  Resume? get latest => resumes.isEmpty ? null : resumes.first;
  double uploadProgress = 0;
  bool uploading = false;
  String? error;

  Future<void> load() async {
    final res = await api.get('/v1/resumes');
    resumes = (res['items'] as List).map((j) => Resume.fromJson(j)).toList();
    notifyListeners();
  }

  /// Uploads straight to Firebase Storage, then registers the file with the API.
  Future<Resume?> upload(File file, String filename) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = filename.split('.').last.toLowerCase();
    final path = 'resumes/$uid/$id.$ext';

    uploading = true;
    uploadProgress = 0;
    error = null;
    notifyListeners();
    try {
      final task = FirebaseStorage.instance.ref(path).putFile(file);
      task.snapshotEvents.listen((s) {
        uploadProgress = s.totalBytes == 0 ? 0 : s.bytesTransferred / s.totalBytes;
        notifyListeners();
      });
      await task;
      final size = await file.length();
      final res = await api.post('/v1/resumes', body: {'storagePath': path, 'filename': filename, 'sizeBytes': size});
      await load();
      return resumes.firstWhere((r) => r.id == res['resumeId']);
    } catch (e) {
      error = e is ApiException ? e.message : "We couldn't upload that file. Try again.";
      return null;
    } finally {
      uploading = false;
      notifyListeners();
    }
  }
}
