import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/upload_controller.dart';
import '../../providers/resume_provider.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_logo_mark.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/step_header.dart';
import 'widgets/dropzone.dart';
import 'widgets/resume_tile.dart';

/// Step 1. Dropzone and nothing else — parsing starts on the run.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _urlCtrl = TextEditingController();

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(BuildContext context) async {
    final resume = await context.read<UploadController>().pickAndUpload();
    if (resume != null && context.mounted) context.go(AppRoutes.interests);
  }

  Future<void> _addUrl(BuildContext context) async {
    var url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    final resume = await context.read<UploadController>().addUrl(url);
    if (resume != null && context.mounted) {
      _urlCtrl.clear();
      context.go(AppRoutes.interests);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UploadController>();
    final resumes = context.watch<ResumeProvider>();
    final latest = resumes.latest;
    final c = context.jm;

    return JmPage(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.jobs)),
        title: const JmWordmark(size: 24),
      ),
      bottom: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: JmSpace.x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (latest != null) ...[
                PrimaryButton(
                  label: 'Continue with ${latest.filename.length > 24 ? 'this resume' : latest.filename}',
                  large: true,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: resumes.uploading ? null : () => context.go(AppRoutes.interests),
                ),
                const SizedBox(height: JmSpace.x2),
              ],
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text('Skip for now', style: context.type.meta),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StepHeader(
            step: 1,
            title: 'Start with your resume',
            lede: 'We read it once to learn your skills, then search ten job sites for roles that actually fit.',
          ),
          const SizedBox(height: JmSpace.x6),
          Dropzone(onTap: () => _pick(context), uploading: resumes.uploading, progress: resumes.uploadProgress),
          const SizedBox(height: JmSpace.x4),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: context.type.meta)),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: JmSpace.x4),
          TextField(
            controller: _urlCtrl,
            decoration: InputDecoration(
              labelText: 'Paste a link to your resume',
              hintText: 'https://...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: resumes.uploading ? null : () => _addUrl(context),
              ),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            onSubmitted: resumes.uploading ? null : (_) => _addUrl(context),
            enabled: !resumes.uploading,
          ),
          if (ctrl.error != null) ...[const SizedBox(height: JmSpace.x3), ErrorLine(ctrl.error!)],
          if (resumes.resumes.isNotEmpty) ...[
            const SizedBox(height: JmSpace.x8),
            JmLabel('On file', color: c.muted),
            const SizedBox(height: JmSpace.x3),
            for (final (i, r) in resumes.resumes.indexed) ...[
              if (i > 0) const SizedBox(height: JmSpace.x2),
              ResumeTile(resume: r, current: r.id == latest?.id, onRemove: () => ctrl.remove(r)),
            ],
          ],
          const SizedBox(height: JmSpace.x8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 16, color: c.faint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your resume is private. Only you and the search engine can read it, and you can remove it any time.',
                  style: context.type.meta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
