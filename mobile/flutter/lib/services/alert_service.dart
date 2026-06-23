import 'package:flutter/services.dart';

class AlertService {
  static Future<void> triggerAlert() async {
    // Haptic feedback (vibration)
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.heavyImpact();

    // System alert sound
    await SystemSound.play(SystemSoundType.alert);
  }
}