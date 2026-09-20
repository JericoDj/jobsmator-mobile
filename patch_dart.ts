import fs from 'fs';

const mobileRunPath = 'lib/core/models/run.dart';
let mobileRunCode = fs.readFileSync(mobileRunPath, 'utf8');
mobileRunCode = mobileRunCode.replace('final int fetchedUnique, alreadyProcessed, scored, recommended;', 'final int fetchedUnique, alreadyProcessed, scored, recommended;\n  final String? feedback;');
mobileRunCode = mobileRunCode.replace('required this.recommended,', 'required this.recommended,\n    this.feedback,');
mobileRunCode = mobileRunCode.replace('recommended: j[\'recommended\'],', 'recommended: j[\'recommended\'],\n    feedback: j[\'feedback\'],');
fs.writeFileSync(mobileRunPath, mobileRunCode);
console.log("Patched mobile run.dart");
