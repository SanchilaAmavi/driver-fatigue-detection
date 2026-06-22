import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class AlertService {
  static Future<void> triggerAlert() async {
    try {
      HapticFeedback.heavyImpact();
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 800, amplitude: 128);
      }
    } catch (_) {}
  }
}
