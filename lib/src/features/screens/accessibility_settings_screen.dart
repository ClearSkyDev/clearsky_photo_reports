import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/models/accessibility_settings.dart';
import '../../core/services/accessibility_service.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  AccessibilitySettings _settings = const AccessibilitySettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AccessibilityService.instance.init();
    _settings = AccessibilityService.instance.settings;
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    await AccessibilityService.instance.saveSettings(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accessibility settings saved')));
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
        title: const Text('Accessibility Settings'),
        backgroundColor: AppTheme.clearSkyTheme.primaryColor,
        foregroundColor: AppTheme.clearSkyTheme.colorScheme.onPrimary,
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Text Size'),
            subtitle: Slider(
              value: _settings.textScale,
              min: 0.8,
              max: 1.5,
              divisions: 7,
              label: _settings.textScale.toStringAsFixed(1),
              onChanged: (v) =>
                  setState(() => _settings = _settings.copyWith(textScale: v)),
            ),
          ),
          SwitchListTile(
            title: const Text('High Contrast'),
            value: _settings.highContrast,
            onChanged: (v) =>
                setState(() => _settings = _settings.copyWith(highContrast: v)),
          ),
          SwitchListTile(
            title: const Text('Screen Reader Mode'),
            value: _settings.screenReader,
            onChanged: (v) =>
                setState(() => _settings = _settings.copyWith(screenReader: v)),
          ),
          SwitchListTile(
            title: const Text('Reduced Motion'),
            value: _settings.reducedMotion,
            onChanged: (v) => setState(
                () => _settings = _settings.copyWith(reducedMotion: v)),
          ),
          SwitchListTile(
            title: const Text('Haptics'),
            value: _settings.haptics,
            onChanged: (v) =>
                setState(() => _settings = _settings.copyWith(haptics: v)),
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
