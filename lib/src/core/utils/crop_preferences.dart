import 'package:shared_preferences/shared_preferences.dart';

/// Stores whether square cropping should be enforced when capturing photos.
class CropPreferences {
  CropPreferences._();
  static const String _key = 'enforce_square_crop';

  static Future<bool> isEnforced() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  static Future<void> setEnforced(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
