import 'package:flutter/material.dart';

import 'app_theme.dart';
import '../features/screens/splash_screen.dart';
import '../features/screens/login_screen.dart';
import '../features/screens/signup_screen.dart';
import '../features/screens/home_screen.dart';
import '../features/screens/project_details_screen.dart';
import '../features/screens/guided_capture_screen.dart';
import '../features/screens/report_preview_screen.dart';
import '../features/screens/settings_screen.dart';
import '../core/models/inspection_metadata.dart';
import '../core/models/peril_type.dart';
import '../core/models/inspection_type.dart';
import '../core/models/inspector_report_role.dart';

final InspectionMetadata dummyMetadata = InspectionMetadata(
  clientName: 'John Doe',
  propertyAddress: '123 Main St',
  inspectionDate: DateTime.now(),
  insuranceCarrier: 'Acme Insurance',
  perilType: PerilType.hail,
  inspectionType: InspectionType.residentialRoof,
  inspectorRoles: {InspectorReportRole.adjuster},
);

class ClearSkyApp extends StatelessWidget {
  const ClearSkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearSky Photo Reports',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(
              freeReportsRemaining: 3,
              isSubscribed: false,
            ),
        '/projectDetails': (context) => const ProjectDetailsScreen(),
        '/reportPreview':
            (context) => ReportPreviewScreen(metadata: dummyMetadata),
        '/settings': (context) => const SettingsScreen(),
        // Navigation to guided capture uses arguments
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/guidedCapture' || settings.name == '/capture') {
          final args = settings.arguments;
          String inspectionId = '';
          if (args is String) {
            inspectionId = args;
          } else if (args is Map<String, dynamic>) {
            inspectionId = args['inspectionId'] as String? ?? '';
          }
          return MaterialPageRoute(
            builder: (context) => GuidedCaptureScreen(inspectionId: inspectionId),
          );
        }
        return null;
      },
    );
  }
}
