/// Build-time configuration.
///
///   flutter run --dart-define=API_URL=https://api.jobsmator.app
///   flutter run --dart-define=PREVIEW=true   # no Firebase, mocked API — for design work
abstract final class AppConfig {
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3001');

  /// Preview mode skips Firebase, signs in a fake user and serves fixture data.
  static const preview = bool.fromEnvironment('PREVIEW');
}
