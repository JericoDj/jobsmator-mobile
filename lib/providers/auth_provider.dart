import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/api/api_client.dart';
import '../core/config.dart';
import '../core/models/app_user.dart';

/// Firebase user + ID token. The router listens to this for redirects.
/// In preview mode there is no Firebase; a fixture user is signed in at start.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    if (AppConfig.preview) {
      _user = const AppUser(uid: 'preview', email: 'jerico@example.com', displayName: 'Jerico De Jesus');
      _ready = true;
      return;
    }
    _sub = fb.FirebaseAuth.instance.authStateChanges().listen((u) {
      _user = u == null ? null : AppUser(uid: u.uid, email: u.email, displayName: u.displayName, photoUrl: u.photoURL);
      _ready = true;
      notifyListeners();
    });
  }

  AppUser? _user;
  bool _ready = false;
  StreamSubscription<fb.User?>? _sub;

  AppUser? get user => _user;
  bool get signedIn => _user != null;

  /// False until Firebase reports the persisted session, so the router does
  /// not flash the sign-in screen on a cold start.
  bool get ready => _ready;

  /// Handed to the API client; Firebase refreshes the token itself.
  Future<String?> idToken() async {
    if (AppConfig.preview) return 'preview-token';
    return fb.FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (AppConfig.preview) return _previewSignIn(email);
    await fb.FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail({required String name, required String email, required String password}) async {
    if (AppConfig.preview) return _previewSignIn(email, name: name);
    final cred = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(name);
    await cred.user?.reload();
    await cred.user?.getIdToken(true);
    final u = fb.FirebaseAuth.instance.currentUser;
    if (u != null) {
      _user = AppUser(uid: u.uid, email: u.email, displayName: u.displayName ?? name, photoUrl: u.photoURL);
      notifyListeners();
    }
  }

  /// Syncs with the backend `GET /v1/me` route.
  Future<Map<String, dynamic>> fetchMe(ApiClient api) async {
    final data = await api.get('/v1/me');
    if (_user != null) {
      final displayName = data['displayName'] as String? ?? _user!.displayName;
      final email = data['email'] as String? ?? _user!.email;
      _user = AppUser(uid: _user!.uid, email: email, displayName: displayName, photoUrl: _user!.photoUrl);
      notifyListeners();
    }
    return data;
  }

  Future<void> sendPasswordReset(String email) async {
    if (AppConfig.preview) return Future.delayed(const Duration(milliseconds: 400));
    await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> signInWithGoogle() async {
    if (AppConfig.preview) return _previewSignIn('jerico@example.com');
    final account = await GoogleSignIn().signIn();
    if (account == null) return;
    final auth = await account.authentication;
    await fb.FirebaseAuth.instance.signInWithCredential(
      fb.GoogleAuthProvider.credential(idToken: auth.idToken, accessToken: auth.accessToken),
    );
  }

  /// iOS only. Firebase drives the native Apple sheet itself, so no extra
  /// plugin is needed — just the Sign in with Apple entitlement on the target.
  Future<void> signInWithApple() async {
    if (AppConfig.preview) return _previewSignIn('jerico@example.com');
    final apple = fb.AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');
    await fb.FirebaseAuth.instance.signInWithProvider(apple);
  }

  Future<void> signOut() async {
    if (AppConfig.preview) {
      _user = null;
      notifyListeners();
      return;
    }
    await fb.FirebaseAuth.instance.signOut();
  }

  void _previewSignIn(String email, {String? name}) {
    _user = AppUser(uid: 'preview', email: email, displayName: name ?? 'Jerico De Jesus');
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
