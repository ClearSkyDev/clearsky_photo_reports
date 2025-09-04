import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'clear_sky_app.dart';
import 'src/core/utils/logging.dart';
import 'src/core/services/theme_service.dart';
import 'src/core/services/accessibility_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crashlytics: capture unhandled Flutter and platform errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await runZonedGuarded<Future<void>>(
    () async {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await ThemeService.instance.init();
        await AccessibilityService.instance.init();
      } catch (e, st) {
        logWarn('Firebase init failed; continuing in degraded mode', e);
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'Firebase init',
        );
      }
      runApp(const ClearSkyApp());
    },
    (error, stack) {
      logError('Uncaught zone error', error, stack);
    },
  );
}
