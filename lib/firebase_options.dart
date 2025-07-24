import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration for ClearSky Photo Reports.
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
      apiKey: "AIzaSyDncntPjpq-awo_TrQhCpIGrd8Bhw4zeLs",
      authDomain: "clearsky-photoreports.firebaseapp.com",
      projectId: "clearsky-photoreports",
      storageBucket: "clearsky-photoreports.appspot.com",
      messagingSenderId: "1027653730880",
      appId: "1:1027653730880:web:bb7e290e2a5bb3745dd5a5",
      measurementId: "G-1C6LJYYJF4");

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9B8c7DEfGhIjkLmNoP1QrStU2VwXyZ',
    appId: '1:1027653730880:android:abc123def456ghi789jkl',
    messagingSenderId: '1027653730880',
    projectId: 'clearsky-photo-reports',
    storageBucket: 'clearsky-photo-reports.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA1B2C3D4E5F6G7H8I9J0abcdefgHIJ',
    appId: '1:1027653730880:ios:123abc456def789ghi012',
    messagingSenderId: '1027653730880',
    projectId: 'clearsky-photo-reports',
    iosBundleId: 'com.clearsky.photo',
    storageBucket: 'clearsky-photo-reports.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAAABBBCCC111222333444ddddEEE',
    appId: '1:1027653730880:macos:abcdef1234567890abcd',
    messagingSenderId: '1027653730880',
    projectId: 'clearsky-photo-reports',
    iosBundleId: 'com.clearsky.photo',
    storageBucket: 'clearsky-photo-reports.appspot.com',
  );
}
