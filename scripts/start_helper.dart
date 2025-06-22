import 'dart:io';

void main() {
  final flutterProject = File('pubspec.yaml').existsSync();
  final reactNativeProject = File('package.json').existsSync();

  if (flutterProject && !reactNativeProject) {
    print('🛑 Detected Flutter project.');
    print('✅ Use this instead: flutter run -d chrome');
  } else if (reactNativeProject) {
    print('✅ Detected React Native project.');
    print('Run this: npx expo start');
  } else {
    print('⚠️ Could not detect project type. No pubspec.yaml or package.json found.');
  }
}
