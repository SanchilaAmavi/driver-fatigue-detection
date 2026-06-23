import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceAlertService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static bool _isSpeaking = false;
  static final Random _rand = Random();

  static Future<void> initialize() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);   // slightly slower = clearer when sleepy
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);

    // ✅ Make sure TTS plays through the speaker at full volume,
    // ignoring silent/vibrate mode where supported (Android only)
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) => _isSpeaking = false);

    _initialized = true;
  }

  /// Call this from the same place you currently call AlertService.triggerAlert()
  static Future<void> speakAlert({
    required bool eyesAlert,
    required bool yawnAlert,
    required bool headAlert,
    required String level,
  }) async {
    if (!_initialized) await initialize();

    // Don't let messages stack up — cut off the previous one
    if (_isSpeaking) {
      await _tts.stop();
    }

    final message = _pickMessage(eyesAlert, yawnAlert, headAlert, level);
    await _tts.speak(message);
  }

  static String _pickMessage(
      bool eyesAlert, bool yawnAlert, bool headAlert, String level) {
    if (eyesAlert && level == 'CRITICAL') {
      return _randomFrom([
        'Wake up! Wake up now! Pull over immediately!',
        'Danger! Your eyes are closed! Stop the vehicle now!',
        'Warning! You are falling asleep! Pull over safely now!',
      ]);
    }
    if (eyesAlert) {
      return _randomFrom([
        'Wake up! Stay alert!',
        'Open your eyes! You are falling asleep!',
      ]);
    }
    if (yawnAlert) {
      return _randomFrom([
        'You seem tired. Please take a break.',
        'Signs of fatigue detected. Consider stopping to rest.',
        'Take a break soon. Find a safe place to stop.',
      ]);
    }
    if (headAlert) {
      return _randomFrom([
        'Stay focused on the road!',
        'Please keep your eyes on the road.',
        'Distraction detected. Please focus ahead.',
      ]);
    }
    return 'Please stay alert and focused.';
  }

  static String _randomFrom(List<String> options) =>
      options[_rand.nextInt(options.length)];

  static Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  static void dispose() {
    _tts.stop();
  }
}