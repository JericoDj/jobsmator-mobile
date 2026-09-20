import fs from 'fs';
const path = 'lib/features/home/home_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const oldCode = `    // Until the catalogue has anything real, every row runs on the fixture
    // jobs and says so — the layout should never sit empty.
    final sample = catalog.all.isEmpty;
    final jobs = sample
        ? fixtureJobs.map((j) => Job.fromJson(j)).toList()
        : catalog.all.where((j) => !j.hidden).toList();`;

const newCode = `    final sample = false;
    final jobs = catalog.all.where((j) => !j.hidden).toList();`;

code = code.replace(oldCode, newCode);
fs.writeFileSync(path, code);
console.log("Patched HomeScreen mock data");
