import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../services/voice_chat_service.dart';

enum VoiceState { idle, listening, thinking, speaking }

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
  bool _processingDone = false;

  // ── Animation ─────────────────────────────────────────────
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
    await _tts.setSpeechRate(0.50);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.1);
  }

  // ── STT init ──────────────────────────────────────────────
  Future<void> _initStt() async {
    _sttReady = await _stt.initialize(
      onError: (e) {
        debugPrint('STT error: ${e.errorMsg}');
        if (mounted && _voiceState == VoiceState.listening) {
          _onSttDone();
        }
      },
      onStatus: (status) {
        debugPrint('STT status: $status');
        if ((status == 'done' || status == 'notListening') &&
            mounted &&
            _voiceState == VoiceState.listening) {
          _onSttDone();
        }
      },
    );
    if (!_sttReady) debugPrint('STT failed to initialise');
  }

  // ── FAB tap ───────────────────────────────────────────────
  Future<void> _activate() async {
    // Cancel if already active
    if (_voiceState != VoiceState.idle) {
      await _stt.stop();
      await _tts.stop();
      _setVoiceState(VoiceState.idle, transcript: '', reply: '');
      return;
    }
    await _startListening();
  }

  Future<void> _startListening() async {
    if (!_sttReady) {
      _sttReady = await _stt.initialize();
      if (!_sttReady) {
        _setVoiceState(VoiceState.speaking,
            reply: 'Microphone unavailable. Check permissions.');
        await _speak('Microphone unavailable. Check permissions.');
        _setVoiceState(VoiceState.idle);
        return;
      }
    }

    // Small gap so mic doesn't catch TTS tail
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;
    _setVoiceState(VoiceState.listening, transcript: '', reply: '');
    _processingDone = false;

    await _stt.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _transcript = result.recognizedWords);
        if (result.finalResult) _onSttDone();
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 2),  // 2s silence = done
      cancelOnError: false,
      partialResults: true,
      localeId: 'en_US',
    );
  }

  // ── STT done → send to Claude ─────────────────────────────
  Future<void> _onSttDone() async {
    if (_processingDone || _voiceState != VoiceState.listening) return;
    _processingDone = true;

    await _stt.stop();
    final text = _transcript.trim();

    if (text.isEmpty) {
      _setVoiceState(VoiceState.speaking,
          reply: "I didn't catch that. Try again.");
      await _speak("I didn't catch that. Try again.");
      _setVoiceState(VoiceState.idle);
      _processingDone = false;
      return;
    }

    // Thinking → Claude
    _setVoiceState(VoiceState.thinking, transcript: text);

    final result = await VoiceChatService.sendMessage(text);

    // Execute in-app action if returned
    if (result.action != null && mounted) {
      widget.onCommand?.call(result.action!);
    }

    final replyText = result.reply.isNotEmpty
        ? result.reply
        : _confirmAction(result.action);

    _setVoiceState(VoiceState.speaking, reply: replyText);
    await _speak(replyText);

    _processingDone = false;
    _setVoiceState(VoiceState.idle);
  }

  String _confirmAction(String? action) {
    switch (action) {
      case 'START_MONITORING': return 'Monitoring started.';
      case 'STOP_MONITORING':  return 'Monitoring stopped.';
      case 'OPEN_SOS':         return 'Opening emergency screen.';
      case 'OPEN_DASHBOARD':   return 'Opening dashboard.';
      case 'OPEN_MAP':         return 'Opening the map.';
      default:                 return 'Done.';
    }
  }

  // ── TTS — reliable completer pattern ─────────────────────
  Future<void> _speak(String text) async {
    if (text.isEmpty || !mounted) return;

    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 80));

    final completer = Completer<void>();
    void done() { if (!completer.isCompleted) completer.complete(); }

    _tts.setCompletionHandler(done);
    _tts.setCancelHandler(done);
    _tts.setErrorHandler((_) => done());

    await _tts.speak(text);
    await completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: done,
    );
  }

  void _setVoiceState(VoiceState s,
      {String? transcript, String? reply}) {
    if (!mounted) return;
    setState(() {
      _voiceState = s;
      if (transcript != null) _transcript = transcript;
      if (reply      != null) _reply      = reply;
    });
  }

  // ── BUILD ─────────────────────────────────────────────────
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

  Widget _buildSheet() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xF00D1117),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _stateColor().withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
              color: _stateColor().withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // State label row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animCtrl,
                builder: (_, __) => Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _stateColor()
                        .withOpacity(0.4 + _animCtrl.value * 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _stateLabel(),
                style: TextStyle(
                  color: _stateColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (_voiceState == VoiceState.listening)
            _buildWaveform()
          else if (_voiceState == VoiceState.thinking)
            Column(
              children: [
                Text(
                  '"$_transcript"',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                _buildThinkingDots(),
              ],
            )
          else
            Column(
              children: [
                Text(
                  _reply,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_transcript.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '"$_transcript"',
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),

          if (_voiceState == VoiceState.listening) ...[
            const SizedBox(height: 10),
            Text(
              'Tap to cancel',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  // ── Animated waveform ─────────────────────────────────────
  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(11, (i) {
            final phase = (i * 0.32 + _animCtrl.value * 3.0) % 1.0;
            final h = 5.0 + 30.0 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
            return Container(
              width: 4,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  // ── Thinking dots ─────────────────────────────────────────
  Widget _buildThinkingDots() {
    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final opacity =
                (((_animCtrl.value * 3) - i).clamp(0.0, 1.0));
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(0.3 + opacity * 0.7),
              ),
            );
          }),
        );
      },
    );
  }

  // ── FAB ───────────────────────────────────────────────────
  Widget _buildFAB() {
    final isActive = _voiceState != VoiceState.idle;
    return GestureDetector(
      onTap: _activate,
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (_, child) {
          final scale = isActive ? 1.0 + _animCtrl.value * 0.08 : 1.0;
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _fabColor().withOpacity(0.9),
                _fabColor(),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _fabColor().withOpacity(isActive ? 0.6 : 0.3),
                blurRadius: isActive ? 24 : 10,
                spreadRadius: isActive ? 4 : 1,
              ),
            ],
          ),
          child: Icon(_fabIcon(), color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Color _fabColor() {
    switch (_voiceState) {
      case VoiceState.idle:      return const Color(0xFF1565C0);
      case VoiceState.listening: return const Color(0xFFD32F2F);
      case VoiceState.thinking:  return const Color(0xFF6A1B9A);
      case VoiceState.speaking:  return const Color(0xFF00796B);
    }
  }

  Color _stateColor() {
    switch (_voiceState) {
      case VoiceState.idle:      return Colors.blueAccent;
      case VoiceState.listening: return Colors.redAccent;
      case VoiceState.thinking:  return Colors.purpleAccent;
      case VoiceState.speaking:  return Colors.tealAccent;
    }
  }

  IconData _fabIcon() {
    switch (_voiceState) {
      case VoiceState.idle:      return Icons.mic_none_rounded;
      case VoiceState.listening: return Icons.mic_rounded;
      case VoiceState.thinking:  return Icons.psychology_rounded;
      case VoiceState.speaking:  return Icons.volume_up_rounded;
    }
  }

  String _stateLabel() {
    switch (_voiceState) {
      case VoiceState.idle:      return '';
      case VoiceState.listening: return 'LISTENING';
      case VoiceState.thinking:  return 'THINKING';
      case VoiceState.speaking:  return 'NEX';
    }
  }
}
