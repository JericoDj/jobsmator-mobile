import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/interests_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/job_detail_controller.dart';
import '../controllers/job_preferences_controller.dart';
import '../controllers/results_controller.dart';
import '../controllers/sites_controller.dart';
import '../controllers/subscribe_controller.dart';
import '../controllers/tool_run_controller.dart';
import '../controllers/upload_controller.dart';
import '../core/models/tool.dart';
import '../features/ai/ai_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/jobs/job_detail_screen.dart';
import '../features/jobs/jobs_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/preferences/interests_screen.dart';
import '../features/preferences/sites_screen.dart';
import '../features/profile/automation_settings_screen.dart';
import '../features/profile/career_profile_screen.dart';
import '../features/profile/job_preferences_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/results/results_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/subscription/subscribe_screen.dart';
import '../features/tools/tool_run_screen.dart';
import '../features/tools/tools_screen.dart';
import '../features/upload/upload_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import 'routes.dart';

/// Layers:
///  0. the welcome tour, once per install
///  1. auth routes (no shell)
///  2. the five-tab shell — Home · Jobs · AI · Tools · Profile; the search
///     flow (steps 1–4) and job details live in the Jobs branch, settings
///     pages in the Profile branch
///  3. full-screen routes over the shell — the paywall
///
/// Auth redirect lives here, not in widgets. Each screen gets its controller
/// from its route so controller lifetime == screen lifetime.
GoRouter buildRouter(AuthProvider auth, OnboardingProvider onboarding) => GoRouter(
  initialLocation: AppRoutes.home,
  refreshListenable: Listenable.merge([auth, onboarding]),
  redirect: (_, state) {
    if (!auth.ready) return null;
    final loc = state.matchedLocation;
    final onWelcome = loc == AppRoutes.welcome;
    final onAuth = AppRoutes.authRoutes.contains(loc);
    // Signed-out first run → the tour, and nowhere else until it's done.
    if (!auth.signedIn && !onboarding.seen) return onWelcome ? null : AppRoutes.welcome;
    if (onWelcome) return auth.signedIn ? AppRoutes.home : AppRoutes.login;
    if (!auth.signedIn && !onAuth) return AppRoutes.login;
    if (auth.signedIn && onAuth) return AppRoutes.home;
    return null;
  },
  routes: [
    // 0. First run
    GoRoute(
      path: AppRoutes.welcome,
      name: RouteNames.welcome,
      builder: (_, _) => ChangeNotifierProvider(
        create: (ctx) => OnboardingController(ctx.read()),
        child: const OnboardingScreen(),
      ),
    ),

    // 1. Auth
    GoRoute(path: AppRoutes.login, name: RouteNames.login, builder: (_, _) => _withAuth(const LoginScreen())),
    GoRoute(path: AppRoutes.register, name: RouteNames.register, builder: (_, _) => _withAuth(const RegisterScreen())),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: RouteNames.forgotPassword,
      builder: (_, _) => _withAuth(const ForgotPasswordScreen()),
    ),

    // 2. Shell
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        // Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              name: RouteNames.home,
              builder: (_, _) => ChangeNotifierProvider(
                create: (ctx) => HomeController(ctx.read(), ctx.read(), ctx.read(), ctx.read()),
                child: const HomeScreen(),
              ),
            ),
          ],
        ),
        // Jobs — database, details, and the search flow
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.jobs,
              name: RouteNames.jobs,
              builder: (_, _) => const JobsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: RouteNames.job,
                  builder: (_, state) {
                    final id = state.pathParameters['id']!;
                    return ChangeNotifierProvider(
                      key: ValueKey('job-$id'),
                      create: (ctx) => JobDetailController(id, ctx.read()),
                      child: const JobDetailScreen(),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.upload,
              name: RouteNames.upload,
              builder: (_, _) =>
                  ChangeNotifierProvider(create: (ctx) => UploadController(ctx.read()), child: const UploadScreen()),
            ),
            GoRoute(
              path: AppRoutes.interests,
              name: RouteNames.interests,
              builder: (_, _) => ChangeNotifierProvider(
                create: (ctx) => InterestsController(ctx.read()),
                child: const InterestsScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.sites,
              name: RouteNames.sites,
              builder: (_, _) => ChangeNotifierProvider(
                create: (ctx) => SitesController(ctx.read(), ctx.read(), ctx.read(), ctx.read()),
                child: const SitesScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.runPattern,
              name: RouteNames.run,
              builder: (_, state) {
                final id = state.pathParameters['id']!;
                return ChangeNotifierProvider(
                  key: ValueKey('run-$id'),
                  create: (ctx) => ResultsController(id, ctx.read(), ctx.read()),
                  child: const ResultsScreen(),
                );
              },
            ),
          ],
        ),
        // AI
        StatefulShellBranch(
          routes: [GoRoute(path: AppRoutes.ai, name: RouteNames.ai, builder: (_, _) => const AiScreen())],
        ),
        // Tools
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.tools,
              name: RouteNames.tools,
              builder: (_, _) => const ToolsScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: RouteNames.tool,
                  builder: (_, state) {
                    final tool = toolById(state.pathParameters['id']!);
                    if (tool == null) return const _NotFound();
                    return ChangeNotifierProvider(
                      key: ValueKey('tool-${tool.id}'),
                      create: (ctx) =>
                          ToolRunController(tool, ctx.read(), ctx.read(), ctx.read(), initialInput: state.extra as String?),
                      child: const ToolRunScreen(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              name: RouteNames.profile,
              builder: (_, _) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'career', name: RouteNames.career, builder: (_, _) => const CareerProfileScreen()),
                GoRoute(
                  path: 'preferences',
                  name: RouteNames.jobPreferences,
                  builder: (_, _) => ChangeNotifierProvider(
                    create: (ctx) => JobPreferencesController(ctx.read()),
                    child: const JobPreferencesScreen(),
                  ),
                ),
                GoRoute(
                  path: 'automation',
                  name: RouteNames.automation,
                  builder: (_, _) => const AutomationSettingsScreen(),
                ),
                GoRoute(path: 'history', name: RouteNames.history, builder: (_, _) => const HistoryScreen()),
              ],
            ),
          ],
        ),
      ],
    ),

    // 3. Over the shell
    GoRoute(
      path: AppRoutes.subscribe,
      name: RouteNames.subscribe,
      pageBuilder: (_, state) => MaterialPage(
        key: state.pageKey,
        fullscreenDialog: true,
        child: ChangeNotifierProvider(create: (ctx) => SubscribeController(ctx.read()), child: const SubscribeScreen()),
      ),
    ),
  ],
  errorBuilder: (_, _) => const _NotFound(),
);

Widget _withAuth(Widget screen) =>
    ChangeNotifierProvider(create: (ctx) => AuthController(ctx.read<AuthProvider>()), child: screen);

class _NotFound extends StatelessWidget {
  const _NotFound();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(child: Text("There's nothing here.", style: Theme.of(context).textTheme.bodyLarge)),
  );
}
