import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<void> initialize() async {
    await _handlePermission();
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      await _handlePermission();
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      throw Exception('Location permission is required for driver location tracking.');
    }
  }

  static String formatPosition(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }
}
