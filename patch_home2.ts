import fs from 'fs';
const path = 'lib/features/home/home_screen.dart';
let code = fs.readFileSync(path, 'utf8');

code = code.replace(/final sample = false;\n/, '');
code = code.replace(/badge: sample \? 'Sample' : null,/g, '');
code = code.replace(/onTap: sample\s*\n\s*\? null\s*\n\s*: \(\) => context\.push\(AppRoutes\.job\(job\.id\)\),/g, "onTap: () => context.push(AppRoutes.job(job.id)),");
code = code.replace(/import '\.\.\/\.\.\/core\/api\/mock_api_client\.dart';\n/, '');

fs.writeFileSync(path, code);
console.log("Patched HomeScreen dead code");
