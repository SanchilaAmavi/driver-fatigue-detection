import 'package:flutter/material.dart';
import '../services/emergency_contact_service.dart';
import '../widgets/voice_fab.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() =>
      _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final TextEditingController _nameController  = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _saved   = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadEmergencyContact() async {
    final contact = await EmergencyContactService.getContact();
    _nameController.text  = contact['name']  ?? '';
    _phoneController.text = contact['phone'] ?? '';
    setState(() {
      _saved   = _nameController.text.isNotEmpty &&
                 _phoneController.text.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _saveEmergencyContact() async {
    final name  = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and phone number.')),
      );
      return;
    }
    await EmergencyContactService.saveContact(name, phone);
    setState(() => _saved = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Emergency contact saved.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _callEmergencyContact() async {
    final success = await EmergencyContactService.callContact();
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Unable to place a call.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _smsEmergencyContact(String message) async {
    final success = await EmergencyContactService.sendSmsAlert(message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '📱 SMS sent successfully.'
            : '❌ Unable to send SMS. Check contact settings.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // ── Bottom nav ──────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context, int current) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0A0E1A),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.white38,
      currentIndex: current,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        const routes = ['/home', '/camera', '/voice', '/dashboard'];
        if (i != current) Navigator.pushNamed(context, routes[i]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home),            label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.remove_red_eye),  label: 'Monitor'),
        BottomNavigationBarItem(icon: Icon(Icons.mic),             label: 'Assistant'),
        BottomNavigationBarItem(icon: Icon(Icons.dashboard),       label: 'Dashboard'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      floatingActionButton: const VoiceFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(context, 0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Row(
          children: [
            Icon(Icons.sos, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Emergency Contact',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header card ──────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B1D1D), Color(0xFF4A0000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.emergency,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 14),
                        const Text('Emergency Contact',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text(
                          'This person will be notified automatically when severe fatigue is detected.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Status badge ─────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (_saved ? Colors.green : Colors.orange)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: (_saved ? Colors.green : Colors.orange)
                              .withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _saved
                              ? Icons.check_circle
                              : Icons.warning_amber,
                          color: _saved ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _saved
                              ? 'Contact configured'
                              : 'No contact set — configure below',
                          style: TextStyle(
                            color: _saved ? Colors.green : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Section label ────────────────────────
                  const Text('Contact Details',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),

                  // ── Name field ───────────────────────────
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 14),

                  // ── Phone field ──────────────────────────
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),

                  // ── Save button ──────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Save Contact',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      onPressed: _saveEmergencyContact,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Actions section ──────────────────────
                  const Text('Quick Actions',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),

                  // Call button
                  _buildActionTile(
                    icon: Icons.call,
                    color: Colors.green,
                    title: 'Call Emergency Contact',
                    subtitle: _saved
                        ? _phoneController.text
                        : 'Save a contact first',
                    onTap: _saved ? _callEmergencyContact : null,
                  ),
                  const SizedBox(height: 12),

                  // SMS button
                  _buildActionTile(
                    icon: Icons.sms,
                    color: Colors.orange,
                    title: 'Send SMS Alert',
                    subtitle: 'Driver fatigue detected. Please check on them.',
                    onTap: _saved
                        ? () => _smsEmergencyContact(
                            'Driver fatigue detected. Please check on them.')
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Test SMS button
                  _buildActionTile(
                    icon: Icons.send,
                    color: Colors.purple,
                    title: 'Send Test SMS',
                    subtitle: 'Verify your contact receives alerts',
                    onTap: _saved
                        ? () => _smsEmergencyContact(
                            '✅ NexDrive test alert — your emergency contact is set up correctly.')
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // ── Info box ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blueAccent, size: 18),
                            SizedBox(width: 8),
                            Text('How it works',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _infoRow('An SMS is auto-sent after 1 min of repeated alerts'),
                        _infoRow('Includes a timestamped warning message'),
                        _infoRow('Works even when you cannot respond'),
                        _infoRow('Update contact anytime from this screen'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1F2E),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.blue.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: enabled ? color : Colors.white24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle,
              color: Colors.blueAccent, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}