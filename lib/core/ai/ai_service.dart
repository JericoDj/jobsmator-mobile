import 'dart:io';

import '../api/api_client.dart';

/// The assistant behind the AI tab and the Tools tab.
///
/// Conversations live on the server (`/v1/ai`), so they survive reinstalls
/// and the model sees the user's resume, matched jobs and earlier turns.
/// [MockAiService] stands in under `--dart-define=PREVIEW=true`.
abstract class AiService {
  Future<List<AiThread>> threads();
  Future<AiThread> thread(String id);
  Future<void> deleteThread(String id);

  /// Sends one turn. Omit [threadId] to start a conversation; pass [tool]
  /// on that first message to start it with a Tools-tab task.
  Future<AiTurn> send({
    String? threadId,
    required String text,
    List<String> attachmentIds = const [],
    String? tool,
  });

  /// Uploads an image and has the model describe it, so it can be attached
  /// to a message and referred to later in the thread.
  Future<AiAttachment> upload(File image);

  /// One-shot Tools-tab run: a fresh thread with the tool's instructions.
  Future<String> runTool(String toolId, String input) async {
    final turn = await send(text: input, tool: toolId);
    return turn.reply.text;
  }
}

enum AiRole { user, assistant }

class AiAttachment {
  const AiAttachment({
    required this.id,
    required this.filename,
    required this.kind,
    required this.analysis,
    required this.url,
  });
  final String id, filename, kind, url;
  final String? analysis;

  factory AiAttachment.fromJson(Map<String, dynamic> j) => AiAttachment(
    id: j['id'] as String,
    filename: j['filename'] as String? ?? 'image',
    kind: j['kind'] as String? ?? 'other',
    analysis: j['analysis'] as String?,
    url: j['url'] as String? ?? '',
  );
}

class AiMessage {
  const AiMessage({
    required this.role,
    required this.text,
    required this.at,
    this.id,
    this.attachments = const [],
  });
  final String? id;
  final AiRole role;
  final String text;
  final DateTime at;
  final List<AiAttachment> attachments;

  AiMessage copyWith({String? text}) =>
      AiMessage(id: id, role: role, text: text ?? this.text, at: at, attachments: attachments);

  factory AiMessage.fromJson(Map<String, dynamic> j) => AiMessage(
    id: j['id'] as String?,
    role: j['role'] == 'assistant' ? AiRole.assistant : AiRole.user,
    text: j['content'] as String? ?? '',
    at: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    attachments: [
      for (final a in (j['attachments'] as List? ?? const [])) AiAttachment.fromJson((a as Map).cast<String, dynamic>()),
    ],
  );
}

/// One conversation. [messages] is empty until [AiService.thread] loads it.
class AiThread {
  AiThread({required this.id, required this.title, this.tool, DateTime? updatedAt, List<AiMessage>? messages})
    : updatedAt = updatedAt ?? DateTime.now(),
      messages = messages ?? [];
  final String id;
  String title;
  final String? tool;
  DateTime updatedAt;
  final List<AiMessage> messages;
  bool loaded = false;

  factory AiThread.fromJson(Map<String, dynamic> j, {List<AiMessage>? messages}) => AiThread(
    id: j['id'] as String,
    title: j['title'] as String? ?? 'New conversation',
    tool: j['tool'] as String?,
    updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? ''),
    messages: messages,
  );
}

class AiTurn {
  const AiTurn({required this.thread, required this.message, required this.reply, required this.used, required this.limit});
  final AiThread thread;
  final AiMessage message, reply;
  final int used, limit;
}

// ---------------------------------------------------------------------------

class ApiAiService extends AiService {
  ApiAiService(this._api);
  final ApiClient _api;

  @override
  Future<List<AiThread>> threads() async {
    final r = await _api.get('/v1/ai/threads');
    return [for (final t in (r['items'] as List? ?? const [])) AiThread.fromJson((t as Map).cast<String, dynamic>())];
  }

  @override
  Future<AiThread> thread(String id) async {
    final r = await _api.get('/v1/ai/threads/$id');
    final messages = [
      for (final m in (r['messages'] as List? ?? const [])) AiMessage.fromJson((m as Map).cast<String, dynamic>()),
    ];
    return AiThread.fromJson((r['thread'] as Map).cast<String, dynamic>(), messages: messages)..loaded = true;
  }

