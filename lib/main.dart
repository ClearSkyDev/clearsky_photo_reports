import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'app_theme.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';
import 'screens/photo_upload_screen.dart';
import 'screens/report_preview_screen.dart';
import 'screens/client_signature_screen.dart';
import 'screens/inspection_checklist_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/admin_audit_log_screen.dart';
import 'client_portal/client_report_screen.dart';
import 'client_portal/client_dashboard_screen.dart';
import 'models/inspector_user.dart';
import 'models/inspection_metadata.dart';
import 'models/inspection_type.dart';
import 'models/checklist_template.dart';

import 'main_nav_scaffold.dart';
import 'client_portal_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ThemeService.instance.init();

  runApp(const ClearSkyApp());
}

class ClearSkyApp extends StatelessWidget {
  const ClearSkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = <String, WidgetBuilder>{
      '/': (context) {
        const bool showClientPortal = false; // toggle for demo
        if (showClientPortal) return const ClientPortalMain();
        return MainNavScaffold(
          user: InspectorUser(uid: 'demo', role: UserRole.inspector),
        );
      },
      '/upload': (context) => const PhotoUploadScreen(),
      '/preview': (context) => ReportPreviewScreen(
            metadata: InspectionMetadata(
              clientName: 'Demo Client',
              propertyAddress: '123 Demo St',
              inspectionDate: DateTime.now(),
              perilType: PerilType.wind,
              inspectionType: InspectionType.residentialRoof,
              inspectorRole: InspectorReportRole.ladder_assist,
            ),
          ),
      '/signature': (context) => const ClientSignatureScreen(),
      '/checklist': (context) => const InspectionChecklistScreen(),
      '/analytics': (context) => const AnalyticsDashboardScreen(allMetrics: []), // Replace with real
      '/audit': (context) => const AdminAuditLogScreen(logs: []), // Replace with real
      '/clientDashboard': (context) => const ClientDashboardScreen(),
      '/clientReport': (context) => const ClientReportScreen(),
      '/clientPortal': (context) => const ClientPortalMain(),
    };

    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'ClearSky Photo Reports',
          debugShowCheckedModeBanner: false,
          theme: ThemeService.instance.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          initialRoute: '/',
          routes: routes,
        );
      },
    );
  }
}
