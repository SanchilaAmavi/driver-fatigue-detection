import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapWidget extends StatefulWidget {
  final VoidCallback? onExpand;
  const MapWidget({super.key, this.onExpand});

  @override
  State<MapWidget> createState() => MapWidgetState(); // public, not _private
}

class MapWidgetState extends State<MapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng _defaultCenter = LatLng(6.9271, 79.8612);

  LatLng? _currentPosition;
  final Set<Marker> _markers = {};
  int _markerIdCounter = 0;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final latLng = LatLng(pos.latitude, pos.longitude);
    setState(() => _currentPosition = latLng);

    final ctrl = await _controller.future;
    ctrl.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
  }

  /// Called from CameraScreen when a fatigue alert fires
  Future<void> addAlertMarker(
      dynamic position, String level, String message) async {
    final latLng = LatLng(position.latitude, position.longitude);
    final color = switch (level) {
      'CRITICAL' => BitmapDescriptor.hueRed,
      'DANGER'   => BitmapDescriptor.hueOrange,
      'WARNING'  => BitmapDescriptor.hueYellow,
      _          => BitmapDescriptor.hueGreen,
    };

    final marker = Marker(
      markerId: MarkerId('alert_${_markerIdCounter++}'),
      position: latLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(color),
      infoWindow: InfoWindow(title: level, snippet: message),
    );

    setState(() => _markers.add(marker));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? _defaultCenter,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: Set.from(_markers),
            onMapCreated: (ctrl) => _controller.complete(ctrl),
          ),
          // Expand button (top-right)
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
        ],
      ),
    );
  }
}