import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/voice_service.dart';
import '../../utils/theme.dart';
import 'neural_core.dart';

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
    _voiceService.stop();
    _currentRecognizedWords = '';
    _voiceService.startListening((text) {
      if (mounted) {
        setState(() {
          _currentRecognizedWords = text;
        });
      }
    }, pauseForSeconds: 10);
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
      height: MediaQuery.of(context).size.height * 0.85, // Even taller for immersive feel
      decoration: BoxDecoration(
        color: MaxTheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 10,
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

          GestureDetector(
            onLongPressStart: (_) => _onLongPressStart(),
            onLongPressEnd: (_) => _onLongPressEnd(),
            onTap: () {
              if (state == VoiceState.speaking) {
                _voiceService.stop();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              padding: const EdgeInsets.all(24),
              decoration: MaxTheme.glassDecoration.copyWith(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: state == VoiceState.listening ? MaxTheme.accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: state == VoiceState.listening
                    ? [
                        BoxShadow(
                          color: MaxTheme.accent.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MaxNeuralCore(
                    state: state == VoiceState.listening
                        ? CoreState.listening
                        : state == VoiceState.speaking
                            ? CoreState.speaking
                            : CoreState.idle,
                    size: 140,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    state == VoiceState.listening ? 'RECORDING' : 'HOLD TO TALK',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: state == VoiceState.listening
                          ? MaxTheme.accent
                          : MaxTheme.secondary,
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
