import fs from 'fs';
const path = 'lib/core/models/subscription.dart';
let code = fs.readFileSync(path, 'utf8');

code = code.replace('int get limit => this == free ? 1 : 5;', 'int get limit => this == free ? 1 : 30;');
fs.writeFileSync(path, code);
console.log("Patched limit in mobile app");

const backendPath = '../jobsmator-backend/.env';
let backendCode = fs.readFileSync(backendPath, 'utf8');
backendCode = backendCode.replace('RUNS_PER_HOUR=5', 'RUNS_PER_HOUR=30');
fs.writeFileSync(backendPath, backendCode);
console.log("Patched backend env");

const backendRunsPath = '../jobsmator-backend/src/lib/env.ts';
let backendRunsCode = fs.readFileSync(backendRunsPath, 'utf8');
backendRunsCode = backendRunsCode.replace('RUNS_PER_HOUR: z.coerce.number().default(5),', 'RUNS_PER_HOUR: z.coerce.number().default(30),');
fs.writeFileSync(backendRunsPath, backendRunsCode);
console.log("Patched backend env.ts");
