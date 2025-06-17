import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;

  Future<bool> init() async {
    _available = await _speech.initialize();
    return _available;
  }

  bool get isListening => _speech.isListening;

  Future<String?> record({required String fieldType, required String reportId}) async {
    if (!_available) {
      _available = await _speech.initialize();
      if (!_available) return null;
    }
    final completer = Completer<String?>();
    String text = '';
    _speech.listen(onResult: (res) {
      text = res.recognizedWords;
      if (res.finalResult) {
        _speech.stop();
        completer.complete(text);
      }
    });
    final transcript = await completer.future;
    if (transcript != null && transcript.isNotEmpty) {
      final cleaned = formatTranscript(transcript);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('speechTranscripts').add({
          'userId': user.uid,
          'reportId': reportId,
          'fieldType': fieldType,
          'text': cleaned,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      return cleaned;
    }
    return transcript;
  }

  void stop() {
    if (_speech.isListening) {
      _speech.stop();
    }
  }

  String formatTranscript(String text) {
    var cleaned = text.trim();
    if (cleaned.isEmpty) return '';
    cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    if (!cleaned.endsWith('.') &&
        !cleaned.endsWith('!') &&
        !cleaned.endsWith('?')) {
      cleaned = '$cleaned.';
    }
    return cleaned;
  }
}
