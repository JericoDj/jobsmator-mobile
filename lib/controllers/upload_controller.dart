import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/config.dart';
import '../core/models/resume.dart';
import '../providers/resume_provider.dart';

const _maxBytes = 10 * 1024 * 1024;

/// Step 1. Picks a PDF/DOCX and hands it to [ResumeProvider]; exposes the
/// one error line the dropzone shows. Navigation is the screen's job.
class UploadController extends ChangeNotifier {
  UploadController(this._resumes) {
    scheduleMicrotask(() {
      if (!_resumes.loaded) _resumes.load().catchError((_) {});
    });
  }

  final ResumeProvider _resumes;

  String? _error;
  String? get error => _error;

  /// Returns the registered resume, or null if the user cancelled or it failed.
  Future<Resume?> pickAndUpload() async {
    _error = null;
    notifyListeners();
    final (file, name) = AppConfig.preview ? await _previewFile() : await _pick();
    if (file == null || name == null) return null;
    try {
      return await _resumes.upload(file, name);
    } catch (e) {
      _error = messageOf(e, fallback: "We couldn't upload that file. Check your connection and try again.");
      notifyListeners();
      return null;
    }
  }

  Future<(File?, String?)> _pick() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx']);
    final f = result?.files.single;
    if (f == null || f.path == null) return (null, null);
    if (f.size > _maxBytes) {
      _error = 'That file is over 10 MB. Export a smaller PDF and try again.';
      notifyListeners();
      return (null, null);
    }
    return (File(f.path!), f.name);
  }

  /// Preview builds have no document picker; stand in a small fake PDF.
  Future<(File?, String?)> _previewFile() async {
    final file = File('${Directory.systemTemp.path}/jobsmator-preview-resume.pdf');
    if (!file.existsSync()) await file.writeAsBytes(List.filled(184 * 1024, 0x20));
    return (file, 'Jerico-De-Jesus-Resume.pdf');
  }

  Future<void> remove(Resume resume) async {
    try {
      await _resumes.remove(resume);
    } catch (e) {
      _error = messageOf(e, fallback: "We couldn't remove that resume. Try again.");
      notifyListeners();
    }
  }
}
