import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration for ClearSky Photo Reports.
///
/// The values below are **dummy credentials** used for development and
/// testing only. They allow the application to run in a mocked offline mode
/// when Firebase initialization fails. Replace these with your real Firebase
/// project settings for production use.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: 'FAKE_WEB_KEY_1234567890',
      authDomain: 'demo-clearsky.firebaseapp.com',
      projectId: 'demo-clearsky',
      storageBucket: 'demo-clearsky.appspot.com',
      messagingSenderId: '123456789012',
      appId: '1:123456789012:web:abcdef1234567890',
      measurementId: 'G-DEMO12345');

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'FAKE_ANDROID_KEY_0987654321',
    appId: '1:123456789012:android:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'demo-clearsky',
    storageBucket: 'demo-clearsky.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'FAKE_IOS_KEY_1234567890',
    appId: '1:123456789012:ios:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'demo-clearsky',
    iosBundleId: 'com.clearsky.photo',
    storageBucket: 'demo-clearsky.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'FAKE_MACOS_KEY_1234567890',
    appId: '1:123456789012:macos:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'demo-clearsky',
    iosBundleId: 'com.clearsky.photo',
    storageBucket: 'demo-clearsky.appspot.com',
  );
}
