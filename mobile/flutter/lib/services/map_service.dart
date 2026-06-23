import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapService {
  static final List<LatLng> routePoints = [];
  static final List<Marker> alertMarkers = [];
  static int _alertMarkerCount = 0;

  static void addRoutePoint(Position position) {
    routePoints.add(LatLng(position.latitude, position.longitude));
  }

  static void addAlertMarker(
      Position position, String alertLevel, String message) {
    _alertMarkerCount++;
    alertMarkers.add(
      Marker(
        markerId: MarkerId('alert_$_alertMarkerCount'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          alertLevel == 'CRITICAL'
              ? BitmapDescriptor.hueRed
              : alertLevel == 'DANGER'
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueYellow,
        ),
        infoWindow: InfoWindow(
          title: '⚠️ $alertLevel',
          snippet: message,
        ),
      ),
    );
  }

  static void clearSession() {
    routePoints.clear();
    alertMarkers.clear();
    _alertMarkerCount = 0;
  }
}