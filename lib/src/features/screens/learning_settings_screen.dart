import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/app_theme.dart';

import '../../core/utils/learning_preferences.dart';
import '../../core/services/ai_feedback_service.dart';
import 'edit_history_screen.dart';

class LearningSettingsScreen extends StatefulWidget {
  const LearningSettingsScreen({super.key});

  @override
  State<LearningSettingsScreen> createState() => _LearningSettingsScreenState();
}

class _LearningSettingsScreenState extends State<LearningSettingsScreen> {
  bool _enabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _enabled = await LearningPreferences.isLearningEnabled();
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    await LearningPreferences.setLearningEnabled(_enabled);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Preferences saved')));
    }
  }

  Future<void> _resetHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await AiFeedbackService.instance.clearHistory(uid);
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('History cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: AppTheme.clearSkyTheme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.clearSkyTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI Learning'),
        backgroundColor: AppTheme.clearSkyTheme.primaryColor,
        foregroundColor: AppTheme.clearSkyTheme.colorScheme.onPrimary,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Allow AI to learn from my edits'),
            value: _enabled,
            onChanged: (val) => setState(() => _enabled = val),
          ),
          ListTile(
            title: const Text('View Edit History'),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EditHistoryScreen())),
          ),
          ListTile(
            title: const Text('Reset History'),
            onTap: _resetHistory,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          )
        ],
      ),
    );
  }
}
