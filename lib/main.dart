import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/core/firebase_options.dart';
import 'src/core/services/offline_sync_service.dart';
import 'src/core/services/notification_service.dart';

import 'src/features/screens/client_dashboard_screen.dart';
import 'src/features/screens/guided_capture_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await OfflineSyncService.instance.init();
  await NotificationService.instance.init();

  runApp(const ClearSkyApp());
}

class ClearSkyApp extends StatelessWidget {
  const ClearSkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearSky Photo Reports',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        appBarTheme: const AppBarTheme(
          elevation: 2,
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueGrey,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ClientDashboardScreen(),
        '/capture': (context) => const GuidedCaptureScreen(),
        // Add more routes as needed
        // '/upload': (context) => SectionedPhotoUploadScreen(),
        // '/send': (context) => SendReportScreen(),
      },
    );
  }
}
