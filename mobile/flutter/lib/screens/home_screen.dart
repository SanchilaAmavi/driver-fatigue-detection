import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _statusMessage = 'Checking backend connectivity...';

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final status = await ApiService.healthCheck();
    setState(() {
      _statusMessage = status ? 'Backend reachable.' : 'Backend unreachable.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NexDrive'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NexDrive',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(_statusMessage, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/camera'),
              child: const Text('Start Camera Monitoring'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/dashboard'),
              child: const Text('View Risk Dashboard'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/break'),
              child: const Text('Break Recommendation'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/emergency'),
              child: const Text('Emergency Contact'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Login / Firebase Setup'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Features enabled:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Front-camera face detection'),
            const Text('• Eye closure, yawning, and head-pose monitoring'),
            const Text('• Real-time alert overlay and vibration'),
            const Text('• Firebase event logging for fatigue events'),
            const Text('• Backend trip logging via API'),
          ],
        ),
      ),
    );
  }
}
