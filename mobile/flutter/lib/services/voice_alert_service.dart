import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceAlertService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized     = false;
  static bool _isSpeaking      = false;
  static final Random _rand    = Random();

  static Future<void> initialize() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(()      => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(()    => _isSpeaking = false);
    _tts.setErrorHandler((_)    => _isSpeaking = false);

    _initialized = true;
    debugPrint('VoiceAlertService initialized');
  }

  /// Fatigue alert — cuts off any current speech immediately
  static Future<void> speakAlert({
    required bool eyesAlert,
    required bool yawnAlert,
    required bool headAlert,
    required String level,
  }) async {
    if (!_initialized) await initialize();
    if (_isSpeaking) await _tts.stop();
    final message = _pickAlertMessage(eyesAlert, yawnAlert, headAlert, level);
    debugPrint('Speaking alert: $message');
    await _tts.speak(message);
  }

  /// General TTS for voice chat replies — waits for completion
  static Future<void> speakRaw(String text) async {
    if (!_initialized) await initialize();
    if (_isSpeaking) await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 80));

    final completer = Completer<void>();
    void done() { if (!completer.isCompleted) completer.complete(); }

    _tts.setCompletionHandler(done);
    _tts.setCancelHandler(done);
    _tts.setErrorHandler((_) => done());

    debugPrint('Speaking raw: $text');
    await _tts.speak(text);
    await completer.future.timeout(
      const Duration(seconds: 40),
      onTimeout: done,
    );
  }

  static String _pickAlertMessage(
      bool eyesAlert, bool yawnAlert, bool headAlert, String level) {
    if (eyesAlert && level == 'CRITICAL') {
      return _pick([
        'Wake up! Wake up now! Pull over immediately!',
        'Danger! Your eyes are closed! Stop the vehicle now!',
        'Warning! You are falling asleep! Pull over safely now!',
      ]);
    }
    if (eyesAlert) {
      return _pick([
        'Wake up! Stay alert!',
        'Open your eyes! You are falling asleep!',
        'Eyes on the road! Stay awake!',
      ]);
    }
    if (yawnAlert) {
      return _pick([
        'You seem tired. Please take a break soon.',
        'Signs of fatigue detected. Consider stopping to rest.',
        'Take a break. Find a safe place to stop.',
      ]);
    }
    if (headAlert) {
      return _pick([
        'Stay focused on the road!',
        'Please keep your eyes on the road.',
        'Distraction detected. Please focus ahead.',
      ]);
    }
    return 'Please stay alert and focused.';
  }

  static String _pick(List<String> options) =>
      options[_rand.nextInt(options.length)];

  static Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  static void dispose() {
    _tts.stop();
  }
}