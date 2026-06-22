import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
    } catch (e) {
      print('Firebase init skipped: $e');
      _initialized = false;
    }
  }

  static bool get isAvailable => _initialized;

  static Future<void> logFatigueEvent(Map<String, dynamic> event) async {
    if (!_initialized) return;
    try {
      await FirebaseFirestore.instance
          .collection('fatigue_events')
          .add({...event, 'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Firebase log error: $e');
    }
  }

  static Future<void> logTrip(Map<String, dynamic> trip) async {
    if (!_initialized) return;
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .add({...trip, 'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Firebase trip log error: $e');
    }
  }
}