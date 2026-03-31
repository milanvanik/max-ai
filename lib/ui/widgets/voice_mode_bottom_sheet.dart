import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/voice_service.dart';

class VoiceModeBottomSheet extends StatefulWidget {
  const VoiceModeBottomSheet({super.key});

  @override
  State<VoiceModeBottomSheet> createState() => _VoiceModeBottomSheetState();
}

class _VoiceModeBottomSheetState extends State<VoiceModeBottomSheet> {
  String _currentRecognizedWords = '';
  late ChatProvider _chatProvider;
  late VoiceService _voiceService;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _chatProvider = context.read<ChatProvider>();
      _voiceService = _chatProvider.voiceService;
      _isInitialized = true;
    }
  }

  void _onLongPressStart() {
    _voiceService.stop(); // Stop any current speaking
    _currentRecognizedWords = '';
    _voiceService.startListening((text) {
      if (mounted) {
        setState(() {
          _currentRecognizedWords = text;
        });
      }
    }, pauseForSeconds: 10); // Don't cut off mid-hold
  }

  void _onLongPressEnd() {
    _voiceService.stopListening();
    if (_currentRecognizedWords.isNotEmpty) {
      _chatProvider.sendMessage(_currentRecognizedWords, isVoiceMode: true);
      _currentRecognizedWords = '';
    }
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _voiceService.stop();
    _chatProvider.resetServicesToDefault();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = _voiceService;
    final chatProvider = _chatProvider;
    final state = voiceService.state;

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            state == VoiceState.listening
                ? 'Listening...'
                : state == VoiceState.speaking
                    ? 'Max is speaking'
                    : chatProvider.isGenerating
                        ? 'Thinking...'
                        : 'Hold button to speak',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Center(
                child: Text(
                  _currentRecognizedWords.isNotEmpty
                      ? '"$_currentRecognizedWords"'
                      : '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w300,
                      ),
                ),
              ),
            ),
          ),
          // LARGE PTT BUTTON AREA
          GestureDetector(
            onLongPressStart: (_) => _onLongPressStart(),
            onLongPressEnd: (_) => _onLongPressEnd(),
            onTap: () {
              if (state == VoiceState.speaking) {
                _voiceService.stop();
              }
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(24),
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: state == VoiceState.listening
                      ? [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary]
                      : [Theme.of(context).colorScheme.surfaceContainerHighest, Theme.of(context).colorScheme.surfaceContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: state == VoiceState.listening
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    state == VoiceState.listening
                        ? Icons.mic
                        : state == VoiceState.speaking
                            ? Icons.graphic_eq
                            : Icons.mic_none,
                    size: 64,
                    color: state == VoiceState.listening
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state == VoiceState.listening ? 'RECORDING' : 'HOLD TO TALK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: state == VoiceState.listening
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Exit Voice Mode',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
