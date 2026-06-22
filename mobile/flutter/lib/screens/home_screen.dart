import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _backendOk   = false;
  bool _checking    = true;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkBackend();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _checkBackend() async {
    setState(() => _checking = true);
    final ok = await ApiService.healthCheck();
    setState(() { _backendOk = ok; _checking = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NexDrive',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2)),
                      Text('Driver Safety Platform',
                          style: TextStyle(
                              fontSize: 14, color: Colors.blue.shade300)),
                    ],
                  ),
                  // Status indicator
                  GestureDetector(
                    onTap: _checkBackend,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_checking
                                  ? Colors.orange
                                  : _backendOk
                                      ? Colors.green
                                      : Colors.red)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _checking
                                ? Colors.orange
                                : _backendOk
                                    ? Colors.green
                                    : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _checking
                                    ? Colors.orange
                                    : _backendOk
                                        ? Colors.green
                                        : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _checking
                                  ? 'Checking'
                                  : _backendOk
                                      ? 'Online'
                                      : 'Offline',
                              style: TextStyle(
                                color: _checking
                                    ? Colors.orange
                                    : _backendOk
                                        ? Colors.green
                                        : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ── Main Action Card ──
              _buildMainCard(context),
              const SizedBox(height: 20),

              // ── Stats Row ──
              _buildStatsRow(),
              const SizedBox(height: 20),

              // ── Feature Grid ──
              const Text('Features',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              _buildFeatureGrid(context),
              const SizedBox(height: 20),

              // ── Safety Tips ──
              _buildSafetyTips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/camera'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.remove_red_eye,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Monitoring',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text('Real-time fatigue detection',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                _FeatureTag(icon: Icons.visibility, label: 'Eye Tracking'),
                SizedBox(width: 8),
                _FeatureTag(icon: Icons.face, label: 'Yawn Detection'),
                SizedBox(width: 8),
                _FeatureTag(icon: Icons.warning, label: 'Alerts'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, color: Color(0xFF1565C0)),
                  SizedBox(width: 6),
                  Text('Tap to Start',
                      style: TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(title: 'Trips Today', value: '3', icon: Icons.directions_car),
        const SizedBox(width: 12),
        _StatCard(title: 'Alerts', value: '2', icon: Icons.warning_amber),
        const SizedBox(width: 12),
        _StatCard(title: 'Safe Score', value: '87%', icon: Icons.shield),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      _Feature('Dashboard',    Icons.dashboard,         '/dashboard', const Color(0xFF1A237E)),
      _Feature('Trip History', Icons.history,            '/dashboard', const Color(0xFF1B5E20)),
      _Feature('Emergency',    Icons.sos,                '/emergency', const Color(0xFFB71C1C)),
      _Feature('Break Tips',   Icons.free_breakfast,     '/break',     const Color(0xFFE65100)),
      _Feature('Fleet Mgmt',   Icons.people,             '/login',     const Color(0xFF4A148C)),
      _Feature('Settings',     Icons.settings,           '/login',     const Color(0xFF006064)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) {
        final f = features[i];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, f.route),
          child: Container(
            decoration: BoxDecoration(
              color: f.color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: f.color.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(f.icon, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(f.label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSafetyTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text('Safety Tips',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('Take a break every 2 hours of driving'),
          _buildTip('Avoid driving between 2 AM – 6 AM'),
          _buildTip('Stay hydrated during long trips'),
          _buildTip('If yawning repeatedly — stop immediately'),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 14),
          const SizedBox(width: 8),
          Expanded(
              child: Text(tip,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }
}

// ── Helper widgets ──────────────────────────────────────────
class _FeatureTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard(
      {required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  const _Feature(this.label, this.icon, this.route, this.color);
}