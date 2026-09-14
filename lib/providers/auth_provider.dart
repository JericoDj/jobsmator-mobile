import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((u) {
      user = u;
      notifyListeners();
    });
  }

  User? user;
  StreamSubscription<User?>? _sub;

  /// Handed to ApiClient; Firebase refreshes the token itself when it expires.
  Future<String?> idToken() => user?.getIdToken() ?? Future.value(null);

  Future<void> signInWithEmail(String email, String password) =>
      FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signUpWithEmail(String email, String password) =>
      FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signInWithGoogle() async {
    final account = await GoogleSignIn().signIn();
    if (account == null) return;
    final auth = await account.authentication;
    await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(idToken: auth.idToken, accessToken: auth.accessToken),
    );
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
