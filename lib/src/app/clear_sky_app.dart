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
import '../core/services/theme_service.dart';
import '../core/services/accessibility_service.dart';
import '../core/models/inspection_metadata.dart';
import '../core/models/peril_type.dart';
import '../core/models/inspection_type.dart';
import '../core/models/inspector_report_role.dart';
import '../core/utils/debug_init.dart';

final InspectionMetadata dummyMetadata = InspectionMetadata(
  clientName: 'John Doe',
  propertyAddress: '123 Main St',
  inspectionDate: DateTime.now(),
  insuranceCarrier: 'Acme Insurance',
  perilType: PerilType.hail,
  inspectionType: InspectionType.residentialRoof,
  inspectorRoles: {InspectorReportRole.adjuster},
);

/// All routes registered with the application.
final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const SplashScreen(),
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  '/home': (context) => const HomeScreen(
        freeReportsRemaining: 3,
        isSubscribed: false,
      ),
  '/projectDetails': (context) => const ProjectDetailsScreen(),
  '/reportPreview': (context) => ReportPreviewScreen(metadata: dummyMetadata),
  '/settings': (context) => const SettingsScreen(),
  // Navigation to guided capture uses arguments
};

class ClearSkyApp extends StatelessWidget {
  const ClearSkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    final accessService = AccessibilityService.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([themeService, accessService]),
      builder: (context, _) {
        final settings = accessService.settings;
        final lightTheme = settings.highContrast
            ? AppTheme.highContrastTheme
            : themeService.lightTheme;
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          navigatorObservers: [LoggingNavigatorObserver()],
          title: 'ClearSky Photo Reports',
          theme: lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              settings.highContrast ? ThemeMode.light : themeService.themeMode,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                accessibleNavigation: settings.screenReader,
                disableAnimations: settings.reducedMotion, textScaler: TextScaler.linear(settings.textScale),
              ),
              child: child!,
            );
          },
          initialRoute: '/',
          routes: appRoutes,
          onGenerateRoute: (settings) {
            if (settings.name == '/guidedCapture' ||
                settings.name == '/capture') {
              final args = settings.arguments;
              String inspectionId = '';
              if (args is String) {
                inspectionId = args;
              } else if (args is Map<String, dynamic>) {
                inspectionId = args['inspectionId'] as String? ?? '';
              }
              return MaterialPageRoute(
                builder: (context) =>
                    GuidedCaptureScreen(inspectionId: inspectionId),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
