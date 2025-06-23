import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'clear_sky_app.dart';
import 'screens/config_error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey.startsWith('REPLACE_WITH')) {
      throw Exception(
          'Firebase API key not configured. Update lib/src/core/firebase_options.dart');
    }
    await Firebase.initializeApp(options: options);
    runApp(const ClearSkyApp());
  } catch (e) {
    runApp(ConfigErrorScreen(error: e.toString()));
  }
}

