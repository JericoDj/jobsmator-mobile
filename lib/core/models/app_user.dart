/// The signed-in user, independent of the auth SDK so screens and controllers
/// never import firebase_auth.
class AppUser {
  const AppUser({required this.uid, this.email, this.displayName, this.photoUrl});
  final String uid;
  final String? email, displayName, photoUrl;

  /// The sheet name follows "JobsMator — {first name}".
  String get firstName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name.split(RegExp(r'\s+')).first;
    return email?.split('@').first ?? 'you';
  }
}
