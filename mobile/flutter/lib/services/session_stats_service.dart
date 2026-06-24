import 'dart:async';
import 'package:flutter/foundation.dart';

/// Tracks real-time driving session stats:
///   • alert count  (incremented whenever a fatigue alert fires)
///   • safe score   (rolling average computed from fatigue scores)
///   • session start time
///
/// Usage:
///   // When a fatigue alert fires:
///   SessionStatsService.recordAlert(fatigueScore: 82.0);
///
///   // When fatigue score updates (even without alert):
///   SessionStatsService.updateScore(65.0);
///
///   // Listen to changes:
///   SessionStatsService.stream.listen((stats) => setState(() => ...));
///
///   // Read current snapshot anywhere:
///   final s = SessionStatsService.current;
///   s.alertCount, s.safeScore, s.tripsToday
class SessionStats {
  final int    alertCount;
  final double safeScore;    // 0–100, higher = safer
  final int    tripsToday;
  final DateTime sessionStart;

  const SessionStats({
    required this.alertCount,
    required this.safeScore,
    required this.tripsToday,
    required this.sessionStart,
  });
}

class SessionStatsService {
  SessionStatsService._();

  // ── Internal state ────────────────────────────────────────
  static int      _alertCount    = 0;
  static int      _tripsToday    = 1;       // current trip counts as 1
  static DateTime _sessionStart  = DateTime.now();

  // Rolling window of recent fatigue scores for safe-score calc
  static final List<double> _scoreWindow = [];
  static const int          _windowSize  = 20;

  // ── Stream ────────────────────────────────────────────────
  static final StreamController<SessionStats> _ctrl =
      StreamController<SessionStats>.broadcast();

  static Stream<SessionStats> get stream => _ctrl.stream;

  static SessionStats get current => SessionStats(
        alertCount:   _alertCount,
        safeScore:    _safeScore(),
        tripsToday:   _tripsToday,
        sessionStart: _sessionStart,
      );

  // ── Public API ────────────────────────────────────────────

  /// Call this every time a fatigue alert fires.
  static void recordAlert({double fatigueScore = 80.0}) {
    _alertCount++;
    updateScore(fatigueScore);
    debugPrint('[SessionStats] alert #$_alertCount  score=$fatigueScore');
  }

  /// Call this whenever the fatigue score updates (polling or model output).
  static void updateScore(double score) {
    _scoreWindow.add(score.clamp(0, 100));
    if (_scoreWindow.length > _windowSize) _scoreWindow.removeAt(0);
    _emit();
  }

  /// Call when the driver starts a new trip (e.g. monitoring resumes).
  static void startNewTrip() {
    _tripsToday++;
    _emit();
  }

  /// Resets counters at the start of a new monitoring session.
  static void resetSession() {
    _alertCount   = 0;
    _scoreWindow.clear();
    _sessionStart = DateTime.now();
    _emit();
  }

  // ── Helpers ───────────────────────────────────────────────

  /// Safe score = inverse of average fatigue (100 - avg_fatigue),
  /// floored at 0, rounded to nearest int.
  static double _safeScore() {
    if (_scoreWindow.isEmpty) return 100.0;
    final avg = _scoreWindow.reduce((a, b) => a + b) / _scoreWindow.length;
    return (100 - avg).clamp(0, 100).roundToDouble();
  }

  static void _emit() {
    if (!_ctrl.isClosed) _ctrl.add(current);
  }

  static void dispose() {
    _ctrl.close();
  }
}