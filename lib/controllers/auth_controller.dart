import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../providers/auth_provider.dart';

/// Form state shared by the login, register and forgot-password screens:
/// the text fields, a busy flag, one error line, and a "done" flag for the
/// reset flow. Auth itself lives in [AuthProvider].
class AuthController extends ChangeNotifier {
  AuthController(this._auth);

  final AuthProvider _auth;
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool _busy = false;
  bool _done = false;
  String? _error;

  bool get busy => _busy;
  bool get done => _done;
  String? get error => _error;

  Future<void> login() async {
    final e = email.text.trim(), p = password.text;
    if (!_validEmail(e)) return _fail('Enter the email you signed up with.');
    if (p.isEmpty) return _fail('Enter your password.');
    await _guard(() => _auth.signInWithEmail(e, p));
  }

  Future<void> register() async {
    final n = name.text.trim(), e = email.text.trim(), p = password.text;
    if (n.isEmpty) return _fail('Tell us your name.');
    if (!_validEmail(e)) return _fail('Enter a valid email.');
    if (p.length < 8) return _fail('Passwords are at least 8 characters.');
    await _guard(() => _auth.signUpWithEmail(name: n, email: e, password: p));
  }

  Future<void> sendReset() async {
    final e = email.text.trim();
    if (!_validEmail(e)) return _fail('Enter the email you signed up with.');
    await _guard(() async {
      await _auth.sendPasswordReset(e);
      _done = true;
    });
  }

  Future<void> continueWithGoogle() => _guard(_auth.signInWithGoogle);

  Future<void> continueWithApple() => _guard(_auth.signInWithApple);

  bool _validEmail(String e) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(e);

  Future<void> _guard(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      // Dismissing the Google/Apple sheet is not an error worth a red line.
      if (!_cancelled(e)) _error = _describe(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _fail(String message) {
    _error = message;
    notifyListeners();
  }

  String _describe(Object e) {
    if (e is ApiException) return e.message;
    return switch (_codeOf(e)) {
      'user-not-found' || 'wrong-password' || 'invalid-credential' => "That email and password don't match.",
      'email-already-in-use' => 'There is already an account for that email. Sign in instead.',
      'weak-password' => 'Pick a longer password — at least 8 characters.',
      'invalid-email' => 'Enter a valid email address.',
      'too-many-requests' => 'Too many tries. Wait a minute and try again.',
      'network-request-failed' => 'Check your connection and try again.',
      'account-exists-with-different-credential' =>
        'That email already signed in another way. Use the same method as before.',
      _ => "We couldn't complete your request. Try again.",
    };
  }

  bool _cancelled(Object e) => const {'canceled', 'web-context-canceled', 'sign_in_canceled'}.contains(_codeOf(e));

  String? _codeOf(Object e) {
    try {
      return (e as dynamic).code as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }
}
