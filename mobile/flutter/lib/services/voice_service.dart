class VoiceService {
  static Future<void> speak(String message) async {
    // Disabled on emulator because TTS engine initialization can crash
    // the Android x86 Google TTS service.
    return;
  }
}
