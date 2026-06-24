import 'dart:async';

import 'package:flutter/material.dart';

import '../services/session_stats_service.dart';

/// Drop-in replacement for the hardcoded stats row on the dashboard.
///
/// Shows live:  Trips today | Alerts | Safe score
///
/// Usage — replace your old hardcoded Row with:
///   const DashboardStatsWidget()
class DashboardStatsWidget extends StatefulWidget {
  const DashboardStatsWidget({super.key});

  @override
  State<DashboardStatsWidget> createState() => _DashboardStatsWidgetState();
}

class _DashboardStatsWidgetState extends State<DashboardStatsWidget> {
  late SessionStats _stats;
  StreamSubscription<SessionStats>? _sub;

  @override
  void initState() {
    super.initState();
    _stats = SessionStatsService.current;
    _sub   = SessionStatsService.stream.listen((s) {
      if (mounted) setState(() => _stats = s);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatCard(
          label: 'Trip today',
          value: '${_stats.tripsToday}',
          icon:  Icons.directions_car_rounded,
          color: Colors.blueAccent,
        ),
        _StatCard(
          label: 'Alerts',
          value: '${_stats.alertCount}',
          icon:  Icons.warning_amber_rounded,
          color: _stats.alertCount > 3
              ? Colors.redAccent
              : Colors.orangeAccent,
        ),
        _StatCard(
          label: 'Safe score',
          value: '${_stats.safeScore.toInt()}',
          icon:  Icons.shield_rounded,
          color: _safeColor(_stats.safeScore),
        ),
      ],
    );
  }

  Color _safeColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

// ── Individual stat card ──────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color    color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color:        const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color:      color,
              fontSize:   26,
              fontWeight: FontWeight.w700,
              height:     1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color:    Colors.white54,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}