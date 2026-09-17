import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/ai/ai_service.dart';

/// One conversation. Title is the first thing the user said.
class AiThread {
  AiThread({required this.id, DateTime? updatedAt})
    : updatedAt = updatedAt ?? DateTime.now();
  final String id;
  final List<AiMessage> messages = [];
  DateTime updatedAt;

  String get title {
    final first = messages
        .where((m) => m.role == AiRole.user)
        .map((m) => m.text)
        .firstOrNull;
    if (first == null) return 'New conversation';
    return first.length > 44 ? '${first.substring(0, 44).trimRight()}…' : first;
  }
}

/// Conversation state for the AI tab. Kept app-scoped so threads survive
/// tab switches (in memory for now — persistence comes with the real API).
///
/// A reply goes through two phases: [thinking] while the request is in
/// flight, then [streaming] while the text is revealed a few characters at
/// a time. [stop] cancels either — a late reply is discarded, a half-typed
/// one is kept as is.
class AiProvider extends ChangeNotifier {
  AiProvider(this._service);

  final AiService _service;

  final List<AiThread> _threads = [];
  AiThread _active = AiThread(id: _newId());
  bool _thinking = false;
  bool _streaming = false;
  String? _error;

  /// Bumped on every send, stop and thread switch so a reply from a
  /// cancelled request can recognise itself as stale and drop out.
  int _gen = 0;
  Timer? _typer;

  static String _newId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  List<AiMessage> get messages => List.unmodifiable(_active.messages);
  AiThread get active => _active;

  /// Saved conversations, newest first. The active one is included once it
  /// has a message.
  List<AiThread> get threads {
    final all = [..._threads];
    if (_active.messages.isNotEmpty && !all.contains(_active)) all.add(_active);
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(all);
  }

  bool get thinking => _thinking;
  bool get streaming => _streaming;
  bool get busy => _thinking || _streaming;
  String? get error => _error;
  bool get isEmpty => _active.messages.isEmpty;

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty || busy) return;
    final thread = _active;
    if (!_threads.contains(thread)) _threads.add(thread);
    thread.messages.add(
      AiMessage(role: AiRole.user, text: t, at: DateTime.now()),
    );
    thread.updatedAt = DateTime.now();
    _thinking = true;
    _error = null;
    final gen = ++_gen;
    notifyListeners();
    try {
      final reply = await _service.chat(thread.messages, t);
      if (gen != _gen) return;
      _thinking = false;
      _startTyping(thread, reply, gen);
    } catch (_) {
      if (gen != _gen) return;
      _thinking = false;
      _error = "Couldn't reach the assistant. Try again in a moment.";
      notifyListeners();
    }
  }

  /// Reveals [full] in an empty assistant bubble, a few characters per
  /// tick. Chunk size scales with length so long answers still land in
  /// about three seconds.
  void _startTyping(AiThread thread, String full, int gen) {
    thread.messages.add(
      AiMessage(role: AiRole.assistant, text: '', at: DateTime.now()),
    );
    _streaming = true;
    notifyListeners();

    final chunk = math.max(1, (full.length / 160).ceil());
    var shown = 0;
    _typer = Timer.periodic(const Duration(milliseconds: 18), (timer) {
      if (gen != _gen) {
        timer.cancel();
        return;
      }
      shown = math.min(full.length, shown + chunk);
      final last = thread.messages.last;
      thread.messages[thread.messages.length - 1] = AiMessage(
        role: last.role,
        text: full.substring(0, shown),
        at: last.at,
      );
      if (shown >= full.length) {
        timer.cancel();
        _typer = null;
        _streaming = false;
        thread.updatedAt = DateTime.now();
      }
      notifyListeners();
    });
  }

  /// Cancel the in-flight request or the reveal. Whatever has already been
  /// typed stays on screen.
  void stop() {
    if (!busy) return;
    _gen++;
    _typer?.cancel();
    _typer = null;
    _thinking = false;
    _streaming = false;
    final m = _active.messages;
    if (m.isNotEmpty &&
        m.last.role == AiRole.assistant &&
        m.last.text.isEmpty) {
      m.removeLast();
    }
    notifyListeners();
  }

  /// Start a fresh thread. The current one stays in [threads] if it has
  /// any messages.
  void newThread() {
    stop();
    if (_active.messages.isEmpty) return;
    _active = AiThread(id: _newId());
    _error = null;
    notifyListeners();
  }

  /// Switch to a saved thread.
  void open(String id) {
    final t = _threads.where((t) => t.id == id).firstOrNull;
    if (t == null || t == _active) return;
    stop();
    _active = t;
    _error = null;
    notifyListeners();
  }

  void delete(String id) {
    _threads.removeWhere((t) => t.id == id);
    if (_active.id == id) {
      stop();
      _active = AiThread(id: _newId());
    }
    notifyListeners();
  }

  /// Kept for callers that only want the thread wiped.
  void clear() => newThread();

  @override
  void dispose() {
    _typer?.cancel();
    super.dispose();
  }
}
