import 'package:flutter/foundation.dart';

/// Delays network calls in debug mode to simulate slow connections.
Future<void> devDelay([Duration duration = const Duration(seconds: 1)]) async {
  if (kDebugMode) {
    await Future.delayed(duration);
  }
}
