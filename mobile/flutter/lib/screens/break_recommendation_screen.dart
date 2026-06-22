import 'dart:async';

import 'package:flutter/material.dart';

class BreakRecommendationScreen extends StatefulWidget {
  final String riskLevel;

  const BreakRecommendationScreen({super.key, this.riskLevel = 'HIGH'});

  @override
  State<BreakRecommendationScreen> createState() => _BreakRecommendationScreenState();
}

class _BreakRecommendationScreenState extends State<BreakRecommendationScreen> {
  static const int _recommendedMinutes = 15;
  Timer? _timer;
  int _remainingSeconds = _recommendedMinutes * 60;
  late String _riskLevel;

  @override
  void initState() {
    super.initState();
    _riskLevel = widget.riskLevel;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() {
          _remainingSeconds -= 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    final riskColor = _riskLevel == 'HIGH'
        ? Colors.red
        : _riskLevel == 'MEDIUM'
            ? Colors.orange
            : Colors.green;
    final riskDescription = _riskLevel == 'HIGH'
        ? 'Stop driving immediately and take a full break.'
        : _riskLevel == 'MEDIUM'
            ? 'Exercise caution. Take a short rest soon.'
            : 'Low risk, but stay alert and refreshed.';

    return Scaffold(
      appBar: AppBar(title: const Text('Break Recommendation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recommended rest break', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Fatigue risk level: $_riskLevel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: riskColor)),
            const SizedBox(height: 8),
            Text(riskDescription, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  const Text('Rest countdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Advice', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• Pull over safely at the next available stop.'),
            const Text('• Take a 15-minute rest or nap.'),
            const Text('• Drink water and stay hydrated.'),
            const Text('• Resume driving only when alertness improves.'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _remainingSeconds = _recommendedMinutes * 60;
                });
              },
              child: const Text('Reset Timer'),
            ),
          ],
        ),
      ),
    );
  }
}
