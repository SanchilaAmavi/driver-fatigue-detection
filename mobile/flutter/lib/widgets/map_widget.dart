import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapWidget extends StatefulWidget {
  final VoidCallback? onExpand;
  const MapWidget({super.key, this.onExpand});

  @override
  State<MapWidget> createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();

  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);

  LatLng? _currentPosition;
  bool    _locationLoaded = false;

  final List<Marker>   _alertMarkers = [];
  int                  _markerIdCounter = 0;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationLoaded = true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentPosition = latLng;
        _locationLoaded  = true;
      });

      _mapController.move(latLng, 15.0);
    } catch (e) {
      debugPrint('MapWidget location error: $e');
      if (mounted) setState(() => _locationLoaded = true);
    }
  }

  /// Called from CameraScreen when fatigue alert fires
  Future<void> addAlertMarker(
      dynamic position, String level, String message) async {
    if (!mounted) return;
    final latLng = LatLng(position.latitude, position.longitude);
    final color = switch (level) {
      'CRITICAL' => Colors.red,
      'DANGER'   => Colors.orange,
      'WARNING'  => Colors.yellow,
      _          => Colors.green,
    };

    setState(() {
      _alertMarkers.add(
        Marker(
          point: latLng,
          width: 40,
          height: 40,
          child: Tooltip(
            message: '$level: $message',
            child: Icon(Icons.warning_rounded, color: color, size: 32),
          ),
        ),
      );
      _markerIdCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // ── Map ─────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? _defaultCenter,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                       InteractiveFlag.drag,
              ),
            ),
            children: [
              // OpenStreetMap tile layer — completely free
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nexdrive.app',
                maxZoom: 19,
              ),

              // Alert markers
              if (_alertMarkers.isNotEmpty)
                MarkerLayer(markers: _alertMarkers),

              // Current location marker
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.blueAccent, width: 2),
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.blueAccent,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Loading overlay ──────────────────────────────
          if (!_locationLoaded)
            Container(
              color: const Color(0xFF0A0E1A),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        color: Colors.blueAccent, strokeWidth: 2),
                    SizedBox(height: 8),
                    Text('Locating...',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
            ),

          // ── Expand button ────────────────────────────────
          if (widget.onExpand != null)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: widget.onExpand,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.fullscreen,
                      color: Colors.white, size: 18),
                ),
              ),
            ),

          // ── Re-center button ─────────────────────────────
          Positioned(
            bottom: 8,
            right: 6,
            child: GestureDetector(
              onTap: () {
                if (_currentPosition != null) {
                  _mapController.move(_currentPosition!, 15.0);
                } else {
                  _getLocation();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.my_location,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
