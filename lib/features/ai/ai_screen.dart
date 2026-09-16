import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/theme.dart';
import '../../core/ai/ai_service.dart';
import '../../providers/ai_provider.dart';
import '../shared/widgets/art_tile.dart';
import '../shared/widgets/jm_robot.dart';

/// The assistant. Empty state is the prompt plus suggested actions; once
/// there is a thread it becomes a plain conversation. Suggestions that map
/// to a flow or tool go straight there instead of round-tripping the chat.
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final ai = context.read<AiProvider>();
    final t = text ?? _input.text;
    if (t.trim().isEmpty) return;
    _input.clear();
    await ai.send(t);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: JmMotion.enterExit, curve: JmMotion.ease);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    final c = context.jm;
    final gutter = JmSpace.gutter(MediaQuery.sizeOf(context).width);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ai.isEmpty
                      ? _EmptyPrompt(onSuggest: _send)
                      : ListView.builder(
                          controller: _scroll,
                          padding: EdgeInsets.fromLTRB(gutter, JmSpace.x4, gutter, JmSpace.x4),
                          itemCount: ai.messages.length + (ai.thinking ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == ai.messages.length) return const _Thinking();
                            return _Bubble(message: ai.messages[i]);
                          },
                        ),
                  if (!ai.isEmpty)
                    Positioned(
                      top: JmSpace.x2,
                      right: gutter - 8,
                      child: IconButton(
                        tooltip: 'New conversation',
                        onPressed: ai.clear,
                        icon: const Icon(Icons.add_comment_outlined),
                        style: IconButton.styleFrom(backgroundColor: c.ground.withValues(alpha: .9)),
                      ),
                    ),
                ],
              ),
            ),
            if (ai.error != null)
              Padding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, JmSpace.x2),
                child: Text(ai.error!, style: context.type.meta.copyWith(color: c.danger)),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.ground,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, JmSpace.x3, gutter, JmSpace.x3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(hintText: 'Ask anything about your search…'),
                      ),
                    ),
                    const SizedBox(width: JmSpace.x2),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton.filled(
                        tooltip: 'Send',
                        onPressed: ai.thinking ? null : _send,
                        icon: const Icon(Icons.arrow_upward_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: c.ocean,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: JmRadius.mdR),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt({required this.onSuggest});
  final ValueChanged<String> onSuggest;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final gutter = JmSpace.gutter(MediaQuery.sizeOf(context).width);
    final suggestions = <(IconData, String, String, ArtHue, VoidCallback)>[
      (
        Icons.search_rounded,
        'Find matching jobs',
        'Ten sites, ranked with reasons.',
        ArtHue.ocean,
        () => context.go(AppRoutes.upload),
      ),
      (
        Icons.description_outlined,
        'Analyze my resume',
        'What recruiters see first.',
        ArtHue.sky,
        () => context.push(AppRoutes.tool('resume-analyzer')),
      ),
      (
        Icons.track_changes_rounded,
        'Analyze this job',
        'Score one listing against you.',
        ArtHue.match,
        () => context.push(AppRoutes.tool('job-match')),
      ),
      (
        Icons.mail_outline_rounded,
        'Write an application',
        'Short, specific, in your voice.',
        ArtHue.volt,
        () => context.push(AppRoutes.tool('application-email')),
      ),
      (
        Icons.record_voice_over_outlined,
        'Prepare me for interview',
        'Likely questions, strong answers.',
        ArtHue.ocean,
        () => context.push(AppRoutes.tool('interview-prep')),
      ),
      (
        Icons.payments_outlined,
        'What should I earn?',
        'A realistic range for your level.',
        ArtHue.sky,
        () => context.push(AppRoutes.tool('salary')),
      ),
    ];
    final header = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: JmLayout.reading),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Same shape as the other tabs' headers, with the robot as
            // the leading mark instead of a trailing control.
            Row(
              children: [
                const JmRobot(size: 36),
                const SizedBox(width: JmSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How can I help?', style: context.type.title.copyWith(fontSize: 22)),
                      const SizedBox(height: 2),
                      Text(
                        'Ask about your resume or any job found.',
                        style: context.type.body.copyWith(color: c.muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: JmSpace.x4),
            _Example(text: 'Find me remote Flutter jobs paying at least ₱80k a month.', onTap: onSuggest),
            const SizedBox(height: JmSpace.x6),
            JmLabel('Suggested', color: c.muted),
            const SizedBox(height: JmSpace.x3),
          ],
        ),
      ),
    );
    // The cards scroll sideways in one row, bleeding to the screen edges so
    // the next card peeks in and invites a swipe.
    return ListView(
      padding: EdgeInsets.only(top: JmSpace.x4, bottom: JmSpace.x6),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: header,
        ),
        SizedBox(
          height: 216,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(width: JmSpace.x3),
            itemBuilder: (_, i) {
              final (icon, title, blurb, hue, go) = suggestions[i];
              return _SuggestionCard(icon: icon, title: title, blurb: blurb, hue: hue, onTap: go);
            },
          ),
        ),
      ],
    );
  }
}

