import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_theme.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../core/services/inspector_role_service.dart';
import 'profile_screen.dart';
import 'report_settings_screen.dart';
import 'theme_settings_screen.dart';
import 'accessibility_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'learning_settings_screen.dart';
import 'changelog_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  InspectorRole _selectedRole = InspectorRole.adjuster;
  bool _highContrast = false;
  final bool _isSubscribed = false; // Replace with real logic later

  final GlobalKey _subscriptionKey = GlobalKey();
  final GlobalKey _roleKey = GlobalKey();
  final GlobalKey _accessibilityKey = GlobalKey();
  final GlobalKey _versionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    InspectorRoleService.loadRole().then((role) {
      if (mounted) setState(() => _selectedRole = role);
    });
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('settings_tutorial_shown') ?? false;
    if (!shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorial());
    }
  }

  void _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_tutorial_shown', true);
  }

  void _showTutorial() {
    final targets = [
      TargetFocus(
        identify: 'subscription',
        keyTarget: _subscriptionKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Manage your subscription and upgrade if needed.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'role',
        keyTarget: _roleKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Select your primary inspector role here.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'accessibility',
        keyTarget: _accessibilityKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              'Toggle high contrast for better visibility.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'version',
        keyTarget: _versionKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Text(
              'Find your app version and other information.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: 'SKIP',
      paddingFocus: 8,
      onFinish: _completeTutorial,
      onSkip: () {
        _completeTutorial();
        return true;
      },
    ).show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clearSkyTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.clearSkyTheme.primaryColor,
        foregroundColor: AppTheme.clearSkyTheme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title: const Text('Profile'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.black),
            title: const Text('Report Settings'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens, color: Colors.black),
            title: const Text('App Theme'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility, color: Colors.black),
            title: const Text('Accessibility'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccessibilitySettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.black),
            title: const Text('Notifications'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.psychology, color: Colors.black),
            title: const Text('AI Learning'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LearningSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.update, color: Colors.black),
            title: const Text("What's New"),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangelogScreen()),
            ),
          ),
          const Divider(),
          const Text('Subscription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            key: _subscriptionKey,
            title: Text(_isSubscribed ? 'Pro Plan (Active)' : 'Free Plan'),
            subtitle: Text(
              _isSubscribed
                  ? 'You have full access to all features.'
                  : 'Upgrade to unlock full exports, annotations, and report automation.',
            ),
            trailing: !_isSubscribed
                ? ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Upgrade'),
                          content: const Text('Upgrade to Pro in the next version!'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Upgrade',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          const Text('Inspector Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          for (final role in InspectorRole.values)
            RadioListTile<InspectorRole>(
              key: role == InspectorRole.adjuster ? _roleKey : null,
              title: Text(role.name),
              value: role,
              groupValue: _selectedRole,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedRole = val);
                  InspectorRoleService.saveRole(val);
                }
              },
            ),
          const SizedBox(height: 16),
          const Text('Accessibility Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            key: _accessibilityKey,
            title: const Text('High Contrast Mode'),
            value: _highContrast,
            onChanged: (val) => setState(() => _highContrast = val),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const Text('Other', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            key: _versionKey,
            title: const Text('App Version'),
            subtitle: const Text('v1.0.0'),
          ),
        ],
      ),
    );
  }
}
