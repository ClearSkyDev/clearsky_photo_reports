import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/metadata_screen.dart';
import 'screens/sectioned_photo_upload_screen.dart';
import 'screens/report_history_screen.dart';
import 'screens/report_settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ClearSkyApp());
}

class ClearSkyApp extends StatelessWidget {
  const ClearSkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearSky Photo Reports',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/report': (context) => const ReportScreen(),
        '/metadata': (context) => const MetadataScreen(),
        '/sectionedUpload': (context) => const SectionedPhotoUploadScreen(),
        '/history': (context) => const ReportHistoryScreen(),
        '/settings': (context) => const ReportSettingsScreen(),
      },
    );
  }
}