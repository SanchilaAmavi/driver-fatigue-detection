import 'package:flutter/material.dart';
import '../services/emergency_contact_service.dart';

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key});

  @override
  State<EmergencyContactScreen> createState() => _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  Future<void> _loadEmergencyContact() async {
    final contact = await EmergencyContactService.getContact();
    _nameController.text = contact['name'] ?? '';
    _phoneController.text = contact['phone'] ?? '';
    setState(() {
      _saved = _nameController.text.isNotEmpty && _phoneController.text.isNotEmpty;
    });
  }

  Future<void> _saveEmergencyContact() async {
    await EmergencyContactService.saveContact(_nameController.text, _phoneController.text);
    setState(() {
      _saved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency contact saved.')));
  }

  Future<void> _callEmergencyContact() async {
    final success = await EmergencyContactService.callContact();
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to place a call.')));
    }
  }

  Future<void> _smsEmergencyContact(String message) async {
    final success = await EmergencyContactService.sendSmsAlert(message);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to send SMS. Check contact settings.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contact')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configure emergency contact', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveEmergencyContact,
              child: const Text('Save Contact'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saved ? _callEmergencyContact : null,
              child: const Text('Call Emergency Contact'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saved ? () => _smsEmergencyContact('Driver fatigue detected. Please check on them.') : null,
              child: const Text('Send SMS Alert'),
            ),
          ],
        ),
      ),
    );
  }
}
