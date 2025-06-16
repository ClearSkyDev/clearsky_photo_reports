import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../models/notification_preferences.dart';

/// Handles Firebase Messaging setup and displaying local notifications.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  NotificationPreferences _prefs = const NotificationPreferences();

  bool _initialized = false;

  /// Initialize FCM, request permissions and set up listeners.
  Future<void> init() async {
    if (_initialized) return;
    await _requestPermissions();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _local.initialize(initSettings);

    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    await _loadPrefs();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('notif_prefs');
    if (raw != null) {
      _prefs = NotificationPreferences.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw)));
    }
  }

  /// Persist [prefs] for future sessions.
  Future<void> savePrefs(NotificationPreferences prefs) async {
    _prefs = prefs;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('notif_prefs', jsonEncode(prefs.toMap()));
  }

  static Future<void> _backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    NotificationService.instance._showNotification(message);
  }

  void _handleMessage(RemoteMessage message) {
    _showNotification(message);
  }

  void _showNotification(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type == 'message' && !_prefs.newMessage) return;
    if (type == 'report' && !_prefs.reportFinalized) return;
    if (type == 'invoice' && !_prefs.invoiceUpdate) return;
    if (type == 'summary' && !_prefs.aiSummary) return;

    final notification = message.notification;
    final title = notification?.title ?? 'ClearSky';
    final body = notification?.body ?? message.data['body'] ?? '';

    _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'clearsky',
          'Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
