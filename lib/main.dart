import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'clear_sky_app.dart';
import 'screens/config_error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const ClearSkyApp());
  } catch (e) {
    runApp(ConfigErrorScreen(error: e.toString()));
  }
}

