import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const _baseUrl = 'http://127.0.0.1:8000';

  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> recordTrip(Map<String, Object> trip) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/trips/record'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(trip),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
