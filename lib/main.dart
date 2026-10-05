import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/billing/store_billing.dart';
import 'core/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.preview) {
    // Generate lib/firebase_options.dart with `flutterfire configure`, then:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Firebase.initializeApp();
  }
  // No-op without RC_API_KEY_IOS/ANDROID or in preview builds.
  await StoreBilling.configure();
  // Read before the first frame so the router knows whether to show the tour.
  runApp(JobsMatorApp(prefs: await SharedPreferences.getInstance()));
}
