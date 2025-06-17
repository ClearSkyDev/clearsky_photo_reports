import 'dart:convert';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tts_settings.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  TtsSettings settings = const TtsSettings();

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('tts_settings');
    if (raw != null) {
      settings = TtsSettings.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw)));
    }
    await _apply();
  }

  Future<void> _apply() async {
    await _tts.setLanguage(settings.language);
    await _tts.setSpeechRate(settings.rate);
  }

  Future<void> saveSettings(TtsSettings newSettings) async {
    settings = newSettings;
    await _apply();
    final sp = await SharedPreferences.getInstance();
    await sp.setString('tts_settings', jsonEncode(settings.toMap()));
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
  Future<void> pause() => _tts.pause();
}
