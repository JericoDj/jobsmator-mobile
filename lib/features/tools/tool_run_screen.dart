import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../controllers/tool_run_controller.dart';
import '../../providers/resume_provider.dart';
import '../shared/widgets/badges.dart';
import '../shared/widgets/jm_buttons.dart';
import '../shared/widgets/jm_page.dart';
import '../shared/widgets/jm_toast.dart';

/// Generic tool runner: one input, one primary action, one result card.
class ToolRunScreen extends StatefulWidget {
  const ToolRunScreen({super.key});

  @override
  State<ToolRunScreen> createState() => _ToolRunScreenState();
}

class _ToolRunScreenState extends State<ToolRunScreen> {
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: context.read<ToolRunController>().input);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final ctrl = context.read<ToolRunController>();
    if (ctrl.locked) {
      await context.push(AppRoutes.subscribe);
      if (!mounted || ctrl.locked) return;
    }
    ctrl.input = _input.text;
    FocusScope.of(context).unfocus();
    await ctrl.run();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ToolRunController>();
    final hasResume = context.watch<ResumeProvider>().latest != null;
    final c = context.jm;
    final tool = ctrl.tool;
    final needsResume = tool.needsResume && !hasResume;

    return JmPage(
      appBar: AppBar(title: Text(tool.title)),
      bottom: ctrl.result != null
          ? Row(
              children: [
                Expanded(
                  child: SecondaryButton(label: 'Run again', icon: Icons.refresh_rounded, onPressed: ctrl.reset),
                ),
                const SizedBox(width: JmSpace.x2),
                Expanded(
                  child: PrimaryButton(
                    label: 'Copy',
                    icon: Icons.copy_rounded,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: ctrl.result!));
                      if (context.mounted) showJmToast(context, title: 'Copied', tone: ToastTone.success);
                    },
                  ),
                ),
              ],
            )
          : PrimaryButton(
              label: ctrl.locked ? '${tool.action} · Pro' : tool.action,
              busyLabel: 'Working…',
              busy: ctrl.busy,
              large: true,
              icon: ctrl.locked ? Icons.lock_outline_rounded : Icons.auto_awesome_rounded,
              onPressed: needsResume ? null : _run,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c.oceanTint, borderRadius: BorderRadius.circular(11)),
                child: Icon(tool.icon, color: c.oceanDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(tool.blurb, style: context.type.body.copyWith(color: c.muted)),
              ),
            ],
          ),
          const SizedBox(height: JmSpace.x6),
          if (needsResume)
            Container(
              margin: const EdgeInsets.only(bottom: JmSpace.x4),
              padding: const EdgeInsets.all(JmSpace.x4),
              decoration: BoxDecoration(color: c.warnTint, borderRadius: JmRadius.mdR),
              child: Row(
                children: [
                  Icon(Icons.upload_file_rounded, color: c.warn),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This tool reads your resume. Upload one first.',
                      style: context.type.ui.copyWith(color: c.ink),
                    ),
                  ),
                  TextButton(onPressed: () => context.go(AppRoutes.upload), child: const Text('Upload')),
                ],
              ),
            ),
          if (ctrl.result == null) ...[
            TextField(
              controller: _input,
              minLines: 3,
              maxLines: 10,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: tool.inputLabel,
                hintText: tool.inputHint,
                alignLabelWithHint: true,
              ),
            ),
            if (ctrl.error != null) ...[const SizedBox(height: JmSpace.x3), ErrorLine(ctrl.error!)],
            if (ctrl.locked) ...[
              const SizedBox(height: JmSpace.x4),
              Text('${tool.title} is a Pro tool. Tap the button to see the plans.', style: context.type.meta),
            ],
          ] else ...[
            JmLabel('Result', color: c.muted),
            const SizedBox(height: JmSpace.x2),
            Container(
              padding: const EdgeInsets.all(JmSpace.x4),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: JmRadius.lgR,
                border: Border.all(color: c.line),
                boxShadow: c.shadow,
              ),
              child: _LightMarkdown(ctrl.result!),
            ),
            const SizedBox(height: JmSpace.x3),
            Text('Drafts are a starting point — read before you send.', style: context.type.meta),
          ],
        ],
      ),
    );
  }
}

/// Bold runs (**x**) and paragraphs; enough for tool output without a
/// markdown dependency.
class _LightMarkdown extends StatelessWidget {
  const _LightMarkdown(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final base = context.type.body.copyWith(fontSize: 15);
    final bold = base.copyWith(fontWeight: FontWeight.w600, color: context.jm.ink);
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(TextSpan(text: m.group(1), style: bold));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return SelectableText.rich(TextSpan(style: base, children: spans));
  }
}
