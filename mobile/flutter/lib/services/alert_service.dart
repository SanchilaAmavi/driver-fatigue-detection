import 'package:flutter/services.dart';

class AlertService {
  static Future<void> triggerAlert() async {
    // Use Flutter's built-in haptic feedback instead of vibration package
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.heavyImpact();
  }

  static Future<void> triggerCriticalAlert() async {
    for (int i = 0; i < 5; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  static Future<void> triggerWarningAlert() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 300));
    await HapticFeedback.mediumImpact();
  }
}