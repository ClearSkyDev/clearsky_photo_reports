import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'clear_sky_app.dart';
import 'src/core/services/theme_service.dart';
import 'src/core/services/accessibility_service.dart';
import 'src/core/services/demo_mode_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (!options.apiKey.contains('Example') &&
        !options.apiKey.startsWith('REPLACE_WITH')) {
      await Firebase.initializeApp(options: options);
    } else {
      throw Exception('Firebase API key not configured');
    }
  } catch (e) {
    DemoModeService.instance.enable();
    print('⚠️ Running in demo mode: Firebase not initialized.');
  }
  await ThemeService.instance.init();
  await AccessibilityService.instance.init();
  if (DemoModeService.instance.isEnabled) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            const ClearSkyApp(),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.orange,
                padding: const EdgeInsets.all(8),
                child: const Text(
                  '⚠️ Running in Demo Mode — Firebase disabled',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  } else {
    runApp(const ClearSkyApp());
  }
}

