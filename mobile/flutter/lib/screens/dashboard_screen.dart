import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _trips        = [];
  bool _loading               = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final stats = await ApiService.getStats();
    final trips = await ApiService.getTrips();
    setState(() {
      _stats   = stats;
      _trips   = trips;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('Safety Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats Cards ──
                    _buildStatsRow(),
                    const SizedBox(height: 20),

                    // ── Safety Score Chart ──
                    _buildSectionTitle('Safety Score Trend'),
                    const SizedBox(height: 12),
                    _buildLineChart(),
                    const SizedBox(height: 20),

                    // ── Alert Distribution ──
                    _buildSectionTitle('Alert Distribution'),
                    const SizedBox(height: 12),
                    _buildAlertChart(),
                    const SizedBox(height: 20),

                    // ── Current Risk ──
                    _buildSectionTitle('Current Risk Level'),
                    const SizedBox(height: 12),
                    _buildRiskCard(),
                    const SizedBox(height: 20),

                    // ── Recent Trips ──
                    _buildSectionTitle('Recent Trips'),
                    const SizedBox(height: 12),
                    _buildTripsList(),
                    const SizedBox(height: 20),

                    // ── Break Button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.free_breakfast,
                            color: Colors.white),
                        label: const Text('Get Break Recommendation',
                            style: TextStyle(
                                color: Colors.white, fontSize: 16)),
                        onPressed: () => Navigator.pushNamed(
                            context, '/break',
                            arguments: {'riskLevel': 'HIGH'}),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold));
  }

  Widget _buildStatsRow() {
    final totalTrips  = _stats['total_trips']  ?? 0;
    final avgScore    = _stats['avg_score']    ?? 0.0;
    final totalAlerts = _stats['total_alerts'] ?? 0;
    final bestScore   = _stats['best_score']   ?? 0.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard('Total Trips',    '$totalTrips',             Icons.directions_car,  Colors.blue),
        _StatCard('Avg Safety',     '${avgScore.toStringAsFixed(1)}%', Icons.shield,  Colors.green),
        _StatCard('Total Alerts',   '$totalAlerts',            Icons.warning_amber,   Colors.orange),
        _StatCard('Best Score',     '${bestScore.toStringAsFixed(1)}%', Icons.star,   Colors.purple),
      ],
    );
  }

  Widget _buildLineChart() {
    final scores = _trips.isEmpty
        ? [85.0, 90.0, 78.0, 92.0, 88.0, 95.0, 82.0]
        : _trips
            .take(7)
            .map<double>((t) =>
                (t['safe_score'] as num?)?.toDouble() ?? 80.0)
            .toList();

    final spots = scores
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.white10, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (val, _) => Text(
                  '${val.toInt()}%',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) => Text(
                  'T${val.toInt() + 1}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 10),
                ),
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertChart() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barGroups: [
            _barGroup(0, 3, Colors.red,    'Eye'),
            _barGroup(1, 5, Colors.orange, 'Yawn'),
            _barGroup(2, 2, Colors.yellow, 'Head'),
            _barGroup(3, 1, Colors.green,  'OK'),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  const labels = ['Eye', 'Yawn', 'Head', 'OK'];
                  return Text(
                    labels[val.toInt()],
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 25,
                getTitlesWidget: (val, _) => Text(
                  '${val.toInt()}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 10),
                ),
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData:   FlGridData(show: false),
        ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color, String label) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 20,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildRiskCard() {
    final avgScore = (_stats['avg_score'] as num?)?.toDouble() ?? 80.0;
    String level;
    Color color;
    String msg;
    IconData icon;

    if (avgScore >= 85) {
      level = 'LOW RISK';
      color = Colors.green;
      msg   = 'Excellent driving safety. Keep it up!';
      icon  = Icons.check_circle;
    } else if (avgScore >= 70) {
      level = 'MEDIUM RISK';
      color = Colors.orange;
      msg   = 'Proceed with caution. Monitor yourself.';
      icon  = Icons.warning_amber;
    } else {
      level = 'HIGH RISK';
      color = Colors.red;
      msg   = 'Take a break immediately!';
      icon  = Icons.dangerous;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level,
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(msg,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    if (_trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No trips recorded yet.\nStart monitoring to record trips.',
              style: TextStyle(color: Colors.white54),
              textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      children: _trips
          .take(5)
          .map((trip) => _TripTile(trip: trip))
          .toList(),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  final dynamic trip;
  const _TripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final score  = (trip['safe_score'] as num?)?.toDouble() ?? 0.0;
    final alerts = trip['alerts'] ?? 0;
    final time   = trip['timestamp'] ?? '';
    final color  = score >= 85
        ? Colors.green
        : score >= 70
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('${score.toInt()}%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trip ${trip['id']?.toString().substring(0, 8) ?? ''}...',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text('$alerts alerts  •  $time',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Icon(
            score >= 85 ? Icons.check_circle : Icons.warning,
            color: color,
          ),
        ],
      ),
    );
  }
}