/// Route paths and names.
///
/// Four groups: the welcome tour, auth (outside the shell), the five-tab
/// shell, and pushed screens (details, tools, settings pages, the paywall).
abstract final class AppRoutes {
  // First run
  static const welcome = '/welcome';

  // Auth
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Shell · Home
  static const home = '/home';

  // Shell · Jobs — the database, plus the search flow (guide §06 steps)
  static const jobs = '/jobs';
  static const jobPattern = '/jobs/:id';
  static String job(String id) => '/jobs/$id';
  static const upload = '/find'; // step 1
  static const interests = '/find/interests'; // step 2
  static const sites = '/find/sites'; // step 3
  static const runPattern = '/find/runs/:id'; // step 4
  static String run(String id) => '/find/runs/$id';

  // Shell · AI
  static const ai = '/ai';

  // Shell · Tools
  static const tools = '/tools';
  static const toolPattern = '/tools/:id';
  static String tool(String id) => '/tools/$id';

  // Shell · Profile
  static const profile = '/profile';
  static const career = '/profile/career';
  static const jobPreferences = '/profile/preferences';
  static const automation = '/profile/automation';
  static const history = '/profile/history';

  // Over the shell
  static const subscribe = '/subscribe';

  static const authRoutes = {login, register, forgotPassword};
}

abstract final class RouteNames {
  static const welcome = 'welcome';
  static const login = 'login';
  static const register = 'register';
  static const forgotPassword = 'forgot-password';
  static const home = 'home';
  static const jobs = 'jobs';
  static const job = 'job';
  static const upload = 'upload';
  static const interests = 'interests';
  static const sites = 'sites';
  static const run = 'run';
  static const ai = 'ai';
  static const tools = 'tools';
  static const tool = 'tool';
  static const profile = 'profile';
  static const career = 'career';
  static const jobPreferences = 'job-preferences';
  static const automation = 'automation';
  static const history = 'history';
  static const subscribe = 'subscribe';
}
