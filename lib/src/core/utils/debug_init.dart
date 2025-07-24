import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global key used by [MaterialApp] to access the navigator.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Navigator observer that logs route changes and keeps track of the stack.
class LoggingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];

  List<String> get stackNames =>
      _stack.map((r) => r.settings.name ?? r.runtimeType.toString()).toList();

  void _logStack() {
    debugPrint("Screen stack: ${stackNames.join(' -> ')}");
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    debugPrint('didPush ${route.settings.name}');
    _logStack();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    debugPrint('didPop ${route.settings.name}');
    _logStack();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    debugPrint('didRemove ${route.settings.name}');
    _logStack();
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = _stack.indexOf(oldRoute!);
    if (index >= 0 && newRoute != null) {
      _stack[index] = newRoute;
    }
    debugPrint('didReplace ${oldRoute.settings.name}');
    _logStack();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

/// Logs useful debug information when the app starts.
Future<void> debugInitCheck({required Map<String, WidgetBuilder> routes}) async {
  if (!kDebugMode) return;

  final deviceInfo = DeviceInfoPlugin();
  final Map<String, dynamic> info = <String, dynamic>{};
  try {
    if (kIsWeb) {
      final data = await deviceInfo.webBrowserInfo;
      info['browser'] = describeEnum(data.browserName);
      info['userAgent'] = data.userAgent;
    } else if (Platform.isAndroid) {
      final data = await deviceInfo.androidInfo;
      info['model'] = data.model;
      info['version'] = data.version.release;
    } else if (Platform.isIOS) {
      final data = await deviceInfo.iosInfo;
      info['model'] = data.utsname.machine;
      info['systemVersion'] = data.systemVersion;
    }
  } catch (e) {
    info['error'] = e.toString();
  }
  debugPrint('Device info: $info');

  final firebaseAvailable = Firebase.apps.isNotEmpty;
  debugPrint('Firebase available: $firebaseAvailable');

  const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  debugPrint('Current environment: $env');

  debugPrint('Registered routes: ${routes.keys.join(', ')}');

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator != null) {
      final observer = navigator.widget.observers
          .whereType<LoggingNavigatorObserver>()
          .firstOrNull;
      if (observer != null) {
        debugPrint("Initial stack: ${observer.stackNames.join(' -> ')}");
      }
    }
  });
}
