import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/metadata_screen.dart';
import 'screens/sectioned_photo_upload_screen.dart';
import 'screens/report_history_screen.dart';
import 'screens/report_settings_screen.dart';
import 'screens/report_theme_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'models/inspector_profile.dart';
import 'utils/profile_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final profile = await ProfileStorage.load();
  runApp(ClearSkyApp(initialProfile: profile));
}

class ClearSkyApp extends StatelessWidget {
  final InspectorProfile? initialProfile;
  const ClearSkyApp({super.key, this.initialProfile});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearSky Photo Reports',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: initialProfile == null ? '/login' : '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/report': (context) => const ReportScreen(),
        '/metadata': (context) => const MetadataScreen(),
        '/sectionedUpload': (context) => const SectionedPhotoUploadScreen(),
        '/history': (context) => const ReportHistoryScreen(),
        '/settings': (context) => const ReportSettingsScreen(),
        '/theme': (context) => const ReportThemeScreen(),
      },
    );
  }
}