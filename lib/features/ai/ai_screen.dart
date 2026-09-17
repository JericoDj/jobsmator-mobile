import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../app/theme/theme.dart';
import '../../core/ai/ai_service.dart';
import '../../providers/ai_provider.dart';
import '../shared/widgets/edge_fade.dart';
import 'ai_side_sheet.dart';
import 'ai_tools.dart';

/// The assistant. Empty state is a centred hero (a fan of tool tiles, one
/// headline, a Try pill); once there is a thread it becomes a plain
/// conversation. Two round buttons sit in the corners: tools on the left,
/// new conversation on the right. The composer is a pill with a "+" that
/// opens the same tools sheet.
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _speech = stt.SpeechToText();
  bool _listening = false;
  AiProvider? _ai;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ai = context.read<AiProvider>();
    if (ai != _ai) {
      _ai?.removeListener(_followTail);
      _ai = ai..addListener(_followTail);
    }
  }

  /// While a reply is being revealed, keep the newest text in view — but
  /// only if the user is already near the bottom, so reading back up the
  /// thread is not hijacked.
  void _followTail() {
    if (!(_ai?.busy ?? false)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      if (pos.maxScrollExtent - pos.pixels < 120) {
        pos.jumpTo(pos.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _ai?.removeListener(_followTail);
    _speech.stop();
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Dictation. Words land in the field as they are recognised so the
  /// user can fix them before sending; tapping the mic again stops.
  Future<void> _toggleDictation() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'done' || s == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dictation is not available on this device.'),
        ),
      );
      return;
    }
    final prefix = _input.text.trim();
    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(partialResults: true),
      onResult: (r) {
        final words = r.recognizedWords;
        _input.text = prefix.isEmpty ? words : '$prefix $words';
        _input.selection = TextSelection.collapsed(offset: _input.text.length);
      },
    );
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
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: JmMotion.enterExit,
        curve: JmMotion.ease,
      );
    });
  }

  void _openTools() => showAiSideSheet(context);

  // Swipe in from the left edge opens the sheet, like a drawer.
  double? _edgeDragStart;
  void _onDragStart(DragStartDetails d) {
    _edgeDragStart = d.globalPosition.dx < 32 ? d.globalPosition.dx : null;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final start = _edgeDragStart;
    if (start != null && d.globalPosition.dx - start > 40) {
      _edgeDragStart = null;
      _openTools();
    }
  }

  Future<void> _confirmNew() async {
    final c = context.jm;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new conversation?'),
        content: const Text('The current thread will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: c.ocean,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start new'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) context.read<AiProvider>().newThread();
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();
    final c = context.jm;
    final gutter = JmSpace.gutter(MediaQuery.sizeOf(context).width);

    // The corner buttons and the composer float over the thread. Instead
    // of painting a coloured scrim on top, the list itself is alpha-masked
    // so messages dissolve to nothing as they slide under either edge —
    // no wash, no visible start line.
    const topBand = 72.0;
    const bottomBand = 96.0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          child: Stack(
            children: [
              Positioned.fill(
                child: ai.isEmpty
                    ? const _Hero()
                    : EdgeFade(
                        top: topBand,
                        bottom: bottomBand,
                        child: ListView.builder(
                          controller: _scroll,
                          padding: EdgeInsets.fromLTRB(
                            gutter,
                            topBand,
                            gutter,
                            bottomBand,
                          ),
                          itemCount: ai.messages.length + (ai.thinking ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == ai.messages.length) {
                              return const _Thinking();
                            }
                            return _Bubble(
                              message: ai.messages[i],
                              typing:
                                  ai.streaming && i == ai.messages.length - 1,
                            );
                          },
                        ),
                      ),
              ),
              Positioned(
                top: JmSpace.x4,
                left: gutter,
                right: gutter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundButton(
                      tooltip: 'Tools',
                      icon: Icons.tune_rounded,
                      onTap: _openTools,
                    ),
                    _RoundButton(
                      tooltip: 'New conversation',
                      icon: Icons.add_comment_outlined,
                      onTap: ai.isEmpty ? null : _confirmNew,
                    ),
                  ],
                ),
              ),
              // Bottom: error line + composer.
              Positioned(
                left: gutter,
                right: gutter,
                bottom: JmSpace.x2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ai.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: JmSpace.x2),
                        child: Text(
                          ai.error!,
                          style: context.type.meta.copyWith(color: c.danger),
                        ),
                      ),
                    _Composer(
                      controller: _input,
                      focusNode: _focus,
                      busy: ai.busy,
                      listening: _listening,
                      onPlus: _openTools,
                      onMic: _toggleDictation,
                      onSend: _send,
                      onStop: ai.stop,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Corner control: the same 44px bordered disc as the tab headers' bell,
/// so the AI tab lines up with Home, Jobs and Tools.
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.tooltip, required this.icon, required this.onTap});
  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      color: c.ink,
      style: IconButton.styleFrom(
        backgroundColor: c.card,
        disabledBackgroundColor: c.card,
        disabledForegroundColor: c.faint,
        side: BorderSide(color: c.line),
        fixedSize: const Size(44, 44),
      ),
    );
  }
}

