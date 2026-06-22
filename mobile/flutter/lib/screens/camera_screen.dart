import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/alert_service.dart';
import '../services/emergency_contact_service.dart';
import '../services/firebase_service.dart';
import '../services/face_detection_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  FaceDetectionService? _faceDetectionService;
  bool _isProcessing       = false;
  bool _isMonitoring       = false;
  String _status           = 'Tap Start to begin monitoring';
  String _alertMessage     = 'No fatigue detected yet.';
  String _alertLevel       = 'NORMAL';
  bool _showAlertOverlay   = false;
  double _fatigueScore     = 0.0;
  int _alertCount          = 0;
  DateTime _sessionStart   = DateTime.now();
  DateTime _lastAlert      = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastEmergencySms = DateTime.fromMillisecondsSinceEpoch(0);

  // Alert level colors
  Color get _alertColor {
    switch (_alertLevel) {
      case 'CRITICAL': return Colors.red;
      case 'DANGER':   return Colors.orange;
      case 'WARNING':  return Colors.yellow;
      default:         return Colors.green;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetectionService?.dispose();
    super.dispose();
  }

  // ── Step 1: Request permissions ──────────────────────────
  Future<bool> _requestPermissions() async {
    final camera   = await Permission.camera.request();
    await Permission.location.request();
    await Permission.notification.request();

    if (!camera.isGranted) {
      setState(() =>
        _status = '❌ Camera permission denied.\nGo to Settings → Apps → NexDrive → Permissions → Allow Camera');
      return false;
    }
    return true;
  }

  // ── Step 2: Initialize camera ────────────────────────────
  Future<void> _initializeCamera() async {
    setState(() => _status = '🔄 Requesting permissions...');

    final granted = await _requestPermissions();
    if (!granted) return;

    setState(() => _status = '🔄 Starting camera...');

    try {
      await FirebaseService.initialize();
      await LocationService.initialize();
      _faceDetectionService = FaceDetectionService();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _status = '❌ No camera found on device');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      setState(() => _status = '✅ Camera ready — Tap Start to begin');
    } catch (e) {
      setState(() => _status = '❌ Camera error: $e');
    }
  }

  // ── Step 3: Start/Stop monitoring ────────────────────────
  Future<void> _toggleMonitoring() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      await _initializeCamera();
      return;
    }

    if (_isMonitoring) {
      // Stop
      await _cameraController!.stopImageStream();
      _saveTrip();
      setState(() {
        _isMonitoring    = false;
        _status          = '⏹ Monitoring stopped';
        _showAlertOverlay = false;
        _fatigueScore    = 0.0;
        _alertLevel      = 'NORMAL';
      });
    } else {
      // Start
      _sessionStart = DateTime.now();
      _alertCount   = 0;
      await _cameraController!.startImageStream(_processCameraImage);
      setState(() {
        _isMonitoring = true;
        _status       = '🟢 Monitoring active — Face detection running';
      });
    }
  }

  // ── Step 4: Process each camera frame ────────────────────
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _cameraController == null) return;
    _isProcessing = true;

    try {
      final face = await _faceDetectionService!.processCameraImage(
        image,
        _cameraController!.description.sensorOrientation,
      );

      if (face == null) {
        if (mounted) {
          setState(() {
            _status           = '👤 No face detected — look at camera';
            _showAlertOverlay = false;
            _fatigueScore     = 0.0;
            _alertLevel       = 'NORMAL';
            _alertMessage     = 'Position your face in the camera';
          });
        }
      } else {
        final metrics  = _evaluateFatigue(face);
        final score    = metrics['score']   as double;
        final alert    = metrics['alert']   as bool;
        final message  = metrics['message'] as String;
        final level    = metrics['level']   as String;

        if (mounted) {
          setState(() {
            _fatigueScore     = score;
            _showAlertOverlay = alert;
            _alertMessage     = message;
            _alertLevel       = level;
            _status = alert
                ? '⚠️  $level detected!'
                : '✅ Driver alert — Score: ${score.toStringAsFixed(0)}%';
          });
        }

        // Trigger alerts
        if (alert &&
            DateTime.now().difference(_lastAlert).inSeconds > 3) {
          _lastAlert  = DateTime.now();
          _alertCount += 1;

          await AlertService.triggerAlert();
          await NotificationService.showAlertNotification(
              '🚨 Fatigue Alert', message);

          // Emergency SMS (max once per minute)
          if (DateTime.now()
                  .difference(_lastEmergencySms)
                  .inMinutes >= 1) {
            _lastEmergencySms = DateTime.now();
            await _notifyEmergencyContact(message);
          }

          // Log to Firebase
          final position =
              await LocationService.getCurrentPosition();
          final loc = position != null
              ? LocationService.formatPosition(position)
              : 'unknown';

          await FirebaseService.logFatigueEvent({
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'score'    : score,
            'level'    : level,
            'message'  : message,
            'location' : loc,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Detection error: $e');
      }
    }

    _isProcessing = false;
  }

  // ── Step 5: Save trip when monitoring stops ───────────────
  Future<void> _saveTrip() async {
    final duration = DateTime.now()
        .difference(_sessionStart)
        .inSeconds;
    final safeScore =
        100.0 - (_alertCount * 5.0).clamp(0, 100);

    await ApiService.recordTrip({
      'driver_id'  : 'driver_001',
      'duration'   : duration,
      'alerts'     : _alertCount,
      'safe_score' : safeScore,
      'distance_km': 0.0,
    });
  }

  // ── Step 6: Notify emergency contact ─────────────────────
  Future<void> _notifyEmergencyContact(String message) async {
    final ok =
        await EmergencyContactService.sendSmsAlert(message);
    await NotificationService.showAlertNotification(
      ok ? '📱 Emergency SMS sent' : '⚠️ Emergency contact',
      ok
          ? 'Your emergency contact was notified'
          : 'No emergency contact configured',
    );
  }

  // ── Step 7: Fatigue evaluation algorithm ─────────────────
  Map<String, Object> _evaluateFatigue(Face face) {
    final leftEye  = face.leftEyeOpenProbability  ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    final eyeScore = (leftEye + rightEye) / 2.0;
    final headYaw  = face.headEulerAngleY?.abs() ?? 0.0;
    final headRoll = face.headEulerAngleZ?.abs() ?? 0.0;

    // Mouth open ratio for yawn detection
    double mouthOpenRatio = 0.0;
    final leftMouth  = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    final upperLip   = face.contours[FaceContourType.upperLipTop];
    final lowerLip   = face.contours[FaceContourType.lowerLipBottom];

    if (leftMouth != null && rightMouth != null &&
        upperLip  != null && lowerLip   != null) {
      final width = _distance(leftMouth.position, rightMouth.position);
      final upperY = upperLip.points
          .map((p) => p.y)
          .reduce((a, b) => a + b) / upperLip.points.length;
      final lowerY = lowerLip.points
          .map((p) => p.y)
          .reduce((a, b) => a + b) / lowerLip.points.length;
      final height = (lowerY - upperY).abs();
      if (width > 0) mouthOpenRatio = height / width;
    }

    final eyesClosed  = eyeScore < 0.35;
    final yawning     = mouthOpenRatio > 0.35;
    final distracted  = headYaw > 20 || headRoll > 20;

    // Calculate score
    double score = 0.0;
    score += (1.0 - eyeScore) * 50;
    if (yawning)    score += 25;
    if (distracted) score += 25;
    score = score.clamp(0, 100);

    // Determine level
    String level;
    if (score >= 75)      level = 'CRITICAL';
    else if (score >= 50) level = 'DANGER';
    else if (score >= 25) level = 'WARNING';
    else                  level = 'NORMAL';

    final shouldAlert = eyesClosed || yawning || distracted;
    final message = shouldAlert
        ? '${eyesClosed ? '😴 Eyes closed' : yawning ? '😮 Yawning detected' : '😵 Head turned/distracted'} — Please stay alert!'
        : '✅ Driver alertness stable';

    return {
      'score'  : score,
      'alert'  : shouldAlert,
      'message': message,
      'level'  : level,
    };
  }

  double _distance(Point<num> a, Point<num> b) =>
      sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: Row(
          children: [
            const Icon(Icons.remove_red_eye, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Fatigue Monitor',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          // Alert counter badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _alertCount > 0
                      ? Colors.red.withOpacity(0.3)
                      : Colors.green.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _alertCount > 0
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                child: Text(
                  '$_alertCount alerts',
                  style: TextStyle(
                    color: _alertCount > 0
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Camera Preview ──
            Expanded(
              child: _cameraController == null ||
                      !_cameraController!.value.isInitialized
                  ? _buildNoCameraView()
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        // Camera feed
                        CameraPreview(_cameraController!),

                        // Alert overlay
                        if (_showAlertOverlay)
                          AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 300),
                            color: _alertColor.withOpacity(0.3),
                          ),

                        // Top status bar
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: _buildTopStatusBar(),
                        ),

                        // Bottom info card
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: _buildInfoCard(),
                        ),

                        // Alert banner
                        if (_showAlertOverlay)
                          Positioned(
                            top: 60,
                            left: 20,
                            right: 20,
                            child: _buildAlertBanner(),
                          ),
                      ],
                    ),
            ),

            // ── Bottom Controls ──
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCameraView() {
    return Container(
      color: const Color(0xFF0A0E1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 80,
              color: Colors.blue.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _status,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _initializeCamera,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _isMonitoring ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isMonitoring ? 'LIVE' : 'STOPPED',
            style: TextStyle(
              color: _isMonitoring ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            'Score: ${_fatigueScore.toStringAsFixed(0)}%',
            style: const TextStyle(
                color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _alertColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: _alertColor.withOpacity(0.5),
              blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          Icon(
            _alertLevel == 'CRITICAL'
                ? Icons.dangerous
                : Icons.warning_amber,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _alertMessage,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _alertColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fatigue Score',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 12)),
              Text(
                '${_fatigueScore.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _alertColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _fatigueScore / 100,
              backgroundColor: Colors.white12,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_alertColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _alertMessage,
            style: const TextStyle(
                color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0A0E1A),
      child: Column(
        children: [
          // Main start/stop button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isMonitoring ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(
                  _isMonitoring ? Icons.stop : Icons.play_arrow),
              label: Text(
                _isMonitoring
                    ? 'Stop Monitoring'
                    : 'Start Monitoring',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _toggleMonitoring,
            ),
          ),
          const SizedBox(height: 10),

          // Secondary buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.sos, size: 18),
                  label: const Text('SOS',
                      style: TextStyle(fontSize: 13)),
                  onPressed: () => Navigator.pushNamed(
                      context, '/emergency'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.dashboard, size: 18),
                  label: const Text('Dashboard',
                      style: TextStyle(fontSize: 13)),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/dashboard'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}