import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/photo_upload_screen.dart';
import 'screens/report_preview_screen.dart';
import 'screens/client_signature_screen.dart';
import 'screens/checklist_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/admin_audit_log_screen.dart';
import 'screens/client_report_screen.dart';
import 'screens/client_dashboard_screen.dart';

import 'main_nav_scaffold.dart';
import 'client_portal_main.dart';

void main() async {
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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainNavScaffold(), // Or ClientPortalMain() based on auth/role
        '/upload': (context) => const PhotoUploadScreen(),
        '/preview': (context) => const ReportPreviewScreen(),
        '/signature': (context) => const ClientSignatureScreen(),
        '/checklist': (context) => const ChecklistScreen(),
        '/analytics': (context) => const AnalyticsDashboardScreen(allMetrics: []), // Replace with real
        '/audit': (context) => const AdminAuditLogScreen(logs: []), // Replace with real
        '/clientDashboard': (context) => const ClientDashboardScreen(),
        '/clientReport': (context) => const ClientReportScreen(),
        '/clientPortal': (context) => const ClientPortalMain(),
      },
    );
  }
}
