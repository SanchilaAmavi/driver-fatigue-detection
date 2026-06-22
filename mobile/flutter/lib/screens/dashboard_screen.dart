import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Risk Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fatigue Summary', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const _RiskLevelCard(riskLevel: 'HIGH'),
            const SizedBox(height: 16),
            const Text('Latest trip risk summary and recommended actions.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/break', arguments: {'riskLevel': 'HIGH'}),
              child: const Text('Open Break Recommendation'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskLevelCard extends StatelessWidget {
  final String riskLevel;

  const _RiskLevelCard({required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    final color = riskLevel == 'HIGH' ? Colors.red : riskLevel == 'MEDIUM' ? Colors.orange : Colors.green;
    final message = riskLevel == 'HIGH'
        ? 'Take a rest break immediately. High fatigue risk detected.'
        : riskLevel == 'MEDIUM'
            ? 'Proceed with caution. Monitor yourself closely.'
            : 'Low risk. Maintain alertness and take breaks as needed.';

    return Card(
      color: color.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current risk: $riskLevel', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