/// One suggestion: a round icon, a title, one line of why, and a Try pill.
/// Sized for a row — three fit on a tablet, one and a bit on a phone.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.icon,
    required this.title,
    required this.blurb,
    required this.hue,
    required this.onTap,
  });
  final IconData icon;
  final String title, blurb;
  final ArtHue hue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final (tint, deep) = switch (hue) {
      ArtHue.ocean => (c.oceanTint, c.oceanDeep),
      ArtHue.sky => (c.skyTint, c.skyDeep),
      ArtHue.match => (c.matchTint, c.matchDeep),
      ArtHue.volt => (c.voltTint, c.voltDeep),
    };
    return Semantics(
      button: true,
      label: '$title. $blurb',
      child: Material(
        color: c.card,
        borderRadius: JmRadius.lgR,
        child: InkWell(
          onTap: onTap,
          borderRadius: JmRadius.lgR,
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(JmSpace.x4),
            decoration: BoxDecoration(
              borderRadius: JmRadius.lgR,
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                  child: Icon(icon, size: 26, color: deep),
                ),
                const SizedBox(height: JmSpace.x3),
                Text(
                  title,
                  style: context.type.uiStrong.copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    blurb,
                    style: context.type.meta.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: JmSpace.x2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: deep, borderRadius: BorderRadius.circular(999)),
                  child: Text('Try', style: context.type.uiStrong.copyWith(color: Colors.white, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Example extends StatelessWidget {
  const _Example({required this.text, required this.onTap});
  final String text;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(text),
        borderRadius: JmRadius.lgR,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: JmSpace.x3, vertical: JmSpace.x3),
          decoration: BoxDecoration(color: c.surface, borderRadius: JmRadius.lgR),
          child: Row(
            children: [
              Icon(Icons.format_quote_rounded, size: 20, color: c.faint),
              const SizedBox(width: 10),
              Expanded(
                child: Text('“$text”', style: context.type.body.copyWith(fontStyle: FontStyle.italic, fontSize: 14)),
              ),
              Icon(Icons.arrow_forward_rounded, size: 18, color: c.faint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final mine = message.role == AiRole.user;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: (MediaQuery.sizeOf(context).width * .85).clamp(240, 560)),
        child: Container(
          margin: const EdgeInsets.only(bottom: JmSpace.x3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: mine ? c.ocean : c.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(JmRadius.lg),
              topRight: const Radius.circular(JmRadius.lg),
              bottomLeft: Radius.circular(mine ? JmRadius.lg : 4),
              bottomRight: Radius.circular(mine ? 4 : JmRadius.lg),
            ),
          ),
          child: Text(
            message.text,
            style: context.type.body.copyWith(fontSize: 15, color: mine ? Colors.white : c.text),
          ),
        ),
      ),
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();
  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: JmSpace.x3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: c.surface, borderRadius: JmRadius.lgR),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: c.ocean)),
            const SizedBox(width: 10),
            Text('Thinking…', style: context.type.meta),
          ],
        ),
      ),
    );
  }
}
