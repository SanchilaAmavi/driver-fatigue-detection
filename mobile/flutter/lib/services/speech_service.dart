import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechToText _stt   = SpeechToText();
  static bool _initialized         = false;
  static bool get isListening      => _stt.isListening;

  static Future<bool> initialize() async {
    if (_initialized) return true;
    await Permission.microphone.request();
    _initialized = await _stt.initialize(
      onError: (e) => print('STT error: $e'),
    );
    return _initialized;
  }

  static Future<void> startListening({
    required void Function(String text) onResult,
    required void Function() onDone,
  }) async {
    if (!_initialized) await initialize();
    if (_stt.isListening) await stopListening();

    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onDone();
        }
      },
      listenFor:   const Duration(seconds: 10),
      pauseFor:    const Duration(seconds: 2),
      localeId:    'en_US',
      cancelOnError: true,
    );
  }

  static Future<void> stopListening() async {
    await _stt.stop();
  }

  static void dispose() {
    _stt.cancel();
  }
}