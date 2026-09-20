import fs from 'fs';
const path = 'lib/core/config.dart';
let code = fs.readFileSync(path, 'utf8');

const insertion = `  static const fbApiKey = String.fromEnvironment('FB_API_KEY', defaultValue: '');
  static const fbAppId = String.fromEnvironment('FB_APP_ID', defaultValue: '1:655823055418:ios:ca8d8102ff4b248a8039bc');
  static const fbMessagingSenderId = String.fromEnvironment('FB_MSG_ID', defaultValue: '655823055418');
  static const fbProjectId = String.fromEnvironment('FB_PROJECT_ID', defaultValue: 'jobsmator');
  static const fbStorageBucket = String.fromEnvironment('FB_STORAGE_BUCKET', defaultValue: 'mondaymobile-3adca.firebasestorage.app');
`;

if (!code.includes('fbStorageBucket')) {
  code = code.replace('abstract final class AppConfig {', 'abstract final class AppConfig {\n' + insertion);
  fs.writeFileSync(path, code);
  console.log("Patched config.dart");
}
