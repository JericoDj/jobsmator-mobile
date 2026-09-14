import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/resume_provider.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  Future<void> _pick(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'docx']);
    final f = result?.files.single;
    if (f?.path == null || !context.mounted) return;
    final resume = await context.read<ResumeProvider>().upload(File(f!.path!), f.name);
    if (resume != null && context.mounted) context.go('/interests');
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ResumeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Upload your resume')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Step 1 of 3', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 24),
            if (rp.uploading) LinearProgressIndicator(value: rp.uploadProgress),
            if (rp.error != null) Text(rp.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const Spacer(),
            FilledButton(onPressed: rp.uploading ? null : () => _pick(context), child: const Text('Choose PDF or DOCX')),
          ],
        ),
      ),
    );
  }
}
