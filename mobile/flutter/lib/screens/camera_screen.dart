import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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
  bool _isProcessing = false;
  String _status = 'Initializing camera...';
  String _alertMessage = 'No fatigue detected yet.';
  bool _showAlertOverlay = false;
  double _fatigueScore = 0.0;
  DateTime _lastAlert = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastEmergencySms = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetectionService?.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await FirebaseService.initialize();
      await LocationService.initialize();
      _faceDetectionService = FaceDetectionService();
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_processCameraImage);

      setState(() {
        _status = 'Camera ready. Face detection active.';
      });
    } catch (error) {
      setState(() {
        _status = 'Camera initialization failed: $error';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _cameraController == null) return;
    _isProcessing = true;

    try {
      final face = await _faceDetectionService!.processCameraImage(
        image,
        _cameraController!.description.sensorOrientation,
      );

      if (face == null) {
        setState(() {
          _status = 'No face detected. Please look at the camera.';
          _showAlertOverlay = false;
          _fatigueScore = 0.0;
          _alertMessage = 'No face detected.';
        });
      } else {
        final metrics = _evaluateFatigue(face);
        final score = metrics['score'] as double;
        final alert = metrics['alert'] as bool;
        final message = metrics['message'] as String;

        setState(() {
          _status = 'Driver detected. Score: ${score.toStringAsFixed(0)}%';
          _fatigueScore = score;
          _showAlertOverlay = alert;
          _alertMessage = message;
        });

        if (alert && DateTime.now().difference(_lastAlert).inSeconds > 3) {
          _lastAlert = DateTime.now();
          await AlertService.triggerAlert();
          // Voice alerts are disabled for Android emulator compatibility.
          await NotificationService.showAlertNotification('Fatigue risk detected', message);
          if (DateTime.now().difference(_lastEmergencySms).inMinutes >= 1) {
            _lastEmergencySms = DateTime.now();
            await _notifyEmergencyContact(message);
          }
          final position = await LocationService.getCurrentPosition();
          final locationString = position != null ? LocationService.formatPosition(position) : 'unknown';
          await FirebaseService.logFatigueEvent({
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'score': score,
            'message': message,
            'location': locationString,
          });
          await ApiService.recordTrip({
            'trip_id': DateTime.now().millisecondsSinceEpoch.toString(),
            'start_time': DateTime.now().toUtc().toIso8601String(),
            'end_time': DateTime.now().toUtc().toIso8601String(),
            'fatigue_score': score,
            'alerts': [message],
            'location': locationString,
          });
        }
      }
    } catch (error) {
      setState(() {
        _status = 'Detection error: $error';
      });
    }

    _isProcessing = false;
  }

  Future<void> _notifyEmergencyContact(String message) async {
    final success = await EmergencyContactService.sendSmsAlert(message);
    if (!success) {
      await NotificationService.showAlertNotification('Emergency contact', 'No emergency contact configured or SMS unavailable.');
    } else {
      await NotificationService.showAlertNotification('Emergency SMS sent', 'Your emergency contact was notified.');
    }
  }

  Map<String, Object> _evaluateFatigue(Face face) {
    final leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;
    final eyeScore = (leftEyeOpen + rightEyeOpen) / 2.0;
    final headYaw = face.headEulerAngleY?.abs() ?? 0.0;
    final headRoll = face.headEulerAngleZ?.abs() ?? 0.0;

    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
    final upperLip = face.contours[FaceContourType.upperLipTop];
    final lowerLip = face.contours[FaceContourType.lowerLipBottom];

    double mouthOpenRatio = 0.0;
    if (leftMouth != null && rightMouth != null && upperLip != null && lowerLip != null) {
      final width = _distance(leftMouth.position, rightMouth.position);
      final upperAverageY = upperLip.points.map((p) => p.y).reduce((a, b) => a + b) / upperLip.points.length;
      final lowerAverageY = lowerLip.points.map((p) => p.y).reduce((a, b) => a + b) / lowerLip.points.length;
      final height = (lowerAverageY - upperAverageY).abs();
      if (width > 0) {
        mouthOpenRatio = height / width;
      }
    }

    final yawning = mouthOpenRatio > 0.35;
    final eyesClosed = eyeScore < 0.35;
    final distracted = headYaw > 20 || headRoll > 20;

    double score = 0.0;
    score += (1.0 - eyeScore) * 50;
    if (yawning) score += 25;
    if (distracted) score += 25;
    score = score.clamp(0, 100);

    final shouldAlert = eyesClosed || yawning || distracted;
    final statusMessage = shouldAlert
        ? 'Fatigue alert: ${eyesClosed ? 'eyes closed' : yawning ? 'yawning' : 'head down/distracted'}'
        : 'Driver alertness stable.';

    return {
      'score': score,
      'alert': shouldAlert,
      'message': statusMessage,
    };
  }

  double _distance(Point<num> a, Point<num> b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Fatigue Detection'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _cameraController == null || !_cameraController!.value.isInitialized
                  ? Center(child: Text(_status, style: const TextStyle(color: Colors.white)))
                  : Stack(
                      children: [
                        CameraPreview(_cameraController!),
                        if (_showAlertOverlay)
                          Container(
                            color: Colors.red.withOpacity(0.45),
                          ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 20,
                          child: Card(
                            color: Colors.black.withOpacity(0.6),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_status, style: const TextStyle(color: Colors.white, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text('Fatigue Score: ${_fatigueScore.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(_alertMessage, style: const TextStyle(color: Colors.white70)),
                                  if (_showAlertOverlay)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.sms),
                                        label: const Text('Notify Emergency Contact'),
                                        onPressed: () => _notifyEmergencyContact(_alertMessage),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Real-time driver fatigue monitoring', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Looks for eye closure, yawning, and head pose', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('• Sends events to Firebase and backend trip logging', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
