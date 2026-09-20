/// Build-time configuration.
///
/// Run with environment files:
///   flutter run --dart-define-from-file=env.local.json
///   flutter run --dart-define-from-file=env.prod.json
///   flutter run --dart-define-from-file=env.preview.json
///
/// Or with inline defines:
///   flutter run --dart-define=API_URL=https://api.jobsmator.app
///   flutter run --dart-define=PREVIEW=true   # no Firebase, mocked API — for design work
abstract final class AppConfig {
  static const fbApiKey = String.fromEnvironment('FB_API_KEY', defaultValue: '');
  static const fbAppId = String.fromEnvironment('FB_APP_ID', defaultValue: '1:655823055418:ios:ca8d8102ff4b248a8039bc');
  static const fbMessagingSenderId = String.fromEnvironment('FB_MSG_ID', defaultValue: '655823055418');
  static const fbProjectId = String.fromEnvironment('FB_PROJECT_ID', defaultValue: 'jobsmator');
  static const fbStorageBucket = String.fromEnvironment('FB_STORAGE_BUCKET', defaultValue: 'mondaymobile-3adca.firebasestorage.app');

  /// App environment name: 'local', 'development', 'production', 'preview', etc.
  static const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'local');

  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3001');

  /// Preview mode skips Firebase, signs in a fake user and serves fixture data.
  static const preview = bool.fromEnvironment('PREVIEW');

  static bool get isProduction => environment == 'production' || environment == 'prod';
  static bool get isLocal => environment == 'local' || environment == 'development';
}
