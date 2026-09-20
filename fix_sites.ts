import fs from 'fs';
let code = fs.readFileSync('lib/features/preferences/sites_screen.dart', 'utf8');
code = code.replace(/_ErrorText\("You've used .*/g, "_ErrorText(\"You've used \\${ctrl.plan.searchLimit} searches \\${ctrl.plan.periodLabel}.\"),");
fs.writeFileSync('lib/features/preferences/sites_screen.dart', code);
