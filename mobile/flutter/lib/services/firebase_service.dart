import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (_) {
      // Firebase is optional for app launch.
      _initialized = false;
    }
  }

  static Future<void> logFatigueEvent(Map<String, Object> event) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('fatigue_events').add(event);
    } catch (_) {
      // ignore errors during logging
    }
  }
}
