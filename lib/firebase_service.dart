import 'package:firebase_core/firebase_core.dart';
import 'src/core/services/demo_mode_service.dart';
import 'src/core/utils/logging.dart';

/// Initializes Firebase, enabling [DemoModeService] on failure.
Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp();
    logger().d('✅ Firebase initialized successfully.');
  } catch (e) {
    logger().d('❌ Firebase init failed: $e');
    DemoModeService.instance.enable();
  }
}
