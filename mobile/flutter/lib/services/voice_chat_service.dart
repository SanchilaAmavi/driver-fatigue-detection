import 'package:flutter/foundation.dart';

class VoiceChatService {
  static final List<Map<String, String>> _history = [];

  static double currentFatigueScore = 0.0;
  static String currentAlertLevel   = 'NORMAL';
  static int    currentAlertCount   = 0;
  static bool   isMonitoring        = false;
  static String currentLocation     = 'Unknown';
  static double currentSpeed        = 0.0;

  static void updateState({
    double? score,
    String? level,
    int?    alerts,
    bool?   monitoring,
    String? location,
    double? speed,
  }) {
    if (score      != null) currentFatigueScore = score;
    if (level      != null) currentAlertLevel   = level;
    if (alerts     != null) currentAlertCount   = alerts;
    if (monitoring != null) isMonitoring        = monitoring;
    if (location   != null) currentLocation     = location;
    if (speed      != null) currentSpeed        = speed;
  }

  static void clearHistory() => _history.clear();

  static Future<({String reply, String? action})> sendMessage(
      String userText) async {
    _history.add({'role': 'user', 'content': userText});
    if (_history.length > 20) {
      _history.removeRange(0, _history.length - 20);
    }

    debugPrint('NEX local processing: "$userText"');
    final raw    = _localReply(userText.toLowerCase().trim());
    final parsed = _parseResponse(raw);
    debugPrint('NEX local reply: $raw');

    _history.add({'role': 'assistant', 'content': parsed.reply});
    return parsed;
  }

