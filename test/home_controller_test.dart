import 'package:flutter_test/flutter_test.dart';
import 'package:jobsmator_mobile/controllers/home_controller.dart';
import 'package:jobsmator_mobile/core/api/mock_api_client.dart';
import 'package:jobsmator_mobile/providers/job_catalog_provider.dart';
import 'package:jobsmator_mobile/providers/preferences_provider.dart';
import 'package:jobsmator_mobile/providers/resume_provider.dart';
import 'package:jobsmator_mobile/providers/run_provider.dart';
import 'package:jobsmator_mobile/providers/subscription_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<HomeController> build(MockApiClient api) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final catalog = JobCatalogProvider(api);
    final runs = RunProvider(api);
    final preferences = PreferencesProvider(api);
    final subs = SubscriptionProvider(api);
    final resumes = ResumeProvider(api, prefs, uid: 'u_1');
    await Future.wait([catalog.load(), runs.loadHistory(), preferences.load(), subs.load(), resumes.load()]);
    return HomeController(catalog, runs, preferences, subs, resumes);
  }

  test('hasResume is false until a resume has been uploaded', () async {
    final api = MockApiClient();
    final ctrl = await build(api);
    expect(ctrl.hasResume, isFalse);

    await api.post('/v1/resumes', body: {'filename': 'resume.pdf', 'sizeBytes': 1024});
    final ctrl2 = await build(api);
    expect(ctrl2.hasResume, isTrue);
  });

  test('strongMatchRate is the share of non-hidden strong-tier jobs', () async {
    final api = MockApiClient();
    final ctrl = await build(api);
    // The fixture catalogue has 8 non-hidden jobs; the client enforces the
    // 70+ rule client-side, so 4 read as strong regardless of the fixture's
    // own tier label (see Job.fromJson).
    expect(ctrl.totalJobs, 8);
    expect(ctrl.strongMatchRate, closeTo(4 / 8, 0.0001));
  });

  test('strongMatchRate is 0 with no jobs, never divides by zero', () async {
    final api = MockApiClient();
    // Hide every fixture job so the catalogue is empty of live jobs.
    for (final id in ['j1', 'j2', 'j3', 'j4', 'j5', 'j6', 'j7', 'j8']) {
      await api.post('/v1/jobs/$id/hide');
    }
    final ctrl = await build(api);
    expect(ctrl.totalJobs, 0);
    expect(ctrl.strongMatchRate, 0);
  });
}
