import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/inspector_user.dart';
import 'main_nav_scaffold.dart';
import 'screens/login_screen.dart';
import 'screens/report_history_screen.dart';
import 'screens/manage_team_screen.dart';

import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/metadata_screen.dart';
import 'screens/sectioned_photo_upload_screen.dart';
import 'screens/drone_media_upload_screen.dart';
import 'screens/report_settings_screen.dart';
import 'screens/report_theme_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/template_manager_screen.dart';
import 'screens/partner_dashboard_screen.dart';
import 'screens/public_report_screen.dart';
import 'screens/public_links_screen.dart';
import 'screens/client_signature_screen.dart';
import 'screens/signature_status_screen.dart';
import 'screens/report_map_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/report_search_screen.dart';
import 'screens/invoice_list_screen.dart';
import 'screens/admin_audit_log_screen.dart';
import 'screens/create_invoice_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/learning_settings_screen.dart';
import 'services/auth_service.dart';
import 'services/offline_sync_service.dart';
import 'services/notification_service.dart';
import 'services/changelog_service.dart';
import 'services/tts_service.dart';
import 'services/accessibility_service.dart';
import 'models/checklist.dart';
import 'screens/changelog_screen.dart';
import 'screens/accessibility_settings_screen.dart';
import 'app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await OfflineSyncService.instance.init();
  await NotificationService.instance.init();
  await ChangelogService.instance.init();
  await TtsService.instance.init();
  await AccessibilityService.instance.init();
  await inspectionChecklist.loadSaved();
  runApp(const ClearSkyApp());
}

class ClearSkyApp extends StatefulWidget {
  const ClearSkyApp({super.key});

  @override
  State<ClearSkyApp> createState() => _ClearSkyAppState();
}

class _ClearSkyAppState extends State<ClearSkyApp> {
  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.addListener(_onUpdate);
  }

  void _onUpdate() => setState(() {});

  @override
  void dispose() {
    AccessibilityService.instance.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClearSky Photo Reports',
      theme: AppTheme.build(highContrast: AccessibilityService.instance.settings.highContrast),
      builder: (context, child) {
        final s = AccessibilityService.instance.settings;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: s.textScale,
            disableAnimations: s.reducedMotion,
          ),
          child: child!,
        );
      },
      routes: {
        '/home': (context) => const HomeScreen(),
        '/report': (context) => const ReportScreen(),
        '/metadata': (context) => const MetadataScreen(),
        '/sectionedUpload': (context) => const SectionedPhotoUploadScreen(),
        '/droneMedia': (context) => const DroneMediaUploadScreen(),
        '/history': (context) => const ReportHistoryScreen(),
        '/settings': (context) => const ReportSettingsScreen(),
        '/theme': (context) => const ReportThemeScreen(),
        '/templates': (context) => const TemplateManagerScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/manageTeam': (context) => const ManageTeamScreen(),
        '/publicLinks': (context) => const PublicLinksScreen(),
        '/signatureStatus': (context) => const SignatureStatusScreen(),
        '/reportMap': (context) => const ReportMapScreen(),
        '/analytics': (context) => const AnalyticsDashboardScreen(),
        '/adminLogs': (context) => const AdminAuditLogScreen(),
        '/search': (context) => const ReportSearchScreen(),
        '/invoices': (context) => const InvoiceListScreen(),
        '/notifications': (context) => const NotificationSettingsScreen(),
        '/learning': (context) => const LearningSettingsScreen(),
        '/changelog': (context) => const ChangelogScreen(),
        '/accessibility': (context) => const AccessibilitySettingsScreen(),
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        if (name.startsWith('/public/') && name.endsWith('/sign')) {
          final id =
              name.substring('/public/'.length, name.length - '/sign'.length);
          return MaterialPageRoute(
              builder: (_) => ClientSignatureScreen(reportId: id));
        }
        if (name.startsWith('/public/')) {
          final id = name.substring('/public/'.length);
          return MaterialPageRoute(
              builder: (_) => PublicReportScreen(publicId: id));
        }
        return null;
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const LoginScreen();
        }
        return FutureBuilder<InspectorUser?>(
          future: AuthService().fetchUser(snapshot.data!.uid),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.data == null) {
              return const LoginScreen();
            }
            final user = snap.data!;
            if (user.role == UserRole.partner) {
              return PartnerDashboardScreen(partnerId: user.uid);
            }
            return MainNavScaffold(user: user);
          },
        );
      },
    );
  }
}
