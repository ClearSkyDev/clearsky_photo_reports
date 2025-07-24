import 'package:flutter/foundation.dart';

/// Tracks whether the app is running in demo mode due to missing
/// configuration like Firebase credentials.
class DemoModeService extends ChangeNotifier {
  DemoModeService._();
  static final DemoModeService instance = DemoModeService._();

  bool _enabled = false;

  bool get isEnabled => _enabled;

  /// Enable demo mode and notify listeners.
  void enable() {
    if (!_enabled) {
      _enabled = true;
      notifyListeners();
    }
  }
}
