import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static Future<bool> isPro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('subscribed') ?? false;
  }
}
