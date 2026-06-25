import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class AlertMarkerData {
  final LatLng position;
  final String level;
  final String message;
  final int id;

  const AlertMarkerData({
    required this.position,
    required this.level,
    required this.message,
    required this.id,
  });
}

class MapService {
  static final List<LatLng>          routePoints   = [];
  static final List<AlertMarkerData> alertMarkers  = [];
  static int _alertMarkerCount = 0;

  static void addRoutePoint(Position position) {
    routePoints.add(LatLng(position.latitude, position.longitude));
  }

  static void addAlertMarker(
      Position position, String alertLevel, String message) {
    _alertMarkerCount++;
    alertMarkers.add(
      AlertMarkerData(
        position: LatLng(position.latitude, position.longitude),
        level:    alertLevel,
        message:  message,
        id:       _alertMarkerCount,
      ),
    );
  }

  static void clearSession() {
    routePoints.clear();
    alertMarkers.clear();
    _alertMarkerCount = 0;
  }
}
