import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
  storageBucket: "clearsky-photoreports.firebasestorage.app",
  messagingSenderId: "1027653730880",
  appId: "1:1027653730880:web:bb7e290e2a5bb3745dd5a5",
  measurementId: "G-1C6LJYYJF4"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyExampleAndroidKey123',
    appId: '1:1234567890:android:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'clearsky-photo-reports',
    storageBucket: 'clearsky-photo-reports.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyExampleIosKey123456',
    appId: '1:1234567890:ios:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'clearsky-photo-reports',
    iosBundleId: 'com.example.clearskyPhotoReports',
    storageBucket: 'clearsky-photo-reports.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyExampleMacKey123456',
    appId: '1:1234567890:macos:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'clearsky-photo-reports',
    iosBundleId: 'com.example.clearskyPhotoReports',
    storageBucket: 'clearsky-photo-reports.appspot.com',
  );
}
