import 'package:flutter/material.dart';

import '../../core/models/app_theme_option.dart';
import '../../core/services/theme_service.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  AppThemeOption _option = ThemeService.instance.option;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ThemeService.instance.init();
    setState(() {
      _option = ThemeService.instance.option;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await ThemeService.instance.setOption(_option);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Theme updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('App Theme')),
      body: ListView(
        children: [
          RadioListTile<AppThemeOption>(
            title: const Text('Light'),
            value: AppThemeOption.light,
            groupValue: _option,
            onChanged: (v) => setState(() => _option = v!),
          ),
          RadioListTile<AppThemeOption>(
            title: const Text('Dark'),
            value: AppThemeOption.dark,
            groupValue: _option,
            onChanged: (v) => setState(() => _option = v!),
          ),
          RadioListTile<AppThemeOption>(
            title: const Text('High Contrast'),
            value: AppThemeOption.highContrast,
            groupValue: _option,
            onChanged: (v) => setState(() => _option = v!),
          ),
          RadioListTile<AppThemeOption>(
            title: const Text('Clear Sky'),
            value: AppThemeOption.clearSky,
            groupValue: _option,
            onChanged: (v) => setState(() => _option = v!),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
