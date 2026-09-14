# jobsmator-mobile

Flutter app for JobsMator (Provider + go_router). Architecture: `../ARCHITECTURE.md`.

## Setup

```bash
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure            # writes lib/firebase_options.dart (git-ignored)
```

Then in `lib/main.dart` switch `Firebase.initializeApp()` to use `DefaultFirebaseOptions.currentPlatform`.

## Run

```bash
flutter run --dart-define=API_URL=http://localhost:3001
```

## Layout

```
lib/
  app/        router, theme (design-guide tokens + JmTierColors extension)
  core/       api_client (Dio + Firebase ID token), models/
  features/   auth, upload, preferences (interests, sites), results
  providers/  Auth, Resume, Preferences, Run (3 s polling), Jobs
```
