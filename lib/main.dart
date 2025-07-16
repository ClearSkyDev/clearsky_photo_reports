import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'clear_sky_app.dart';
import 'screens/config_error_screen.dart';
import 'src/core/services/theme_service.dart';
import 'src/core/services/accessibility_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey.startsWith('REPLACE_WITH') ||
        options.apiKey.contains('Example')) {
      throw Exception(
          'Firebase API key not configured. Update lib/firebase_options.dart');
    }
    await Firebase.initializeApp(options: options);
    await ThemeService.instance.init();
    await AccessibilityService.instance.init();
    runApp(const ClearSkyApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: ConfigErrorScreen(error: e.toString()),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

