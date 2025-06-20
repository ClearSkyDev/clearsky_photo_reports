import 'dart:convert';
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
      settings =
          TtsSettings.fromMap(Map<String, dynamic>.from(jsonDecode(raw)));
    }
    await _apply();
  }

  Future<void> _apply() async {
    await _tts.setLanguage(settings.language);
    await _tts.setSpeechRate(settings.rate);
    if (settings.voice.isNotEmpty) {
      await _tts
          .setVoice({'name': settings.voice, 'locale': settings.language});
    }
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

  Future<File> exportSummary(String text, String intro, String outro) async {
    final full = [intro, text, outro].join(' ');
    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    dir ??= await getApplicationDocumentsDirectory();
    final path = p.join(
        dir.path, 'summary_${DateTime.now().millisecondsSinceEpoch}.mp3');
    await _tts.synthesizeToFile(full, path);
    return File(path);
  }

  Future<File> synthesizeClip(String text, {String? name}) async {
    Directory dir = await getTemporaryDirectory();
    final fileName = name ?? 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final path = p.join(dir.path, fileName);
    await _tts.synthesizeToFile(text, path);
    return File(path);
  }

  Future<void> stop() => _tts.stop();
  Future<void> pause() => _tts.pause();
}