  // ── Local rule engine ─────────────────────────────────────
  static String _localReply(String t) {

    // ── App commands ──────────────────────────────────────
    if (t.contains('start monitor') || t.contains('begin monitor'))
      return 'Starting monitoring now. Stay safe! [ACTION:START_MONITORING]';

    if (t.contains('stop monitor') || t.contains('end monitor'))
      return 'Monitoring stopped. Drive safely. [ACTION:STOP_MONITORING]';

    if (t.contains('open map') || t.contains('show map') ||
        t.contains('open the map') || t.contains('where am i'))
      return 'Opening the map now. [ACTION:OPEN_MAP]';

    if (t.contains('dashboard') || t.contains('open dash'))
      return 'Opening your dashboard. [ACTION:OPEN_DASHBOARD]';

    if (t.contains('sos') || t.contains('emergency') ||
        t.contains('help me') || t.contains('call for help'))
      return 'Opening emergency screen. Stay calm. [ACTION:OPEN_SOS]';

    // ── Fatigue & driving state ───────────────────────────
    if (t.contains('fatigue') || t.contains('score') ||
        t.contains('how am i doing') || t.contains('my status')) {
      final score = currentFatigueScore.toStringAsFixed(0);
      if (currentFatigueScore >= 75)
        return 'Your fatigue score is $score percent — that is critical. Please pull over and rest immediately.';
      if (currentFatigueScore >= 50)
        return 'Your fatigue score is $score percent. You are getting tired. Consider taking a break soon.';
      if (currentFatigueScore >= 25)
        return 'Your fatigue score is $score percent. Mild fatigue detected. Stay alert.';
      return 'Your fatigue score is $score percent. You are doing well. Keep it up!';
    }

    if (t.contains('alert') || t.contains('warning')) {
      if (currentAlertCount == 0)
        return 'No alerts so far this session. Great driving!';
      return 'You have had $currentAlertCount alert${currentAlertCount > 1 ? "s" : ""} this session. Stay focused.';
    }

    if (t.contains('level') || t.contains('danger')) {
      switch (currentAlertLevel) {
        case 'CRITICAL': return 'Alert level is critical. Please stop driving and rest immediately.';
        case 'DANGER':   return 'Alert level is danger. You are quite fatigued. Take a break very soon.';
        case 'WARNING':  return 'Alert level is warning. Mild fatigue signs detected. Stay alert.';
        default:         return 'Alert level is normal. You are driving safely.';
      }
    }

    if (t.contains('monitor') && !t.contains('start') && !t.contains('stop'))
      return isMonitoring
          ? 'Monitoring is currently active and watching for fatigue signs.'
          : 'Monitoring is currently off. Tap Start Monitoring to begin.';

    if (t.contains('speed'))
      return 'Your current speed is ${currentSpeed.toStringAsFixed(0)} kilometers per hour.';

    if (t.contains('location') || t.contains('where are we') ||
        t.contains('where are you'))
      return 'Your current location is $currentLocation.';

    // ── Greetings ─────────────────────────────────────────
    if (t.contains('hello') || t.contains('hi nex') ||
        t.contains('hey nex') || t.contains('hey') || t.contains('hi'))
      return 'Hey there! I am Nex, your driving assistant. How can I help you today?';

    if (t.contains('good morning'))
      return 'Good morning! Stay alert and have a safe drive today.';

    if (t.contains('good afternoon'))
      return 'Good afternoon! Remember to take breaks on long drives.';

    if (t.contains('good night') || t.contains('goodnight'))
      return 'Good night! Night driving increases fatigue risk, so please be extra careful.';

    if (t.contains('how are you') || t.contains('are you okay'))
      return 'I am fully operational and keeping a close eye on your drive!';

    if (t.contains('what is your name') || t.contains('who are you'))
      return 'I am Nex, your NexDrive voice assistant. I monitor your fatigue and help you drive safely.';

    if (t.contains('what can you do') || t.contains('help'))
      return 'I can monitor your fatigue, open the map, show the dashboard, send an SOS, and chat with you on the road.';

    // ── Wellbeing & tiredness ─────────────────────────────
    if (t.contains('tired') || t.contains('sleepy') ||
        t.contains('drowsy') || t.contains('i need a break')) {
      if (currentFatigueScore > 50)
        return 'Your fatigue score agrees. Please find a safe place to pull over and rest.';
      return 'Listen to your body. Pull over safely and take a short break. Even ten minutes helps a lot.';
    }

    if (t.contains('break') || t.contains('rest stop') ||
        t.contains('pull over'))
      return 'Good idea. Find a safe spot to pull over, rest for at least fifteen minutes, and have some water.';

    if (t.contains('coffee') || t.contains('caffeine') ||
        t.contains('energy drink'))
      return 'Caffeine can help short term, but it is not a substitute for real rest. Take a proper break when you can.';

    if (t.contains('eyes') || t.contains('blinking'))
      return 'Keep blinking regularly. Dry eyes can increase fatigue. If your eyes feel heavy, please pull over.';

    // ── Jokes & casual chat ───────────────────────────────
    if (t.contains('joke') || t.contains('funny') ||
        t.contains('make me laugh') || t.contains('tell me something'))
      return _randomJoke();

    if (t.contains('bored') || t.contains('boring'))
      return 'Let me tell you something interesting. Did you know the average person blinks fifteen times per minute? On long drives it drops to seven, which is why eyes dry out so fast.';

    if (t.contains('sing') || t.contains('song'))
      return 'I would love to sing but I might put you to sleep! How about I tell you a joke instead?';

    if (t.contains('music') || t.contains('playlist'))
      return 'I cannot play music directly, but some upbeat tunes really help on long drives. Try something lively!';

    if (t.contains('weather'))
      return 'I do not have live weather data right now, but always adjust your speed in rain or fog.';

    if (t.contains('time') || t.contains('what time'))
      return 'I do not have a clock right now, but check your phone display for the time.';

    // ── Motivational ──────────────────────────────────────
    if (t.contains('i can do this') || t.contains('almost there') ||
        t.contains('nearly there'))
      return 'You are doing great! Stay focused and keep going. Safety first though — take a break if you need one.';

    if (t.contains('thank') || t.contains('thanks'))
      return 'You are welcome! Stay safe out there.';

    if (t.contains('bye') || t.contains('goodbye') ||
        t.contains('see you'))
      return 'Take care and drive safely. Goodbye!';

    if (t.contains('awesome') || t.contains('great') ||
        t.contains('nice') || t.contains('cool'))
      return 'Glad to hear it! Keep that positive energy on the road.';

    // ── Driving tips ──────────────────────────────────────
    if (t.contains('tip') || t.contains('advice') ||
        t.contains('suggest'))
      return _drivingTip();

    if (t.contains('safe') || t.contains('safety'))
      return 'Always keep a safe following distance, stay off your phone, and take regular breaks every two hours.';

    if (t.contains('distance') || t.contains('following'))
      return 'Keep at least a three second gap from the car in front. In wet conditions, double that to six seconds.';

    if (t.contains('rain') || t.contains('wet') || t.contains('storm'))
      return 'In wet conditions, reduce speed and increase following distance. Turn on your headlights too.';

    if (t.contains('night') || t.contains('dark') || t.contains('lights'))
      return 'Night driving is tiring. Make sure your headlights are on and take more frequent breaks than usual.';

    // ── General knowledge fallbacks ───────────────────────
    if (t.contains('capital') || t.contains('country') ||
        t.contains('president') || t.contains('history'))
      return 'That is a great question! I am focused on keeping you safe right now, but you can ask me again when parked.';

    if (t.contains('recipe') || t.contains('food') || t.contains('eat'))
      return 'Food talk! Smart drivers stop for a proper meal rather than eating behind the wheel. Safety first!';

    if (t.contains('sport') || t.contains('game') || t.contains('score'))
      return 'I do not have live sports updates, but I can keep your fatigue score low! Stay focused on the road.';

    if (t.contains('movie') || t.contains('film') || t.contains('watch'))
      return 'Save the movies for when you arrive safely. Eyes on the road for now!';

    if (t.contains('love') || t.contains('miss you'))
      return 'That is sweet! Get home safely so you can spend time with the people who matter.';

    // ── Default ───────────────────────────────────────────
    return 'I am here and listening. You can ask me about your fatigue score, driving tips, or say commands like open map or start monitoring.';
  }

