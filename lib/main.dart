import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'clear_sky_app.dart';
import 'src/core/services/theme_service.dart';
import 'src/core/services/accessibility_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[Main] Launching Flutter app');
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (!options.apiKey.contains('Example') &&
        !options.apiKey.startsWith('REPLACE_WITH')) {
      await Firebase.initializeApp(options: options);
      debugPrint('[Firebase] Initialized for project ${options.projectId}');
    } else {
      throw Exception('Firebase API key not configured');
    }
  } catch (e) {
    debugPrint('[Firebase] Initialization failed: $e');
    print('⚠️ Running in demo mode: Firebase not initialized.');
  }
  await ThemeService.instance.init();
  await AccessibilityService.instance.init();
  runApp(const ClearSkyApp());
}

