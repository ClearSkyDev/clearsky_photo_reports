import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/core/firebase_options.dart';
import 'src/core/services/offline_sync_service.dart';
import 'src/core/services/notification_service.dart';

import 'src/app/clear_sky_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await OfflineSyncService.instance.init();
  await NotificationService.instance.init();

  runApp(const ClearSkyApp());
}

