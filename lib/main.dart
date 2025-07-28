import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'clear_sky_app.dart';
import 'src/core/utils/logging.dart';
import 'src/core/services/theme_service.dart';
import 'src/core/services/accessibility_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await ThemeService.instance.init();
    await AccessibilityService.instance.init();
    runApp(const ClearSkyApp());
  } catch (e, stack) {
    logger().d('Firebase initialization failed: $e\n$stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to initialize Firebase. Please check configuration.\n\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

