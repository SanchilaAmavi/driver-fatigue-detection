import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechToText _stt = SpeechToText();
  static bool _initialized       = false;
  static bool get isListening    => _stt.isListening;

  static Future<bool> initialize() async {
    if (_initialized) return true;
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('Microphone permission denied');
      return false;
    }
    _initialized = await _stt.initialize(
      onError: (e) => debugPrint('STT error: ${e.errorMsg}'),
      onStatus: (s) => debugPrint('STT status: $s'),
    );
    debugPrint('STT initialized: $_initialized');
    return _initialized;
  }

  static Future<void> startListening({
    required void Function(String text) onResult,
    required void Function() onDone,
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) {
        onDone();
        return;
      }
    }

    if (_stt.isListening) await _stt.stop();

    await _stt.listen(
      onResult: (result) {
        debugPrint('STT partial: ${result.recognizedWords}');
        // Send partial results live so UI updates
        onResult(result.recognizedWords);
        if (result.finalResult) {
          debugPrint('STT final: ${result.recognizedWords}');
          onDone();
        }
      },
      listenFor:     const Duration(seconds: 15),
      pauseFor:      const Duration(seconds: 2),
      localeId:      'en_US',
      cancelOnError: false,
      partialResults: true,
    );
  }

  static Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }

  static void dispose() {
    _stt.cancel();
  }
}