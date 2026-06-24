import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/alert_service.dart';
import '../services/api_service.dart';
import '../services/emergency_contact_service.dart';
import '../services/face_detection_service.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../services/notification_service.dart';
import '../services/voice_alert_service.dart';
import '../services/voice_chat_service.dart';
import '../widgets/map_widget.dart';
import '../widgets/voice_fab.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  // ── Camera & detection ────────────────────────────────────
  CameraController? _cameraController;
  FaceDetectionService? _faceDetectionService;
  bool _isProcessing = false;
  bool _isMonitoring = false;

  // ── Status & alert state ──────────────────────────────────
  String _status = 'Tap Start to begin monitoring';
  String _alertMessage = 'No fatigue detected yet.';
  String _alertLevel = 'NORMAL';
  bool _showAlertOverlay = false;
  double _fatigueScore = 0.0;
  int _alertCount = 0;

  // ── Timestamps ────────────────────────────────────────────
  DateTime _sessionStart = DateTime.now();
  DateTime _lastAlert = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastEmergencySms = DateTime.fromMillisecondsSinceEpoch(0);

  // ── Consecutive-frame counters ────────────────────────────
  int _eyesClosedFrames = 0;
  int _yawnFrames = 0;
  int _distractedFrames = 0;
  static const int _eyesClosedThreshold = 8;
  static const int _yawnThreshold = 10;
  static const int _distractedThreshold = 12;

  // ── Blink animation ───────────────────────────────────────
  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;

  // ── Map widget key ────────────────────────────────────────
  final GlobalKey<MapWidgetState> _mapKey = GlobalKey<MapWidgetState>();
  // ── Map visibility toggle ─────────────────────────────────
  bool _showMap = true;

  Color get _alertColor {
    switch (_alertLevel) {
      case 'CRITICAL': return Colors.red;
      case 'DANGER':   return Colors.orange;
      case 'WARNING':  return Colors.yellow;
      default:         return Colors.green;
    }
  }

  // ── Init ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _blinkAnim =
        Tween<double>(begin: 0.1, end: 0.45).animate(_blinkController);
    _initializeCamera();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _cameraController?.dispose();
    _faceDetectionService?.dispose();
    VoiceAlertService.dispose();
    super.dispose();
  }

  // ── Permissions ───────────────────────────────────────────
  Future<bool> _requestPermissions() async {
    final camera = await Permission.camera.request();
    await Permission.location.request();
    await Permission.notification.request();
    await Permission.microphone.request(); // needed for voice FAB
    if (!camera.isGranted) {
      setState(() => _status =
          '❌ Camera permission denied.\nSettings → Apps → NexDrive → Permissions → Camera');
      return false;
    }
    return true;
  }

  // ── Camera init ───────────────────────────────────────────
  Future<void> _initializeCamera() async {
    setState(() => _status = '🔄 Requesting permissions...');
    if (!await _requestPermissions()) return;

    setState(() => _status = '🔄 Starting camera...');
    try {
      await FirebaseService.initialize();
      await LocationService.initialize();
      await VoiceAlertService.initialize();
      _faceDetectionService = FaceDetectionService();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _status = '❌ No camera found');
        return;
      }

      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      setState(() => _status = '✅ Camera ready — Tap Start');
    } catch (e) {
      setState(() => _status = '❌ Camera error: $e');
    }
  }

  // ── Start / Stop ──────────────────────────────────────────
  Future<void> _toggleMonitoring() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      await _initializeCamera();
      return;
    }

    if (_isMonitoring) {
      await _cameraController!.stopImageStream();
      _saveTrip();
      _resetCounters();
      MapService.clearSession();
      await VoiceAlertService.stop();
      setState(() {
        _isMonitoring = false;
        _status = '⏹ Monitoring stopped';
        _showAlertOverlay = false;
        _fatigueScore = 0.0;
        _alertLevel = 'NORMAL';
      });
      VoiceChatService.updateState(
        score: _fatigueScore,
        level: _alertLevel,
        alerts: _alertCount,
        monitoring: _isMonitoring,
      );
    } else {
      _sessionStart = DateTime.now();
      _alertCount = 0;
      _resetCounters();
      MapService.clearSession();
      await _cameraController!.startImageStream(_processCameraImage);
      setState(() {
        _isMonitoring = true;
        _status = '🟢 Monitoring active';
      });
      VoiceChatService.updateState(
        score: _fatigueScore,
        level: _alertLevel,
        alerts: _alertCount,
        monitoring: _isMonitoring,
      );
    }
  }

  void _resetCounters() {
    _eyesClosedFrames = 0;
    _yawnFrames = 0;
    _distractedFrames = 0;
  }

  // ── Frame processor ───────────────────────────────────────
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _cameraController == null) return;
    _isProcessing = true;
    try {
      final face = await _faceDetectionService!.processCameraImage(
        image,
        _cameraController!.description.sensorOrientation,
      );
      if (!mounted) return;
      if (face == null) {
        _resetCounters();
        setState(() {
          _status = '👤 No face detected — look at camera';
          _showAlertOverlay = false;
          _fatigueScore = 0.0;
          _alertLevel = 'NORMAL';
          _alertMessage = 'Position your face in the camera';
        });
      } else {
        await _handleFace(face);
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Detection error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // ── Face handler ──────────────────────────────────────────
  Future<void> _handleFace(Face face) async {
    // 1. Eye openness
    final leftEye  = face.leftEyeOpenProbability  ?? 1.0;
    final rightEye = face.rightEyeOpenProbability ?? 1.0;
    final avgEye   = (leftEye + rightEye) / 2.0;
    final eyesClosed = avgEye < 0.25;

    // 2. Yawn
    final yawning = _detectYawn(face);

    // 3. Head pose
    final headYaw   = face.headEulerAngleY?.abs() ?? 0.0;
    final headPitch = face.headEulerAngleX?.abs() ?? 0.0;
    final headRoll  = face.headEulerAngleZ?.abs() ?? 0.0;
    final distracted = headYaw > 25 || headRoll > 20 || headPitch > 20;

    // 4. Frame counters
    eyesClosed ? _eyesClosedFrames++ : _eyesClosedFrames = 0;
    yawning    ? _yawnFrames++       : _yawnFrames       = 0;
    distracted ? _distractedFrames++ : _distractedFrames = 0;

    // 5. Alert conditions
    final eyesAlert = _eyesClosedFrames >= _eyesClosedThreshold;
    final yawnAlert = _yawnFrames       >= _yawnThreshold;
    final headAlert = _distractedFrames >= _distractedThreshold;
    final anyAlert  = eyesAlert || yawnAlert || headAlert;

    // 6. Score
    double score = 0.0;
    score += (1.0 - avgEye).clamp(0.0, 1.0) * 50;
    if (yawning)    score += 25;
    if (distracted) score += 15;
    if (_eyesClosedFrames > 3) {
      score += (_eyesClosedFrames * 2).clamp(0, 10).toDouble();
    }
    score = score.clamp(0, 100);

    // 7. Level
    String level;
    if (score >= 75)      level = 'CRITICAL';
    else if (score >= 50) level = 'DANGER';
    else if (score >= 25) level = 'WARNING';
    else                  level = 'NORMAL';

    // 8. Message
    String message;
    if (eyesAlert)       message = '😴 Eyes closed! Wake up — DANGER!';
    else if (yawnAlert)  message = '😮 Yawning detected — Take a break!';
    else if (headAlert)  message = '😵 Head drooping/distracted — Stay focused!';
    else if (eyesClosed) message = '⚠️ Eyes closing... ($_eyesClosedFrames/$_eyesClosedThreshold)';
    else if (yawning)    message = '⚠️ Possible yawn... ($_yawnFrames/$_yawnThreshold)';
    else                 message = '✅ Driver alert — Score: ${score.toStringAsFixed(0)}%';

    if (mounted) {
      setState(() {
        _fatigueScore     = score;
        _showAlertOverlay = anyAlert;
        _alertMessage     = message;
        _alertLevel       = level;
        _status = anyAlert
            ? '⚠️ $level — ${eyesAlert ? "EYES CLOSED" : yawnAlert ? "YAWNING" : "DISTRACTED"}'
            : '✅ Score: ${score.toStringAsFixed(0)}% | Eyes: ${(avgEye * 100).toStringAsFixed(0)}%';
      });

      VoiceChatService.updateState(
        score: score,
        level: level,
        alerts: _alertCount,
        monitoring: _isMonitoring,
      );
    }

    // 9. Trigger alerts
    if (anyAlert &&
        DateTime.now().difference(_lastAlert).inSeconds > 3) {
      _lastAlert  = DateTime.now();
      _alertCount += 1;

      await AlertService.triggerAlert();

      await VoiceAlertService.speakAlert(
        eyesAlert: eyesAlert,
        yawnAlert: yawnAlert,
        headAlert: headAlert,
        level: level,
      );

      await NotificationService.showAlertNotification(
          '🚨 Fatigue Alert ($level)', message);

      VoiceChatService.updateState(
        score: score,
        level: level,
        alerts: _alertCount,
        monitoring: _isMonitoring,
      );

      if (DateTime.now().difference(_lastEmergencySms).inMinutes >= 1) {
        _lastEmergencySms = DateTime.now();
        await _notifyEmergencyContact(message);
      }

      final position = await LocationService.getCurrentPosition();

      if (position != null) {
        _mapKey.currentState?.addAlertMarker(position, level, message);
      }

      final loc = position != null
          ? LocationService.formatPosition(position)
          : 'unknown';

      await FirebaseService.logFatigueEvent({
        'timestamp'   : DateTime.now().toUtc().toIso8601String(),
        'score'       : score,
        'level'       : level,
        'message'     : message,
        'location'    : loc,
        'eyes_frames' : _eyesClosedFrames,
        'yawn_frames' : _yawnFrames,
        'head_frames' : _distractedFrames,
      });
    }
  }

  // ── Yawn detection ────────────────────────────────────────
  bool _detectYawn(Face face) {
    final upperLip   = face.contours[FaceContourType.upperLipTop];
    final lowerLip   = face.contours[FaceContourType.lowerLipBottom];
    final leftMouth  = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];

    if (upperLip != null && lowerLip != null &&
        leftMouth != null && rightMouth != null) {
      final width = _dist(leftMouth.position, rightMouth.position);
      if (width <= 0) return false;
      final upperY = upperLip.points
          .map((p) => p.y.toDouble())
          .reduce((a, b) => a + b) / upperLip.points.length;
      final lowerY = lowerLip.points
          .map((p) => p.y.toDouble())
          .reduce((a, b) => a + b) / lowerLip.points.length;
      return ((lowerY - upperY).abs() / width) > 0.35;
    }

    if (leftMouth != null && rightMouth != null) {
      final mouthWidth  = _dist(leftMouth.position, rightMouth.position);
      final noseBase    = face.landmarks[FaceLandmarkType.noseBase];
      final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];
      if (noseBase != null && bottomMouth != null) {
        final ratio = _dist(noseBase.position, bottomMouth.position) /
            (mouthWidth > 0 ? mouthWidth : 1);
        return ratio > 0.6;
      }
    }
    return false;
  }

  double _dist(Point<num> a, Point<num> b) =>
      sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2));

  // ── Trip save ─────────────────────────────────────────────
  Future<void> _saveTrip() async {
    final duration  = DateTime.now().difference(_sessionStart).inSeconds;
    final safeScore = (100.0 - (_alertCount * 5.0)).clamp(0.0, 100.0);
    await ApiService.recordTrip({
      'driver_id'  : 'driver_001',
      'duration'   : duration,
      'alerts'     : _alertCount,
      'safe_score' : safeScore,
      'distance_km': 0.0,
    });
  }

  // ── Emergency contact ─────────────────────────────────────
  Future<void> _notifyEmergencyContact(String message) async {
    final ok = await EmergencyContactService.sendSmsAlert(message);
    await NotificationService.showAlertNotification(
      ok ? '📱 Emergency SMS sent' : '⚠️ Emergency contact',
      ok ? 'Your emergency contact was notified'
         : 'No emergency contact configured',
    );
  }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Row(
          children: [
            Icon(Icons.remove_red_eye, color: Colors.blue),
            SizedBox(width: 8),
            Text('Fatigue Monitor',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showMap ? Icons.map : Icons.map_outlined,
              color: _showMap ? Colors.blueAccent : Colors.white54,
            ),
            tooltip: 'Toggle map',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
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
                    color: _alertCount > 0 ? Colors.red : Colors.green,
                  ),
                ),
                child: Text(
                  '$_alertCount alerts',
                  style: TextStyle(
                    color: _alertCount > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // ── Voice FAB — wired to app actions ──────────────────
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80), // clear bottom controls
        child: VoiceFAB(
          onCommand: (action) {
            switch (action) {
              case 'START_MONITORING':
                if (!_isMonitoring) _toggleMonitoring();
              case 'STOP_MONITORING':
                if (_isMonitoring) _toggleMonitoring();
              case 'OPEN_SOS':
                Navigator.pushNamed(context, '/emergency');
              case 'OPEN_DASHBOARD':
                Navigator.pushNamed(context, '/dashboard');
              case 'OPEN_MAP':
                Navigator.pushNamed(context, '/map');
            }
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _cameraController == null ||
                      !_cameraController!.value.isInitialized
                  ? _buildNoCameraView()
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_cameraController!),

                        // Blinking alert overlay
                        if (_showAlertOverlay)
                          AnimatedBuilder(
                            animation: _blinkAnim,
                            builder: (_, __) => Container(
                              color: _alertColor
                                  .withOpacity(_blinkAnim.value),
                            ),
                          ),

                        Positioned(
                          top: 0, left: 0, right: 0,
                          child: _buildTopStatusBar(),
                        ),

                        // Map widget (bottom-left)
                        if (_showMap)
                          Positioned(
                            left: 12,
                            bottom: 130,
                            child: SizedBox(
                              width: 175,
                              height: 145,
                              child: MapWidget(
                                key: _mapKey,
                                onExpand: () => Navigator.pushNamed(
                                    context, '/map'),
                              ),
                            ),
                          ),

                        Positioned(
                          left: 16, right: 16, bottom: 16,
                          child: _buildInfoCard(),
                        ),

                        if (_showAlertOverlay)
                          Positioned(
                            top: 60, left: 20, right: 20,
                            child: _buildAlertBanner(),
                          ),

                        Positioned(
                          top: 60, right: 10,
                          child: _buildDebugPanel(),
                        ),
                      ],
                    ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────

  Widget _buildDebugPanel() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('👁 Closed: $_eyesClosedFrames/$_eyesClosedThreshold',
              style: TextStyle(
                  color: _eyesClosedFrames > 0
                      ? Colors.red
                      : Colors.white54,
                  fontSize: 10)),
          Text('😮 Yawn:  $_yawnFrames/$_yawnThreshold',
              style: TextStyle(
                  color: _yawnFrames > 0 ? Colors.orange : Colors.white54,
                  fontSize: 10)),
          Text('😵 Head:  $_distractedFrames/$_distractedThreshold',
              style: TextStyle(
                  color: _distractedFrames > 0
                      ? Colors.yellow
                      : Colors.white54,
                  fontSize: 10)),
        ],
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
            Icon(Icons.camera_alt,
                size: 80, color: Colors.blue.withOpacity(0.5)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(_status,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              color: _alertColor.withOpacity(0.5), blurRadius: 15)
        ],
      ),
      child: Row(
        children: [
          Icon(
            _alertLevel == 'CRITICAL'
                ? Icons.dangerous
                : Icons.warning_amber,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _alertMessage,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
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
        border: Border.all(color: _alertColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
              valueColor: AlwaysStoppedAnimation<Color>(_alertColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(_alertMessage,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13)),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMonitoring ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
              label: Text(
                _isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _toggleMonitoring,
            ),
          ),
          const SizedBox(height: 10),
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
                  onPressed: () =>
                      Navigator.pushNamed(context, '/emergency'),
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