import fs from 'fs';

const enginePath = '../jobsmator-backend/src/contracts/engine.ts';
let engineCode = fs.readFileSync(enginePath, 'utf8');
engineCode = engineCode.replace('jobs: z.array(EngineJob),', 'recommendation: z.string().optional(),\n  jobs: z.array(EngineJob),');
fs.writeFileSync(enginePath, engineCode);
console.log("Patched engine.ts");

const runsContractPath = '../jobsmator-backend/src/contracts/runs.ts';
let runsContractCode = fs.readFileSync(runsContractPath, 'utf8');
runsContractCode = runsContractCode.replace('recommended: z.number(),', 'recommended: z.number(),\n  feedback: z.string().optional(),');
fs.writeFileSync(runsContractPath, runsContractCode);
console.log("Patched runs.ts contract");

const runsRoutePath = '../jobsmator-backend/src/routes/runs.ts';
let runsRouteCode = fs.readFileSync(runsRoutePath, 'utf8');
runsRouteCode = runsRouteCode.replace('tier: (j.score >= 70 ? "strong" : "good") as "strong" | "good",', 'tier: (j.score >= 70 ? "strong" : j.score >= body.minScore ? "good" : "skip") as "strong" | "good" | "skip",');
runsRouteCode = runsRouteCode.replace('stats: result.stats ?? null,', 'stats: result.stats ? { ...result.stats, feedback: result.recommendation } : null,');
fs.writeFileSync(runsRoutePath, runsRouteCode);
console.log("Patched runs.ts route");

const mobileRunPath = 'lib/core/models/run.dart';
let mobileRunCode = fs.readFileSync(mobileRunPath, 'utf8');
mobileRunCode = mobileRunCode.replace('final int fetchedUnique, alreadyProcessed, scored, recommended;', 'final int fetchedUnique, alreadyProcessed, scored, recommended;\n  final String? feedback;');
mobileRunCode = mobileRunCode.replace('required this.recommended,', 'required this.recommended,\n    this.feedback,');
mobileRunCode = mobileRunCode.replace('recommended: j[\'recommended\'],', 'recommended: j[\'recommended\'],\n    feedback: j[\'feedback\'],');
fs.writeFileSync(mobileRunPath, mobileRunCode);
console.log("Patched mobile run.dart");