  // ── Jokes pool ────────────────────────────────────────────
  static int _jokeIndex = 0;
  static final List<String> _jokes = [
    'Why do driving instructors always pass their exams? Because they know all the turns!',
    'I tried to come up with a joke about cars but I exhausted all my ideas.',
    'Why did the bicycle fall over? Because it was two tired.',
    'What do you call a sleeping dinosaur while driving? A car-nivore catching some Z\'s.',
    'Why do cows wear bells? Because their horns do not work.',
    'I used to hate facial hair but then it grew on me.',
    'Why did the scarecrow win an award? Because he was outstanding in his field.',
    'What do you call cheese that is not yours? Nacho cheese!',
  ];

  static String _randomJoke() {
    final joke = _jokes[_jokeIndex % _jokes.length];
    _jokeIndex++;
    return joke;
  }

  // ── Driving tips pool ─────────────────────────────────────
  static int _tipIndex = 0;
  static final List<String> _tips = [
    'Take a break every two hours on long drives. Even a ten minute walk helps reset your alertness.',
    'Stay hydrated. Dehydration increases fatigue significantly. Keep a water bottle in the car.',
    'Avoid driving between midnight and six in the morning when your body clock naturally dips.',
    'Keep the car cool and well ventilated. A warm car makes you drowsy faster.',
    'Avoid heavy meals before driving. A big meal diverts blood flow and causes drowsiness.',
    'If you feel yourself nodding off, pull over immediately. There is no safe way to push through real sleepiness.',
    'Chewing gum or singing along to music can help maintain alertness on short stretches.',
  ];

  static String _drivingTip() {
    final tip = _tips[_tipIndex % _tips.length];
    _tipIndex++;
    return tip;
  }

  // ── Response parser ───────────────────────────────────────
  static ({String reply, String? action}) _parseResponse(String raw) {
    final actionRegex = RegExp(r'\[ACTION:(\w+)\]');
    final match  = actionRegex.firstMatch(raw);
    final action = match?.group(1);
    final reply  = raw.replaceAll(actionRegex, '').trim();
    return (reply: reply, action: action);
  }

  // ── Command parser (used by voice_assistant_screen) ───────
  static String? parseCommand(String text) {
    final t = text.toLowerCase();
    if (t.contains('start monitor'))                  return 'START_MONITORING';
    if (t.contains('stop monitor'))                   return 'STOP_MONITORING';
    if (t.contains('sos') || t.contains('emergency')) return 'OPEN_SOS';
    if (t.contains('dashboard'))                      return 'OPEN_DASHBOARD';
    if (t.contains('open map') || t.contains('show map') ||
        t.contains('open the map'))                   return 'OPEN_MAP';
    return null;
  }
}
