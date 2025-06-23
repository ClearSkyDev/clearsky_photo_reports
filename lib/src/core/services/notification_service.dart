import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  NotificationPreferences _prefs = NotificationPreferences();

  bool _initialized = false;

  /// Initialize FCM, request permissions and set up listeners.
  Future<void> init() async {
    debugPrint('[NotificationService] init');
    if (_initialized) return;
    await _requestPermissions();

    final androidSettings =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(android: androidSettings);
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

  @pragma('vm:entry-point')
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      await NotificationService.instance._loadPrefs();
      NotificationService.instance._showNotification(message);
    } catch (_) {
      // Ignore initialization errors in background isolate
    }
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('[NotificationService] message received');
    _showNotification(message);
  }

  void _showNotification(RemoteMessage message) {
    debugPrint('[NotificationService] showNotification');
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
      NotificationDetails(
        android: AndroidNotificationDetails(
          'clearsky',
          'Alerts',
          channelDescription: 'ClearSky notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
