import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/jobs_provider.dart';
import 'providers/preferences_provider.dart';
import 'providers/resume_provider.dart';
import 'providers/run_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Generate lib/firebase_options.dart with `flutterfire configure`, then:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();
  runApp(const JobsMatorApp());
}

class JobsMatorApp extends StatelessWidget {
  const JobsMatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ProxyProvider<AuthProvider, ApiClient>(
          update: (_, auth, previous) => previous ?? ApiClient(tokenProvider: auth.idToken),
        ),
        ChangeNotifierProxyProvider<ApiClient, ResumeProvider>(
          create: (_) => ResumeProvider(),
          update: (_, api, p) => p!..api = api,
        ),
        ChangeNotifierProxyProvider<ApiClient, PreferencesProvider>(
          create: (_) => PreferencesProvider(),
          update: (_, api, p) => p!..api = api,
        ),
        ChangeNotifierProxyProvider<ApiClient, RunProvider>(
          create: (_) => RunProvider(),
          update: (_, api, p) => p!..api = api,
        ),
        ChangeNotifierProxyProvider<ApiClient, JobsProvider>(
          create: (_) => JobsProvider(),
          update: (_, api, p) => p!..api = api,
        ),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'JobsMator',
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          routerConfig: buildRouter(context.read<AuthProvider>()),
        ),
      ),
    );
  }
}
