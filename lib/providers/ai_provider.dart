import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/ai/ai_service.dart';
import '../core/api/api_client.dart';

/// Conversation state for the AI tab. Threads live on the server; this keeps
/// the list, the active thread's messages and any images waiting to be sent.
///
/// A reply goes through two phases: [thinking] while the request is in
/// flight, then [streaming] while the text is revealed a few characters at
/// a time. [stop] cancels either — a late reply is discarded from view (it
/// is still saved server-side), a half-typed one is kept as is.
class AiProvider extends ChangeNotifier {
  AiProvider(this._service);

  final AiService _service;

  final List<AiThread> _threads = [];
  AiThread _active = _draft();
  bool _loaded = false;
  bool _loadingThread = false;
  bool _thinking = false;
  bool _streaming = false;
  String? _error;

  /// Images uploaded but not yet sent with a message.
  final List<AiAttachment> _pending = [];
  int _uploading = 0;

  int? _used, _limit;

  /// Bumped on every send, stop and thread switch so a reply from a
  /// cancelled request can recognise itself as stale and drop out.
  int _gen = 0;
  Timer? _typer;

  /// A thread that exists only on this device until its first message.
  static AiThread _draft() => AiThread(id: '', title: 'New conversation');

  List<AiMessage> get messages => List.unmodifiable(_active.messages);
  AiThread get active => _active;
  List<AiThread> get threads => List.unmodifiable(_threads);
  List<AiAttachment> get pending => List.unmodifiable(_pending);
  bool get uploading => _uploading > 0;
  bool get loaded => _loaded;
  bool get loadingThread => _loadingThread;
  bool get thinking => _thinking;
  bool get streaming => _streaming;
  bool get busy => _thinking || _streaming;
  String? get error => _error;
  bool get isEmpty => _active.messages.isEmpty && !_loadingThread;
  int? get used => _used;
  int? get limit => _limit;

  /// Fetches the saved conversations once. Safe to call repeatedly.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final list = await _service.threads();
      _threads
        ..clear()
        ..addAll(list);
      _loaded = true;
    } catch (e) {
      _error = messageOf(e, fallback: "Couldn't load your conversations.");
    }
    notifyListeners();
  }

  Future<void> send(String text) async {
    final t = text.trim();
    if ((t.isEmpty && _pending.isEmpty) || busy || uploading) return;
    final thread = _active;
    final attachments = List<AiAttachment>.of(_pending);
    _pending.clear();
    thread.messages.add(
      AiMessage(role: AiRole.user, text: t, at: DateTime.now(), attachments: attachments),
    );
    _thinking = true;
    _error = null;
    final gen = ++_gen;
    notifyListeners();
    try {
      final turn = await _service.send(
        threadId: thread.id.isEmpty ? null : thread.id,
        text: t,
        attachmentIds: [for (final a in attachments) a.id],
      );
      _used = turn.used;
      _limit = turn.limit;
      if (gen != _gen) return;
      _thinking = false;
      _adopt(thread, turn);
      _startTyping(thread, turn.reply, gen);
    } catch (e) {
      if (gen != _gen) return;
      _thinking = false;
      _error = messageOf(e, fallback: "Couldn't reach the assistant. Try again in a moment.");
      notifyListeners();
    }
  }

  /// A draft thread becomes the real one the server created; the user
  /// message swaps for the saved copy so ids and attachment URLs are right.
  void _adopt(AiThread thread, AiTurn turn) {
    if (thread.id.isEmpty) {
      final real = AiThread(id: turn.thread.id, title: turn.thread.title, tool: turn.thread.tool, updatedAt: turn.thread.updatedAt, messages: thread.messages)
        ..loaded = true;
      if (_active == thread) _active = real;
      _threads.insert(0, real);
      thread = real;
    } else {
      thread.title = turn.thread.title;
      thread.updatedAt = turn.thread.updatedAt;
      _threads
        ..remove(thread)
        ..insert(0, thread);
    }
    if (thread.messages.isNotEmpty && thread.messages.last.role == AiRole.user) {
      thread.messages[thread.messages.length - 1] = turn.message;
    }
  }

  /// Reveals [reply] in an empty assistant bubble, a few characters per
  /// tick. Chunk size scales with length so long answers still land in
  /// about three seconds.
  void _startTyping(AiThread thread, AiMessage reply, int gen) {
    final full = reply.text;
    thread.messages.add(reply.copyWith(text: ''));
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
      thread.messages[thread.messages.length - 1] = reply.copyWith(text: full.substring(0, shown));
      if (shown >= full.length) {
        timer.cancel();
        _typer = null;
        _streaming = false;
      }
      notifyListeners();
    });
  }

  /// Uploads an image so it can ride along with the next message. The
  /// server describes it once; that description is what the model
  /// remembers in later turns.
  Future<void> attach(File image) async {
    _uploading++;
    _error = null;
    notifyListeners();
    try {
      _pending.add(await _service.upload(image));
    } catch (e) {
      _error = messageOf(e, fallback: "Couldn't upload that image.");
    } finally {
      _uploading--;
      notifyListeners();
    }
  }

  void removePending(String id) {
    _pending.removeWhere((a) => a.id == id);
    notifyListeners();
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
    if (m.isNotEmpty && m.last.role == AiRole.assistant && m.last.text.isEmpty) {
      m.removeLast();
    }
    notifyListeners();
  }

  /// Start a fresh thread. The current one stays in [threads].
  void newThread() {
    stop();
    if (_active.id.isEmpty && _active.messages.isEmpty) return;
    _active = _draft();
    _pending.clear();
    _error = null;
    notifyListeners();
  }

  /// Switch to a saved thread, fetching its messages the first time.
  Future<void> open(String id) async {
    final t = _threads.where((t) => t.id == id).firstOrNull;
    if (t == null || t == _active) return;
    stop();
    _active = t;
    _pending.clear();
    _error = null;
    if (!t.loaded) {
      _loadingThread = true;
      notifyListeners();
      try {
        final full = await _service.thread(id);
        t.messages
          ..clear()
          ..addAll(full.messages);
        t.loaded = true;
      } catch (e) {
        _error = messageOf(e, fallback: "Couldn't open that conversation.");
      }
      _loadingThread = false;
    }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final t = _threads.where((t) => t.id == id).firstOrNull;
    if (t == null) return;
    _threads.remove(t);
    if (_active.id == id) {
      stop();
      _active = _draft();
    }
    notifyListeners();
    try {
      await _service.deleteThread(id);
    } catch (e) {
      _threads.add(t);
      _error = messageOf(e, fallback: "Couldn't delete that conversation.");
      notifyListeners();
    }
  }

  /// Kept for callers that only want the thread wiped.
  void clear() => newThread();

  @override
  void dispose() {
    _typer?.cancel();
    super.dispose();
  }
}
