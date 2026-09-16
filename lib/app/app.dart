import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../core/api/mock_api_client.dart';
import '../core/config.dart';
import '../providers/auth_provider.dart';
import '../providers/jobs_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/preferences_provider.dart';
import '../providers/resume_provider.dart';
import '../core/ai/ai_service.dart';
import '../providers/ai_provider.dart';
import '../providers/job_catalog_provider.dart';
import '../providers/run_provider.dart';
import '../providers/subscription_provider.dart';
import 'router.dart';
import 'theme/theme.dart';

/// Provider tree, top to bottom (ARCHITECTURE.md §8):
/// Auth → ApiClient → Resume, Preferences, Run, Jobs. Screen controllers
/// are created per route in [buildRouter].
class JobsMatorApp extends StatefulWidget {
  const JobsMatorApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  State<JobsMatorApp> createState() => _JobsMatorAppState();
}

class _JobsMatorAppState extends State<JobsMatorApp> {
  late final AuthProvider _auth = AuthProvider();
  late final OnboardingProvider _onboarding = OnboardingProvider(widget.prefs);
  late final _router = buildRouter(_auth, _onboarding);

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    _onboarding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _onboarding),
        Provider<ApiClient>(
          create: (ctx) => AppConfig.preview ? MockApiClient() : HttpApiClient(tokenProvider: _auth.idToken),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ResumeProvider>(
          create: (ctx) => ResumeProvider(ctx.read<ApiClient>(), uid: _auth.user?.uid),
          update: (ctx, auth, prev) => prev != null && prev.uid == auth.user?.uid
              ? prev
              : ResumeProvider(ctx.read<ApiClient>(), uid: auth.user?.uid),
        ),
        ChangeNotifierProvider(create: (ctx) => PreferencesProvider(ctx.read<ApiClient>())),
        ChangeNotifierProvider(create: (ctx) => RunProvider(ctx.read<ApiClient>())),
        ChangeNotifierProvider(create: (ctx) => JobsProvider(ctx.read<ApiClient>())),
        ChangeNotifierProvider(create: (ctx) => JobCatalogProvider(ctx.read<ApiClient>())),
        Provider<AiService>(create: (_) => const MockAiService()),
        ChangeNotifierProvider(create: (ctx) => AiProvider(ctx.read<AiService>())),
        ChangeNotifierProvider(create: (ctx) => SubscriptionProvider(ctx.read<ApiClient>())),
      ],
      child: MaterialApp.router(
        title: 'JobsMator',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