  @override
  Future<void> deleteThread(String id) => _api.delete('/v1/ai/threads/$id');

  @override
  Future<AiTurn> send({String? threadId, required String text, List<String> attachmentIds = const [], String? tool}) async {
    final r = await _api.post(
      '/v1/ai/messages',
      body: {
        'threadId': ?threadId,
        'text': text,
        'attachmentIds': attachmentIds,
        'tool': ?tool,
      },
    );
    final usage = (r['usage'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AiTurn(
      thread: AiThread.fromJson((r['thread'] as Map).cast<String, dynamic>()),
      message: AiMessage.fromJson((r['message'] as Map).cast<String, dynamic>()),
      reply: AiMessage.fromJson((r['reply'] as Map).cast<String, dynamic>()),
      used: usage['used'] as int? ?? 0,
      limit: usage['limit'] as int? ?? 0,
    );
  }

  @override
  Future<AiAttachment> upload(File image) async {
    final r = await _api.upload('/v1/ai/attachments', file: image, field: 'file');
    return AiAttachment.fromJson(r);
  }
}

// ---------------------------------------------------------------------------

/// Canned replies for preview builds; keeps threads in memory.
class MockAiService extends AiService {
  MockAiService();
  final _threads = <String, AiThread>{};

  static String _id() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  @override
  Future<List<AiThread>> threads() async => _threads.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<AiThread> thread(String id) async => _threads[id]!..loaded = true;

  @override
  Future<void> deleteThread(String id) async => _threads.remove(id);

  @override
  Future<AiAttachment> upload(File image) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return AiAttachment(
      id: _id(),
      filename: image.uri.pathSegments.last,
      kind: 'job_posting',
      analysis: 'Job posting: Senior Flutter Developer at Sprout, ₱120k–₱160k, remote, 4+ years Flutter.',
      url: image.uri.toString(),
    );
  }

  @override
  Future<AiTurn> send({String? threadId, required String text, List<String> attachmentIds = const [], String? tool}) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final AiThread thread;
    if (threadId != null) {
      thread = _threads[threadId]!;
    } else {
      final id = _id();
      thread = _threads[id] = AiThread(id: id, title: text.length > 44 ? '${text.substring(0, 44)}…' : text, tool: tool);
    }
    final now = DateTime.now();
    final message = AiMessage(id: _id(), role: AiRole.user, text: text, at: now);
    final reply = AiMessage(id: _id(), role: AiRole.assistant, text: tool != null ? _tool(tool, text) : _chat(text), at: now);
    thread.messages
      ..add(message)
      ..add(reply);
    thread.updatedAt = now;
    thread.loaded = true;
    return AiTurn(thread: thread, message: message, reply: reply, used: 1, limit: 30);
  }

  String _chat(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('remote') && p.contains('flutter')) {
      return 'I found 4 remote Flutter roles from your last search. Two are above your minimum rate: '
          'Mobile Engineer at GCash (84) and Flutter Developer at Maya (81). Want me to open them in Jobs, '
          'or draft an application for the top one?';
    }
    if (p.contains('resume')) {
      return 'Your resume reads well for senior Flutter roles. The gap recruiters will notice: no numbers on impact. '
          'Add one metric to each of your last two roles and your match scores should rise 3–5 points.';
    }
    if (p.contains('interview')) {
      return 'For a Flutter interview at a fintech, expect questions on state management trade-offs, offline sync, '
          'and secure storage. I can run a mock round — pick a listing from Jobs and say "prepare me".';
    }
    return 'I can search jobs, score a listing against your resume, draft applications, or prep you for an '
        'interview. Try "find me remote Flutter jobs" or "analyze my resume".';
  }

  String _tool(String toolId, String input) => switch (toolId) {
    'resume-analyzer' =>
      '**Strong:** 3 years of Flutter, Firebase and REST integration read clearly.\n\n'
          '**Fix first:** no metrics on impact. Add one number per role.\n\n'
          '**Missing keywords for ${input.isEmpty ? 'senior Flutter roles' : input}:** CI/CD, state management rationale, accessibility.',
    'job-match' => '**Score: 82 — Strong.**\n\nMatches your Flutter, Firebase and REST experience.\n\n**Watch out for:** salary hidden.',
    'salary' => 'For ${input.isEmpty ? 'a mid-level Flutter developer in Manila' : input}: **₱70k–₱110k / month**.',
    _ => 'Done.',
  };
}
