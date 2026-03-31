import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

enum VoiceState { idle, listening, speaking }

class VoiceService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  VoiceState _state = VoiceState.idle;
  VoiceState get state => _state;
  bool _isListeningSessionActive = false;

  Function()? onSpeakDone;
  Function()? onListeningDone;

  void _setState(VoiceState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  Future<void> _applyVoiceSettings() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> init() async {
    await _applyVoiceSettings();

    _flutterTts.setCompletionHandler(() {
      _setState(VoiceState.idle);
      onSpeakDone?.call();
    });

    _flutterTts.setCancelHandler(() {
      _setState(VoiceState.idle);
      onSpeakDone?.call();
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      _setState(VoiceState.idle);
      onSpeakDone?.call();
    });
  }

  Future<void> speak(String text) async {
    await _applyVoiceSettings();
    _setState(VoiceState.speaking);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _setState(VoiceState.idle);
    onSpeakDone?.call();
  }

  Future<bool> startListening(Function(String) onResult, {int pauseForSeconds = 5}) async {
    var permissionStatus = await Permission.microphone.request();
    if (permissionStatus != PermissionStatus.granted) {
      return false;
    }

    bool available = await _speechToText.initialize(
      onStatus: (status) {
        debugPrint('STT status: $status');
        if (status == 'done' || status == 'notListening') {
          if (_isListeningSessionActive) {
            _isListeningSessionActive = false;
            _setState(VoiceState.idle);
            onListeningDone?.call();
          }
        }
      },
      onError: (errorNotification) {
        debugPrint('STT error: $errorNotification');
        if (_isListeningSessionActive) {
          _isListeningSessionActive = false;
          _setState(VoiceState.idle);
          onListeningDone?.call();
        }
      },
    );

    if (available) {
      _isListeningSessionActive = true;
      _setState(VoiceState.listening);
      _speechToText.listen(
        onResult: (val) {
          onResult(val.recognizedWords);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: Duration(seconds: pauseForSeconds),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
        ),
      );
      return true;
    }
    return false;
  }

  Future<void> stopListening() async {
    _isListeningSessionActive = false;
    await _speechToText.stop();
    _setState(VoiceState.idle);
  }
}
