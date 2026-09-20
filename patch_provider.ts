import fs from 'fs';
const path = 'lib/providers/job_catalog_provider.dart';
let code = fs.readFileSync(path, 'utf8');
code = code.replace(
  '  Future<Job?> fetch(String id) async {',
  `  Future<Job> scoreJob(String id) async {
    final res = await _api.post('/v1/jobs/$id/score');
    final job = Job.fromJson(res);
    _jobs = [..._jobs, job];
    notifyListeners();
    return job;
  }

  Future<Job?> fetch(String id) async {`
);
fs.writeFileSync(path, code);
