import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/emergency_contact_screen.dart';
import 'screens/break_recommendation_screen.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseService.initialize();
  } catch (_) {
    // Continue without Firebase if initialization fails.
  }
  await NotificationService.initialize();
  runApp(const DriverFatigueApp());
}

class DriverFatigueApp extends StatelessWidget {
  const DriverFatigueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexDrive',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/break') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => BreakRecommendationScreen(
              riskLevel: args?['riskLevel'] as String? ?? 'HIGH',
            ),
          );
        }
        return null;
      },
      routes: {
        '/': (context) => const HomeScreen(),
        '/camera': (context) => const CameraScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/login': (context) => const LoginScreen(),
        '/emergency': (context) => const EmergencyContactScreen(),
      },
    );
  }
}
