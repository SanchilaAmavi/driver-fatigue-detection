import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ── Change this to your FastAPI server IP ──
  // For emulator testing use: 10.0.2.2:8000
  // For real device use: your computer's IP e.g. 192.168.1.100:8000
  static const _baseUrl = 'http://10.0.2.2:8000';

  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> predictImage(
      List<int> imageBytes) async {
    try {
      final uri    = Uri.parse('$_baseUrl/predict');
      final base64 = base64Encode(imageBytes);
      final response = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'image': base64}))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'error': 'Server error ${response.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<bool> recordTrip(Map<String, dynamic> trip) async {
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/trips/record'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(trip))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<dynamic>> getTrips() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/trips'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/stats'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}