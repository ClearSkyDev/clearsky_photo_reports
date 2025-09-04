import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Logger? _logger;
Logger logger() => _logger ??= Logger();

void logInfo(String message, [dynamic data]) {
  logger().i(message);
  if (kReleaseMode) FirebaseCrashlytics.instance.log('$message ${data ?? ''}');
}

void logWarn(String message, [dynamic data]) {
  logger().w(message);
  if (kReleaseMode)
    FirebaseCrashlytics.instance.log('WARN: $message ${data ?? ''}');
}

void logError(String message, Object error, [StackTrace? stack]) {
  logger().e(message, error: error, stackTrace: stack);
  if (kReleaseMode) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: message,
      fatal: false,
    );
  }
}
