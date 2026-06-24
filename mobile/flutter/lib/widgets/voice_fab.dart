import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/voice_chat_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Voice states
// ─────────────────────────────────────────────────────────────────────────────
enum VoiceState { idle, listening, thinking, speaking }

// ─────────────────────────────────────────────────────────────────────────────
// VoiceFAB — Siri-style bidirectional voice assistant overlay
// ─────────────────────────────────────────────────────────────────────────────
class VoiceFAB extends StatefulWidget {
  final Function(String action)? onCommand;

  const VoiceFAB({super.key, this.onCommand});

  @override
  State<VoiceFAB> createState() => _VoiceFABState();
}

class _VoiceFABState extends State<VoiceFAB>
    with SingleTickerProviderStateMixin {
  // ── STT ───────────────────────────────────────────────────
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;

  // ── TTS ───────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();

  // ── State ─────────────────────────────────────────────────
  VoiceState _voiceState = VoiceState.idle;
  String _transcript = '';
  String _reply      = '';

  // ── Animation ─────────────────────────────────────────────
  late AnimationController _animCtrl;

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _initTts();
    _initStt();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _stt.stop();
    _tts.stop();
    super.dispose();
  }

  // ── TTS init ──────────────────────────────────────────────
  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
  }

  // ── STT init ──────────────────────────────────────────────
  Future<void> _initStt() async {
    _sttReady = await _stt.initialize(
      onError: (e) => debugPrint('STT error: ${e.errorMsg}'),
      onStatus: (status) {
        debugPrint('STT status: $status');
        if ((status == 'done' || status == 'notListening') &&
            _voiceState == VoiceState.listening) {
          _onSttDone();
        }
      },
    );
    if (!_sttReady) debugPrint('STT failed to initialise');
  }

  // ─────────────────────────────────────────────────────────
  // FAB tap — entry point
  // ─────────────────────────────────────────────────────────
  Future<void> _activate() async {
    // Second tap cancels
    if (_voiceState != VoiceState.idle) {
      await _stt.stop();
      await _tts.stop();
      _setState(VoiceState.idle, transcript: '', reply: '');
      return;
    }

    // Re-init STT if needed
    if (!_sttReady) {
      _sttReady = await _stt.initialize();
      if (!_sttReady) {
        _setState(VoiceState.speaking,
            reply: 'Microphone is not available.');
        await _speak('Microphone is not available.');
        _setState(VoiceState.idle);
        return;
      }
    }

    // Stop TTS so mic doesn't pick up assistant voice
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 200));

    _setState(VoiceState.listening, transcript: '', reply: '');

    await _stt.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _transcript = result.recognizedWords);
        if (result.finalResult) _onSttDone();
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: false,
      partialResults: true,
      localeId: 'en_US',
    );
  }

  // ── STT finished ──────────────────────────────────────────
  bool _processingDone = false;

  Future<void> _onSttDone() async {
    if (_processingDone || _voiceState != VoiceState.listening) return;
    _processingDone = true;

    await _stt.stop();
    final text = _transcript.trim();
    _processingDone = false;

    // Nothing heard
    if (text.isEmpty) {
      _setState(VoiceState.speaking,
          reply: "I didn't catch that. Tap the mic and try again.");
      await _speak("I didn't catch that. Tap the mic and try again.");
      _setState(VoiceState.idle);
      return;
    }

    // ── Claude handles everything — chat + actions ─────────
    _setState(VoiceState.thinking, transcript: text);
    final result = await VoiceChatService.sendMessage(text);

    // Execute app action if Claude detected one
    if (result.action != null) {
      widget.onCommand?.call(result.action!);
    }

    // Speak reply (fall back to confirmation if reply is empty)
    final replyText = result.reply.isNotEmpty
        ? result.reply
        : _actionConfirmation(result.action);

    _setState(VoiceState.speaking, reply: replyText);
    await _speak(replyText);
    _setState(VoiceState.idle);
  }

  String _actionConfirmation(String? action) {
    switch (action) {
      case 'START_MONITORING': return 'Starting monitoring now.';
      case 'STOP_MONITORING':  return 'Monitoring stopped.';
      case 'OPEN_SOS':         return 'Opening emergency screen. Stay calm.';
      case 'OPEN_DASHBOARD':   return 'Opening dashboard.';
      case 'OPEN_MAP':         return 'Opening the map.';
      default:                 return 'Done.';
    }
  }

  // ── TTS speak — waits until done ──────────────────────────
  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 100));

    final completer = Completer<void>();

    void complete() {
      if (!completer.isCompleted) completer.complete();
    }

    _tts.setCompletionHandler(complete);
    _tts.setCancelHandler(complete);
    _tts.setErrorHandler((_) => complete());

    await _tts.speak(text);
    await completer.future.timeout(
      const Duration(seconds: 40),
      onTimeout: complete,
    );
  }

  void _setState(VoiceState s, {String? transcript, String? reply}) {
    if (!mounted) return;
    setState(() {
      _voiceState = s;
      if (transcript != null) _transcript = transcript;
      if (reply      != null) _reply      = reply;
    });
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_voiceState != VoiceState.idle) ...[
          _buildSheet(),
          const SizedBox(height: 12),
        ],
        _buildFAB(),
      ],
    );
  }

  // ── Overlay sheet ─────────────────────────────────────────
  Widget _buildSheet() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xEE0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _stateColor().withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── State indicator row ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animCtrl,
                builder: (_, __) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _stateColor()
                        .withOpacity(0.5 + _animCtrl.value * 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _stateLabel(),
                style: TextStyle(
                  color: _stateColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Main content area ────────────────────────────
          if (_voiceState == VoiceState.listening)
            _buildWaveform()
          else
            Text(
              _voiceState == VoiceState.thinking ? _transcript : _reply,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),

          // ── Show what user said while speaking reply ─────
          if (_voiceState == VoiceState.speaking &&
              _transcript.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"$_transcript"',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Cancel hint while listening ──────────────────
          if (_voiceState == VoiceState.listening) ...[
            const SizedBox(height: 10),
            Text(
              'Tap mic to cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Animated waveform bars ────────────────────────────────
  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(9, (i) {
            final phase =
                (i * 0.38 + _animCtrl.value * 2.5) % 1.0;
            final h = 6.0 +
                28.0 *
                    (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
            return Container(
              width: 4,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.85),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  // ── FAB button ────────────────────────────────────────────
  Widget _buildFAB() {
    final isActive = _voiceState != VoiceState.idle;
    return GestureDetector(
      onTap: _activate,
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (_, child) {
          final scale =
              isActive ? 1.0 + _animCtrl.value * 0.10 : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _fabColor(),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _fabColor().withOpacity(0.5),
                      blurRadius: 22,
                      spreadRadius: 4,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child:
              Icon(_fabIcon(), color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  Color _fabColor() {
    switch (_voiceState) {
      case VoiceState.idle:      return const Color(0xFF1565C0);
      case VoiceState.listening: return const Color(0xFFD32F2F);
      case VoiceState.thinking:  return const Color(0xFF6A1B9A);
      case VoiceState.speaking:  return const Color(0xFF2E7D32);
    }
  }

  Color _stateColor() {
    switch (_voiceState) {
      case VoiceState.idle:      return Colors.blue;
      case VoiceState.listening: return Colors.redAccent;
      case VoiceState.thinking:  return Colors.purpleAccent;
      case VoiceState.speaking:  return Colors.greenAccent;
    }
  }

  IconData _fabIcon() {
    switch (_voiceState) {
      case VoiceState.idle:      return Icons.mic_none_rounded;
      case VoiceState.listening: return Icons.mic_rounded;
      case VoiceState.thinking:  return Icons.hourglass_top_rounded;
      case VoiceState.speaking:  return Icons.volume_up_rounded;
    }
  }

  String _stateLabel() {
    switch (_voiceState) {
      case VoiceState.idle:      return '';
      case VoiceState.listening: return 'LISTENING';
      case VoiceState.thinking:  return 'THINKING...';
      case VoiceState.speaking:  return 'NEX';
    }
  }
}