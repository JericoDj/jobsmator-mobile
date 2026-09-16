import 'package:flutter/foundation.dart';

import '../core/ai/ai_service.dart';

/// Conversation state for the AI tab. Kept app-scoped so the thread
/// survives tab switches.
class AiProvider extends ChangeNotifier {
  AiProvider(this._service);

  final AiService _service;

  final List<AiMessage> _messages = [];
  bool _thinking = false;
  String? _error;

  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool get thinking => _thinking;
  String? get error => _error;
  bool get isEmpty => _messages.isEmpty;

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _thinking) return;
    _messages.add(AiMessage(role: AiRole.user, text: t, at: DateTime.now()));
    _thinking = true;
    _error = null;
    notifyListeners();
    try {
      final reply = await _service.chat(_messages, t);
      _messages.add(AiMessage(role: AiRole.assistant, text: reply, at: DateTime.now()));
    } catch (_) {
      _error = "Couldn't reach the assistant. Try again in a moment.";
    } finally {
      _thinking = false;
      notifyListeners();
    }
  }

  void clear() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }
}
