// Generated via `flutterfire configure`. Replace placeholder values with your Firebase project settings.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for the app across different platforms.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_API_KEY',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
    authDomain: 'TODO',
    storageBucket: 'TODO',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_API_KEY',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
    storageBucket: 'TODO',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_API_KEY',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
    iosBundleId: 'TODO',
    storageBucket: 'TODO',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_API_KEY',
    appId: 'TODO',
    messagingSenderId: 'TODO',
    projectId: 'TODO',
    iosBundleId: 'TODO',
    storageBucket: 'TODO',
  );
}
