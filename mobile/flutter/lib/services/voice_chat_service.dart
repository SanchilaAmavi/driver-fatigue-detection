import 'dart:convert';
import 'package:http/http.dart' as http;

class VoiceChatService {
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY';
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  static final List<Map<String, String>> _history = [];

  static double currentFatigueScore = 0.0;
  static String currentAlertLevel   = 'NORMAL';
  static int    currentAlertCount   = 0;
  static bool   isMonitoring        = false;
  static String currentLocation     = 'Unknown';
  static double currentSpeed        = 0.0;

  static void updateState({
    double? score, String? level, int? alerts,
    bool? monitoring, String? location, double? speed,
  }) {
    if (score      != null) currentFatigueScore = score;
    if (level      != null) currentAlertLevel   = level;
    if (alerts     != null) currentAlertCount   = alerts;
    if (monitoring != null) isMonitoring        = monitoring;
    if (location   != null) currentLocation     = location;
    if (speed      != null) currentSpeed        = speed;
  }

  static void clearHistory() => _history.clear();

  /// Returns {reply: String, action: String?}
  /// action is one of: START_MONITORING | STOP_MONITORING |
  ///                   OPEN_SOS | OPEN_DASHBOARD | OPEN_MAP | null
  static Future<({String reply, String? action})> sendMessage(
      String userText) async {
    _history.add({'role': 'user', 'content': userText});
    if (_history.length > 20) {
      _history.removeRange(0, _history.length - 20);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type'      : 'application/json',
          'x-api-key'         : _apiKey,
          'anthropic-version' : '2023-06-01',
        },
        body: jsonEncode({
          'model'      : 'claude-3-haiku-20240307',
          'max_tokens' : 180,
          'system'     : _buildSystemPrompt(),
          'messages'   : _history,
        }),
      );

      if (response.statusCode == 200) {
        final data     = jsonDecode(response.body);
        final raw      = data['content'][0]['text'] as String;
        final parsed   = _parseResponse(raw);
        _history.add({'role': 'assistant', 'content': parsed.reply});
        return parsed;
      } else {
        return (reply: _fallback(userText), action: null);
      }
    } catch (e) {
      return (reply: _fallback(userText), action: null);
    }
  }

  // ── Parse [ACTION:XXX] tag from response ─────────────────
  static ({String reply, String? action}) _parseResponse(String raw) {
    final actionRegex = RegExp(r'\[ACTION:(\w+)\]');
    final match = actionRegex.firstMatch(raw);
    final action = match?.group(1);
    final reply  = raw.replaceAll(actionRegex, '').trim();
    return (reply: reply, action: action);
  }

  static String _buildSystemPrompt() => '''
You are Nex, a friendly, witty, and helpful AI voice assistant built into a car app called NexDrive.

CURRENT DRIVER STATE:
- Fatigue score: ${currentFatigueScore.toStringAsFixed(0)}%
- Alert level: $currentAlertLevel
- Alerts this session: $currentAlertCount
- Monitoring: ${isMonitoring ? "active" : "stopped"}
- Location: $currentLocation
- Speed: ${currentSpeed.toStringAsFixed(0)} km/h

PERSONALITY:
- Warm, conversational, and natural. Not robotic.
- You can chat about ANYTHING — jokes, weather, music, life advice, random questions, anything.
- Keep replies to 1–3 short sentences max. You are being spoken aloud.
- No markdown, no bullet points, no symbols. Plain spoken English only.
- If fatigue score is above 75%, gently remind the driver to rest at the end of your reply.

IN-APP ACTIONS:
If the driver asks you to do something inside the app, include an action tag at the END of your reply (after your spoken sentence), like this:
[ACTION:START_MONITORING]
[ACTION:STOP_MONITORING]
[ACTION:OPEN_SOS]
[ACTION:OPEN_DASHBOARD]
[ACTION:OPEN_MAP]

Examples:
- "start monitoring" → reply + [ACTION:START_MONITORING]
- "open the map" → reply + [ACTION:OPEN_MAP]
- "I need help, emergency" → reply + [ACTION:OPEN_SOS]
- "show me the dashboard" → reply + [ACTION:OPEN_DASHBOARD]
- "what is the capital of France?" → just reply, no action tag
- "tell me a joke" → just reply, no action tag

Only include an action tag when the driver clearly wants to navigate or control the app.
''';

  static String _fallback(String input) {
    final t = input.toLowerCase();
    if (t.contains('score') || t.contains('fatigue'))
      return 'Your fatigue score is ${currentFatigueScore.toStringAsFixed(0)} percent.';
    if (t.contains('start monitor')) return 'Starting monitoring now.';
    if (t.contains('stop monitor'))  return 'Monitoring stopped.';
    if (t.contains('emergency') || t.contains('sos'))
      return 'Opening emergency screen. Stay calm.';
    if (t.contains('map'))           return 'Opening the map.';
    if (t.contains('dashboard'))     return 'Opening dashboard.';
    return "I'm here. Ask me anything.";
  }

  // Keep for hard-coded command detection as a fallback
  static String? parseCommand(String text) {
    final t = text.toLowerCase();
    if (t.contains('start monitor'))                   return 'START_MONITORING';
    if (t.contains('stop monitor'))                    return 'STOP_MONITORING';
    if (t.contains('sos') || t.contains('emergency'))  return 'OPEN_SOS';
    if (t.contains('dashboard'))                       return 'OPEN_DASHBOARD';
    if (t.contains('open the map') || t.contains('show map')) return 'OPEN_MAP';
    return null;
  }
}