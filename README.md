# jobsmator-mobile

Flutter app for JobsMator (Provider + go_router). Architecture: `../ARCHITECTURE.md`.
Visual language: `../docs/design-guide.html` (v1.1) — every token in `lib/app/theme/` traces back to it.

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

### Preview mode (no Firebase, no backend)

```bash
flutter run --dart-define=PREVIEW=true
```

Signs in a fixture user, serves fixture jobs from `MockApiClient`, and stands in a fake
resume for the document picker. A mock run takes ~9 s so the search-progress state is visible.
Use it for design work and screenshots.

## Layout

```
lib/
  main.dart               Firebase init (skipped in preview) → JobsMatorApp
  app/
    app.dart              Provider tree: Auth → ApiClient → Resume, Preferences, Run, Jobs, JobCatalog, Subscription, Ai
    router.dart           go_router: auth routes → tab shell (StatefulShellRoute) → full-screen paywall
    routes.dart           AppRoutes / RouteNames
    theme/
      tokens.dart         JmColors (light + dark), JmTierColors, JmSpace, JmRadius, JmMotion
      typography.dart     JmText — the guide's type scale (Outfit / Instrument Sans / JetBrains Mono)
      theme.dart          buildTheme(): ColorScheme mapping + component themes
  core/
    api/                  ApiClient (abstract), HttpApiClient (Dio + ID token), MockApiClient
    models/               Job, Run, Resume, UserDefaults, AppUser (mirror packages/contracts);
                          Subscription, CareerProfile, Automation, Tool (app-side, not in contracts yet)
    ai/                   AiService + MockAiService
    copy.dart             Voice & copy: error codes → sentences, headline, relative time
    config.dart           API_URL, PREVIEW dart-defines
  providers/              App-scoped ChangeNotifiers (data + long-lived state)
    auth_provider         Firebase user → AppUser; the router listens to it
    resume_provider       Resume list; upload to Storage with progress, then POST /v1/resumes
    preferences_provider  Interests, sites, limits (GET/PATCH /v1/me)
    run_provider          Current run + 3 s polling; run history; "unseen result" flag for the nav dot
    jobs_provider         Jobs for a run: tier filter, weaker-tier disclosure, optimistic save/hide
    job_catalog_provider  Every job across runs: search, filters, save/hide/apply (the Jobs tab + Home)
    ai_provider           Assistant thread; talks to AiService
    subscription_provider Plan + quota (from /v1/me); upgrade via /v1/billing/checkout
  controllers/            Screen-scoped ChangeNotifiers, created per route, disposed with the screen
    auth_controller       login / register / reset: busy, one error line, done flag
    subscribe_controller  paywall: selected plan, busy, error
    home_controller       derives the dashboard numbers, recommendations, suggestion, activity
    tool_run_controller   one tool run: input → busy → result; locked on Free for premium tools
    upload_controller     file pick + size check → ResumeProvider
    interests_controller  add/remove with the 5-title limit and hints
    sites_controller      save prefs, start run; needsUpgrade gates on the plan (quota, site limit, Sheets)
    results_controller    ties Run + Jobs to one run id; search progress estimate; export
  features/
    auth/                 LoginScreen, RegisterScreen, ForgotPasswordScreen on one AuthScaffold (navy hero)
    shell/                AppShell + JmBottomNav — Home · Jobs · AI · Tools · Profile (Volt dot on Jobs for new results)
    home/                 HomeScreen — the command centre
    jobs/                 JobsScreen (database), JobDetailScreen, JobRow (compact list row)
    ai/                   AiScreen — assistant chat + suggested actions
    tools/                ToolsScreen (grid), ToolRunScreen (generic runner)
    upload/               UploadScreen, Dropzone, ResumeTile              — step 1
    preferences/          InterestsScreen, SitesScreen                     — steps 2, 3
    results/              ResultsScreen + JobCard, ScoreRing, SummaryTiles,
                          SearchProgressView, EmptyState, StaggeredEntry  — step 4
    history/              HistoryScreen — past runs with stats, tap to reopen
    profile/              ProfileScreen, CareerProfileScreen, JobPreferencesScreen, AutomationSettingsScreen
    subscription/         SubscribeScreen — the paywall: Free vs Pro cards, one Cobalt CTA
    shared/widgets/       JmPage, StepHeader/StepBars, SelectionChip, TierBadge, FlagChip,
                          PrimaryButton/SecondaryButton/DangerButton, showJmToast,
                          HighlightedText, JmLogoMark/JmWordmark
```

### Routes

| Route | Where | Notes |
|---|---|---|
| `/login`, `/register`, `/forgot-password` | outside the shell | redirect target when signed out |
| `/home` | **Home** tab | greeting, stats, recommended jobs, AI suggestion, quick actions, automations, recent activity |
| `/jobs`, `/jobs/:id` | **Jobs** tab | the job database: search, filters, detail with Apply + already-applied |
| `/find` → `/find/interests` → `/find/sites` → `/find/runs/:id` | Jobs tab | the guide's four search steps |
| `/ai` | **AI** tab | assistant chat; suggestions jump straight to flows/tools |
| `/tools`, `/tools/:id` | **Tools** tab | tool grid + generic runner (input → result); premium tools gate on the plan |
| `/profile`, `/profile/career`, `/profile/preferences`, `/profile/automation`, `/profile/history` | **Profile** tab | AI profile, job preferences, sources, automation settings, plan, sign out |
| `/subscribe` | full-screen over the shell | the paywall; on upgrade the blocked action continues |

Plans: **Free** — 1 search/day, 3 sites, no Sheets, no premium tools. **Pro** (₱299/mo) — 5 searches/hour, all ten sites, Sheets, every tool.

Stubs to replace when the API grows (all mocked in `MockApiClient`): `GET /v1/jobs`, `POST /v1/jobs/:id/apply`,
`subscription` / `profile` / `automations` / `settings` on `/v1/me`, `PATCH /v1/automations/:id`, `POST /v1/billing/checkout`,
and `AiService` (chat + tools) behind `MockAiService`.

### Conventions

- **Providers** hold data and outlive screens. **Controllers** hold UI state for one screen and
  orchestrate providers; they never import go_router — screens navigate on the controller's result.
- Read tokens through the theme: `context.jm` (palette), `context.tiers`, `context.type`.
  No hard-coded colours or font sizes in widgets.
- One Cobalt primary per view. Green only for an earned result. Volt only as a highlighter.
- Copy comes from `JmCopy` or reads like the guide's voice: second person, specific numbers,
  never "skip", never an error code.

## Test

```bash
flutter test
```
