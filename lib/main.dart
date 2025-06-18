import 'package:flutter/material.dart';
import 'package:clearsky_photo_reports/screens/home_screen.dart';
import 'package:clearsky_photo_reports/screens/photo_upload_screen.dart';
import 'package:clearsky_photo_reports/screens/report_preview_screen.dart';
import 'package:clearsky_photo_reports/screens/client_signature_screen.dart';
import 'package:clearsky_photo_reports/screens/checklist_screen.dart';
import 'package:clearsky_photo_reports/screens/analytics_dashboard_screen.dart';
import 'package:clearsky_photo_reports/screens/admin_audit_log_screen.dart';
import 'package:clearsky_photo_reports/theme/app_theme.dart';

void main() {
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
        '/': (context) => const HomeScreen(),
        '/upload': (context) => const PhotoUploadScreen(),
        '/preview': (context) => const ReportPreviewScreen(),
        '/signature': (context) => const ClientSignatureScreen(),
        '/checklist': (context) => const ChecklistScreen(),
        '/analytics': (context) => const AnalyticsDashboardScreen(
            allMetrics: []), // Replace with real data
        '/audit': (context) =>
            const AdminAuditLogScreen(logs: []), // Replace with real data
      },
    );
  }
}
