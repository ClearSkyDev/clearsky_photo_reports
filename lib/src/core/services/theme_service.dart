import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_theme.dart';
import '../models/app_theme_option.dart';

class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _key = 'app_theme_option';

  AppThemeOption _option = AppThemeOption.light;
  bool _initialized = false;

  AppThemeOption get option => _option;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (name != null) {
      for (final o in AppThemeOption.values) {
        if (o.name == name) {
          _option = o;
          break;
        }
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setOption(AppThemeOption option) async {
    _option = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, option.name);
    notifyListeners();
  }

  ThemeData get lightTheme {
    if (_option == AppThemeOption.highContrast) {
      return AppTheme.highContrastTheme;
    }
    return AppTheme.lightTheme;
  }

  ThemeMode get themeMode {
    switch (_option) {
      case AppThemeOption.dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }
}
