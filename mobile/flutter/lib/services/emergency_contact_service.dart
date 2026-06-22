import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactService {
  static const _nameKey = 'emergency_name';
  static const _phoneKey = 'emergency_phone';

  static Future<Map<String, String>> getContact() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_nameKey) ?? '',
      'phone': prefs.getString(_phoneKey) ?? '',
    };
  }

  static Future<bool> hasContact() async {
    final contact = await getContact();
    return contact['name']!.isNotEmpty && contact['phone']!.isNotEmpty;
  }

  static Future<void> saveContact(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_phoneKey, phone);
  }

  static Future<bool> callContact() async {
    final contact = await getContact();
    final phone = contact['phone'];
    if (phone == null || phone.isEmpty) return false;
    final uri = Uri.parse('tel:$phone');
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> sendSmsAlert(String message) async {
    final contact = await getContact();
    final phone = contact['phone'];
    if (phone == null || phone.isEmpty) return false;
    final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