/// Centred empty state: a swipeable fan of tool tiles, then a headline and
/// one muted line that describe whichever tile is in the middle, and a Try
/// pill that opens it. The fan bleeds past the screen edges on purpose so
/// the neighbours peek in, like a hand of cards, and invite a swipe.
class _Hero extends StatefulWidget {
  const _Hero();

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  final _page = PageController(
    viewportFraction: _TileFan.fraction,
    initialPage: _TileFan.origin,
  );
  int _current = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final tool = aiTools[_current];
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: JmLayout.reading),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TileFan(
                controller: _page,
                onChanged: (i) => setState(() => _current = i % aiTools.length),
              ),
              const SizedBox(height: JmSpace.x6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: JmSpace.x6),
                child: AnimatedSwitcher(
                  duration: JmMotion.enterExit,
                  switchInCurve: JmMotion.ease,
                  switchOutCurve: JmMotion.ease,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, .08),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey(_current),
                    children: [
                      Text(
                        tool.title,
                        textAlign: TextAlign.center,
                        style: context.type.title.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: JmSpace.x2),
                      Text(
                        tool.blurb,
                        textAlign: TextAlign.center,
                        style: context.type.body.copyWith(
                          color: c.muted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: JmSpace.x6),
              FilledButton(
                onPressed: () => openAiTool(context, tool),
                style: FilledButton.styleFrom(
                  backgroundColor: c.ink,
                  foregroundColor: c.ground,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: const StadiumBorder(),
                  textStyle: context.type.uiStrong.copyWith(fontSize: 15),
                ),
                child: const Text('Try it'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A PageView of tool tiles drawn as an arc: the tile nearest the centre
/// sits highest and straight, the others drop and tilt outward in
/// proportion to their distance from the centre, so the arc holds its
/// shape mid-swipe. Tapping a neighbour scrolls it to the middle.
class _TileFan extends StatelessWidget {
  const _TileFan({required this.controller, required this.onChanged});
  final PageController controller;
  final ValueChanged<int> onChanged;

  static const fraction = .24;
  static const _size = 64.0;

  /// Starting page — a multiple of the tool count far enough from zero
  /// that nobody swipes back to the edge. The list itself is unbounded
  /// and wraps modulo the tool count, so the tiles cycle forever.
  static const origin = _toolCount * 1000;
  static const _toolCount = 6;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: PageView.builder(
        controller: controller,
        onPageChanged: onChanged,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, i) => AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            // Distance from the centre in pages, -2..2 visible at once.
            final page =
                controller.hasClients && controller.position.haveDimensions
                ? controller.page ?? controller.initialPage.toDouble()
                : controller.initialPage.toDouble();
            final k = (i - page).clamp(-2.5, 2.5);
            final drop = 10.0 * k * k - 16;
            final angle = 7 * k * math.pi / 180;
            return Transform.translate(
              offset: Offset(0, drop),
              child: Transform.rotate(angle: angle, child: child),
            );
          },
          child: Center(
            child: _FanTile(
              tool: aiTools[i % aiTools.length],
              size: _size,
              onTap: () => controller.animateToPage(
                i,
                duration: JmMotion.enterExit,
                curve: JmMotion.ease,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FanTile extends StatelessWidget {
  const _FanTile({required this.tool, required this.size, required this.onTap});
  final AiTool tool;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final (tint, deep) = aiHueColors(c, tool.hue);
    return Semantics(
      button: true,
      label: tool.title,
      child: Material(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        shadowColor: JmColors.navy.withValues(alpha: .35),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(tool.icon, size: size * .45, color: deep),
          ),
        ),
      ),
    );
  }
}

/// Pill composer: "+" on the left, the field, a round send button.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.listening,
    required this.onPlus,
    required this.onMic,
    required this.onSend,
    required this.onStop,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy, listening;
  final VoidCallback onPlus, onMic, onSend, onStop;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Tools',
            onPressed: onPlus,
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(
              foregroundColor: c.ink,
              fixedSize: const Size.square(40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: context.type.body.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: listening ? 'Listening…' : 'Ask JobsMator',
                  hintStyle: context.type.body.copyWith(
                    color: c.muted,
                    fontSize: 15,
                  ),
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          // Mic: plain when idle, filled danger while recording.
          IconButton(
            tooltip: listening ? 'Stop dictation' : 'Dictate',
            onPressed: onMic,
            icon: Icon(
              listening ? Icons.stop_rounded : Icons.mic_none_rounded,
              size: 22,
            ),
            style: IconButton.styleFrom(
              backgroundColor: listening ? c.dangerTint : Colors.transparent,
              foregroundColor: listening ? c.danger : c.ink,
              fixedSize: const Size.square(40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 2),
          // Send, or Stop while a reply is in flight. A small filled disc
          // drawn by hand so its box is exactly 40px tall like the other
          // buttons — IconButton's own padding and tap-target rules kept
          // nudging it off the mic's centre line.
          SizedBox(
            width: 36,
            height: 40,
            child: Center(
              child: Semantics(
                button: true,
                label: busy ? 'Stop' : 'Send',
                child: Material(
                  color: busy ? c.ink : c.ocean,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: busy ? onStop : onSend,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        busy ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                        size: busy ? 16 : 18,
                        color: busy ? c.ground : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.typing = false});
  final AiMessage message;

  /// Shows a caret after the text while the reply is still being revealed.
  final bool typing;

  @override
  Widget build(BuildContext context) {
    final c = context.jm;
    final mine = message.role == AiRole.user;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width * .85).clamp(240, 560),
        ),
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
          child: Text.rich(
            TextSpan(
              text: message.text,
              children: [
                if (typing)
                  TextSpan(
                    text: ' ▍',
                    style: TextStyle(color: c.ocean),
                  ),
              ],
            ),
            style: context.type.body.copyWith(
              fontSize: 15,
              color: mine ? Colors.white : c.text,
            ),
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
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.ocean),
            ),
            const SizedBox(width: 10),
            Text('Thinking…', style: context.type.meta),
          ],
        ),
      ),
    );
  }
}
