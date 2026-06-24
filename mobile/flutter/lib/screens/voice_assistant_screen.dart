import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import '../services/voice_alert_service.dart';
import '../services/voice_chat_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  final List<_ChatMessage> _messages = [];
  final ScrollController _scroll    = ScrollController();

  bool   _isListening  = false;
  bool   _isThinking   = false;
  bool   _isSpeaking   = false;
  String _liveText     = '';

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.9, end: 1.1).animate(_pulseCtrl);
    _init();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scroll.dispose();
    SpeechService.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await SpeechService.initialize();
    await VoiceAlertService.initialize();
    _addMessage(
      'Hello! I am NexDrive, your driving assistant. '
      'Ask me about your fatigue score, alerts, or say a command like "Start monitoring".',
      isUser: false,
    );
    await VoiceAlertService.initialize();
    _speak(
        'Hello! I am NexDrive. How can I help you today?');
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: isUser,
          time: TimeOfDay.now()));
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    await VoiceAlertService.initialize();
    // Use flutter_tts directly for chat responses
    await _ttsSpeak(text);
    setState(() => _isSpeaking = false);
  }

  // Direct TTS call for chat (not fatigue alerts)
  Future<void> _ttsSpeak(String text) async {
    // VoiceAlertService exposes FlutterTts indirectly,
    // so we reuse the same TTS instance via a simple speak
    await VoiceAlertService.speakRaw(text);
  }

  Future<void> _startListening() async {
    if (_isListening || _isThinking) return;
    setState(() {
      _isListening = true;
      _liveText    = '';
    });

    await SpeechService.startListening(
      onResult: (text) => setState(() => _liveText = text),
      onDone: () async {
        final text = _liveText.trim();
        setState(() => _isListening = false);
        if (text.isEmpty) return;
        await _handleUserInput(text);
      },
    );
  }

  Future<void> _stopListening() async {
    await SpeechService.stopListening();
    setState(() => _isListening = false);
  }

  Future<void> _handleUserInput(String text) async {
    _addMessage(text, isUser: true);
    setState(() => _isThinking = true);

    // Check for commands first
    final command = VoiceChatService.parseCommand(text);
    if (command != null) {
      await _handleCommand(command, text);
      setState(() => _isThinking = false);
      return;
    }

    // Send to Claude
    final reply = await VoiceChatService.sendMessage(text);
    setState(() => _isThinking = false);
    _addMessage(reply.reply, isUser: false);
await _speak(reply.reply);
  }

  Future<void> _handleCommand(
      String command, String originalText) async {
    String response;
    switch (command) {
      case 'START_MONITORING':
        response = 'Starting monitoring now. Stay alert and safe.';
        _addMessage(response, isUser: false);
        await _speak(response);
        if (mounted) Navigator.pushNamed(context, '/camera');
        break;
      case 'STOP_MONITORING':
        response = 'Stopping monitoring. Drive safe.';
        _addMessage(response, isUser: false);
        await _speak(response);
        if (mounted) Navigator.pop(context);
        break;
      case 'OPEN_SOS':
        response = 'Opening emergency screen now.';
        _addMessage(response, isUser: false);
        await _speak(response);
        if (mounted) Navigator.pushNamed(context, '/emergency');
        break;
      case 'OPEN_DASHBOARD':
        response = 'Opening your dashboard.';
        _addMessage(response, isUser: false);
        await _speak(response);
        if (mounted) Navigator.pushNamed(context, '/dashboard');
        break;
      case 'OPEN_MAP':
        response = 'Opening the live map.';
        _addMessage(response, isUser: false);
        await _speak(response);
        if (mounted) Navigator.pushNamed(context, '/map');
        break;
      case 'OPEN_BREAK':
        response = 'Opening break recommendations.';
        _addMessage(response, isUser: false);
        await _speak(response);
        if (mounted) Navigator.pushNamed(context, '/break');
        break;
      default:
        final reply = await VoiceChatService.sendMessage(originalText);
        _addMessage(reply.reply, isUser: false);
        await _speak(reply.reply);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('NexDrive Assistant',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            tooltip: 'Clear chat',
            onPressed: () {
              setState(() => _messages.clear());
              VoiceChatService.clearHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Status bar ─────────────────────────────────
          _buildStatusBar(),

          // ── Chat messages ───────────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        _messages.length + (_isThinking ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_isThinking && i == _messages.length) {
                        return _buildThinkingBubble();
                      }
                      return _buildMessageBubble(_messages[i]);
                    },
                  ),
          ),

          // ── Live transcript ─────────────────────────────
          if (_isListening && _liveText.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.blue.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hearing,
                      color: Colors.blueAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_liveText,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
            ),

          // ── Mic button area ─────────────────────────────
          _buildMicArea(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final score = VoiceChatService.currentFatigueScore;
    final level = VoiceChatService.currentAlertLevel;
    final color = level == 'CRITICAL'
        ? Colors.red
        : level == 'DANGER'
            ? Colors.orange
            : level == 'WARNING'
                ? Colors.yellow
                : Colors.green;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1A1F2E),
      child: Row(
        children: [
          Icon(Icons.monitor_heart, color: color, size: 16),
          const SizedBox(width: 6),
          Text('Fatigue: ${score.toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 14,
            color: Colors.white24,
          ),
          const SizedBox(width: 16),
          Icon(Icons.warning_amber, color: color, size: 16),
          const SizedBox(width: 6),
          Text(level,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Icon(
            VoiceChatService.isMonitoring
                ? Icons.visibility
                : Icons.visibility_off,
            color: VoiceChatService.isMonitoring
                ? Colors.green
                : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            VoiceChatService.isMonitoring ? 'LIVE' : 'OFF',
            style: TextStyle(
              color: VoiceChatService.isMonitoring
                  ? Colors.green
                  : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.record_voice_over,
              size: 64, color: Colors.blueAccent.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('Hold the mic to speak',
              style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
            'Try: "What is my fatigue score?"\nor "Start monitoring"',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.blueAccent.withOpacity(0.85)
                    : const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.text,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person,
                  color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(200),
                const SizedBox(width: 4),
                _dot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, val, __) => Opacity(
        opacity: val,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildMicArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF0A0E1A),
      child: Column(
        children: [
          // ── Voice command hints ───────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _HintChip(
                    label: '🎯 Fatigue score',
                    onTap: () =>
                        _handleUserInput('What is my fatigue score?')),
                const SizedBox(width: 8),
                _HintChip(
                    label: '🚗 Start monitoring',
                    onTap: () =>
                        _handleUserInput('Start monitoring')),
                const SizedBox(width: 8),
                _HintChip(
                    label: '🗺️ Open map',
                    onTap: () => _handleUserInput('Open map')),
                const SizedBox(width: 8),
                _HintChip(
                    label: '🆘 SOS',
                    onTap: () => _handleUserInput('SOS emergency')),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Mic button ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speaking indicator
              if (_isSpeaking)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.volume_up,
                          color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('Speaking',
                          style: TextStyle(
                              color: Colors.green, fontSize: 12)),
                    ],
                  ),
                ),

              // Main mic button
              GestureDetector(
                onTapDown: (_) => _startListening(),
                onTapUp: (_) => _stopListening(),
                onTapCancel: () => _stopListening(),
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => Transform.scale(
                    scale:
                        _isListening ? _pulseAnim.value : 1.0,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? Colors.red
                            : _isThinking
                                ? Colors.orange
                                : Colors.blueAccent,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening
                                    ? Colors.red
                                    : Colors.blueAccent)
                                .withOpacity(0.4),
                            blurRadius: _isListening ? 20 : 10,
                            spreadRadius:
                                _isListening ? 4 : 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening
                            ? Icons.mic
                            : _isThinking
                                ? Icons.hourglass_top
                                : Icons.mic_none,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isListening
                ? 'Listening... release to send'
                : _isThinking
                    ? 'Thinking...'
                    : _isSpeaking
                        ? 'NexDrive is speaking...'
                        : 'Hold to speak',
            style: const TextStyle(
                color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final TimeOfDay time;
  const _ChatMessage(
      {required this.text,
      required this.isUser,
      required this.time});
}

class _HintChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _HintChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.blueAccent.withOpacity(0.4)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
      ),
    );
  }
}