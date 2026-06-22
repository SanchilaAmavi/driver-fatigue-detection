import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  static Future<void> showAlertNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'fatigue_alerts',
      'Fatigue Alerts',
      channelDescription: 'Alerts for driver fatigue events',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails();
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}
