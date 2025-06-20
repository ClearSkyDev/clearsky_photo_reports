import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/accessibility_settings.dart';

class AccessibilityService extends ChangeNotifier {
  AccessibilityService._();
  static final AccessibilityService instance = AccessibilityService._();

  AccessibilitySettings settings = const AccessibilitySettings();

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('accessibility_settings');
    if (raw != null) {
      settings = AccessibilitySettings.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw)));
    }
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    settings = settings.copyWith(
      highContrast: settings.highContrast || features.highContrast,
      reducedMotion: settings.reducedMotion || features.disableAnimations,
      screenReader: settings.screenReader || features.accessibleNavigation,
    );
    notifyListeners();
  }

  Future<void> saveSettings(AccessibilitySettings newSettings) async {
    settings = newSettings;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('accessibility_settings', jsonEncode(settings.toMap()));
    notifyListeners();
  }
}
