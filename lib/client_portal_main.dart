import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'src/core/firebase_options.dart';
import 'src/features/client_portal/client_login_screen.dart';
import 'src/features/client_portal/client_dashboard_screen.dart';
import 'src/core/services/auth_service.dart';
import 'src/app/app_theme.dart';
import 'src/core/services/theme_service.dart';
import 'screens/config_error_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey.startsWith('REPLACE_WITH')) {
      throw Exception(
          'Firebase API key not configured. Update lib/src/core/firebase_options.dart');
    }
    await Firebase.initializeApp(options: options);
  } catch (e) {
    runApp(
      MaterialApp(
        home: ConfigErrorScreen(error: e.toString()),
        debugShowCheckedModeBanner: false,
      ),
    );
    return;
  }
  await ThemeService.instance.init();
  runApp(const ClientPortalApp());
}

class ClientPortalApp extends StatelessWidget {
  const ClientPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'ClearSky Client Portal',
          theme: ThemeService.instance.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          home: const _AuthGate(),
        );
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) return const ClientLoginScreen();
        return const ClientDashboardScreen();
      },
    );
  }
}
