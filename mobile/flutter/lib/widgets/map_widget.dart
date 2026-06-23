import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/map_service.dart';

class MapWidget extends StatefulWidget {
  final VoidCallback? onExpand;

  const MapWidget({super.key, this.onExpand});

  @override
  State<MapWidget> createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _startLocationTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);
      MapService.addRoutePoint(position);
      if (mounted) {
        setState(() => _currentPosition = latLng);
        if (_mapReady) {
          _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
        }
      }
    });
  }

  // Called from CameraScreen when a fatigue alert fires
  void addAlertMarker(Position position, String level, String message) {
    MapService.addAlertMarker(position, level, message);
    if (mounted) setState(() {});
  }

  // Refresh markers after external update
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // ── Map or loading ──────────────────────────────
            _currentPosition == null
                ? _buildLoadingMap()
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 16,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _mapReady = true;
                      controller.setMapStyle(_darkMapStyle);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    markers: Set<Marker>.from(MapService.alertMarkers),
                    polylines: MapService.routePoints.length > 1
                        ? {
                            Polyline(
                              polylineId: const PolylineId('route'),
                              points: List<LatLng>.from(
                                  MapService.routePoints),
                              color: Colors.blueAccent,
                              width: 4,
                            ),
                          }
                        : {},
                  ),

            // ── Top-left label ──────────────────────────────
            Positioned(
              top: 8,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.map, color: Colors.blueAccent, size: 12),
                    SizedBox(width: 4),
                    Text('Live Map',
                        style:
                            TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),

            // ── Alert count badge ───────────────────────────
            if (MapService.alertMarkers.isNotEmpty)
              Positioned(
                top: 8,
                right: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${MapService.alertMarkers.length} alerts',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 10),
                  ),
                ),
              ),

            // ── Expand button ───────────────────────────────
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: widget.onExpand,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.open_in_full,
                      color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMap() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 8),
            Text('Getting location...',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]}
]
''';