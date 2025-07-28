import 'dart:io';
import 'package:clearsky_photo_reports/src/core/utils/logging.dart';

void main() {
  final flutterProject = File('pubspec.yaml').existsSync();
  final reactNativeProject = File('package.json').existsSync();

  if (flutterProject && !reactNativeProject) {
    logger().d('🛑 Detected Flutter project.');
    logger().d('✅ Use this instead: flutter run -d chrome');
  } else if (reactNativeProject) {
    logger().d('✅ Detected React Native project.');
    logger().d('Run this: npx expo start');
  } else {
    logger().d('⚠️ Could not detect project type. No pubspec.yaml or package.json found.');
  }
}
