import 'package:go_router/go_router.dart';

import '../features/auth/sign_in_screen.dart';
import '../features/preferences/interests_screen.dart';
import '../features/preferences/sites_screen.dart';
import '../features/results/results_screen.dart';
import '../features/upload/upload_screen.dart';
import '../providers/auth_provider.dart';

GoRouter buildRouter(AuthProvider auth) => GoRouter(
      initialLocation: '/upload',
      refreshListenable: auth,
      redirect: (_, state) {
        final signedIn = auth.user != null;
        final onSignIn = state.matchedLocation == '/sign-in';
        if (!signedIn && !onSignIn) return '/sign-in';
        if (signedIn && onSignIn) return '/upload';
        return null;
      },
      routes: [
        GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
        GoRoute(path: '/upload', builder: (_, _) => const UploadScreen()),
        GoRoute(path: '/interests', builder: (_, _) => const InterestsScreen()),
        GoRoute(path: '/sites', builder: (_, _) => const SitesScreen()),
        GoRoute(path: '/runs/:id', builder: (_, s) => ResultsScreen(runId: s.pathParameters['id']!)),
      ],
    );
