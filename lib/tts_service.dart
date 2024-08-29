import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  Function(int)? onProgressUpdate; // Callback for progress updates

  TtsService() {
    _flutterTts.setStartHandler(() {
      print("TTS started");
    });

    _flutterTts.setCompletionHandler(() {
      print("TTS completed");
    });

    _flutterTts.setProgressHandler((String text, int startOffset, int endOffset, String word) {
      if (onProgressUpdate != null) {
        onProgressUpdate!(startOffset);
      }
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS error: $msg");
    });
  }

  Future<void> speak(String text, {Function(int)? onProgressUpdate}) async {
    this.onProgressUpdate = onProgressUpdate;
    await _flutterTts.setLanguage('en-IN');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Future<void> pause() async {
    await _flutterTts.stop(); // No direct pause method; stopping is used as a workaround
  }
}
