import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  AudioService({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? FlutterTts();

  final FlutterTts _flutterTts;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(true);

    _initialized = true;
  }

  Future<void> speak(String text, {bool slow = false}) async {
    final cleanedText = text.trim();

    if (cleanedText.isEmpty) {
      return;
    }

    await initialize();
    await stop();

    await _flutterTts.setSpeechRate(slow ? 0.30 : 0.48);

    await _flutterTts.speak(cleanedText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> dispose() async {
    await stop();
  }
}
