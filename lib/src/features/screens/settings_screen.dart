import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../core/services/inspector_role_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  InspectorRole _selectedRole = InspectorRole.adjuster;
  bool _highContrast = false;
  bool _isSubscribed = false; // Replace with real logic later

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
      context,
      targets: targets,
      colorShadow: Colors.black,
      textSkip: 'SKIP',
      paddingFocus: 8,
      onFinish: _completeTutorial,
      onSkip: _completeTutorial,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Subscription", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            key: _subscriptionKey,
            title: Text(_isSubscribed ? "Pro Plan (Active)" : "Free Plan"),
            subtitle: Text(_isSubscribed
                ? "You have full access to all features."
                : "Upgrade to unlock full exports, annotations, and report automation."),
            trailing: !_isSubscribed
                ? ElevatedButton(
                    onPressed: () {
                      // Trigger upgrade dialog or flow
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Upgrade"),
                          content: const Text("Upgrade to Pro in the next version!"),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
                        ),
                      );
                    },
                    child: const Text("Upgrade"),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          const Text("Inspector Role", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

          const Text("Accessibility", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            key: _accessibilityKey,
            title: const Text("High Contrast Mode"),
            value: _highContrast,
            onChanged: (val) => setState(() => _highContrast = val),
          ),
          const SizedBox(height: 32),

          const Divider(),
          const Text("Other", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ListTile(
            key: _versionKey,
            title: const Text("App Version"),
            subtitle: const Text("v1.0.0"),
          ),
        ],
      ),
    );
  }
}
