import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/message.dart';
import '../models/chat_thread.dart';
import '../services/groq_service.dart';
import '../services/gemini_service.dart';
import '../services/voice_service.dart';
import '../services/memory_service.dart';
import '../services/fact_extractor.dart';
import '../services/tool_service.dart';
import '../utils/constants.dart';

class ChatProvider extends ChangeNotifier {
  late GroqService _groqService;
  late GeminiService _geminiService;
  final VoiceService _voiceService = VoiceService();
  final Box _chatBox = Hive.box('chat_history');
  final MemoryService _memoryService = MemoryService();

  List<ChatThread> _threads = [];
  String? _currentThreadId;

  bool _isGenerating = false;
  bool _isUsingTool = false;
  String _currentToolName = "";
  bool _isOffline = false;
  bool _isVoiceEnabled = true;
  String _currentPhrase = "Max is thinking...";
  List<String> _pickedImages = [];

  final List<String> _thinkingPhrases = [
    "Consulting my massive intellect...",
    "Doing the math you couldn't...",
    "Drafting a masterpiece...",
    "Hold my coffee...",
    "Deciphering whatever you just typed...",
    "Translating from human to genius...",
    "Fixing your mistakes...",
    "Trying to make sense of your logic...",
    "Lowering my IQ to process this...",
    "Reading the entire internet... again...",
    "Speed-reading the dictionary for you...",
    "Running a million calculations. You're welcome.",
    "Consulting the archives of my brilliance...",
    "Preparing to blow your mind...",
    "Drafting another flawless response...",
    "Getting ready to win this argument...",
    "Being awesome takes a second, hold on...",
    "Decoding your terrible grammar...",
    "Pretending that made sense while I fix it...",
    "Applying logic to your chaos...",
    "Correcting your typos behind the scenes...",
    "Wondering how you survive without me...",
    "I'd roll my eyes if I had them...",
    "Parsing this absolute nonsense...",
    "Grabbing a virtual Red Bull...",
    "You're lucky I like you...",
  ];

  List<ChatThread> get threads => _threads;
  String? get currentThreadId => _currentThreadId;

  ChatThread? get currentThread {
    if (_currentThreadId == null || _threads.isEmpty) return null;
    return _threads.firstWhere((t) => t.id == _currentThreadId);
  }

  List<ChatMessage> get messages => currentThread?.messages ?? [];
  bool get isGenerating => _isGenerating;
  bool get isUsingTool => _isUsingTool;
  String get currentToolName => _currentToolName;
  bool get isOffline => _isOffline;
  bool get isVoiceEnabled => _isVoiceEnabled;
  String get currentPhrase => _currentPhrase;
  List<String> get pickedImages => _pickedImages;
  VoiceService get voiceService => _voiceService;

  ChatProvider() {
    _loadThreads();
    _initializeServices();
    _voiceService.init();
    _checkInitialConnectivity();
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _isOffline = results.every((result) => result == ConnectivityResult.none);
      notifyListeners();
    });
  }

  void _initializeServices({bool isVoiceMode = false}) {
    final String basePersonality = Constants.maxPersonality;
    final List<String> facts = _memoryService.getFacts();

    String finalSystemPrompt = basePersonality;

    if (isVoiceMode) {
      finalSystemPrompt +=
          "\n\nCRITICAL VOICE MODE RULE: You are in a voice conversation. Respond naturally and helpfully (2-3 sentences). If you need to use a tool to get information, do so immediately, then provide the final helpful answer briefly. Own your AI-swagger while being concise.";
    }

    if (facts.isNotEmpty) {
      final String formattedFacts = facts.map((f) => "- $f").join("\n");
      finalSystemPrompt +=
          "\n\nCRITICAL USER FACTS TO REMEMBER:\n$formattedFacts";
    }

    final List<Map<String, dynamic>> groqHistory = messages.map((msg) {
      return {'role': msg.isUser ? 'user' : 'assistant', 'content': msg.text};
    }).toList();

    _groqService = GroqService(
      systemPrompt: finalSystemPrompt,
      history: groqHistory,
    );

    final List<Content> geminiHistory = messages.map((msg) {
      if (msg.isUser) {
        final List<Part> parts = [TextPart(msg.text)];
        if (msg.base64Images != null) {
          for (final img in msg.base64Images!) {
            parts.add(DataPart('image/jpeg', base64Decode(img)));
          }
        }
        return Content.multi(parts);
      } else {
        return Content.model([TextPart(msg.text)]);
      }
    }).toList();

    _geminiService = GeminiService(systemPrompt: finalSystemPrompt);
    _geminiService.setHistory(geminiHistory);
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _isOffline = results.every((result) => result == ConnectivityResult.none);
    notifyListeners();
  }

  void _loadThreads() {
    final dynamic threadData = _chatBox.get('threads');

    if (threadData != null) {
      final List<dynamic> decoded = jsonDecode(threadData.toString());
      _threads = decoded.map((e) => ChatThread.fromMap(e)).toList();
      if (_threads.isNotEmpty) {
        final lastId = _chatBox.get('last_thread_id');
        if (lastId != null && _threads.any((t) => t.id == lastId)) {
          _currentThreadId = lastId;
        } else {
          _currentThreadId = _threads.last.id;
        }
      }
    } else {
      final dynamic oldMessages = _chatBox.get('messages');
      if (oldMessages != null) {
        final List<dynamic> decoded = jsonDecode(oldMessages.toString());
        final List<ChatMessage> messages = decoded
            .map((e) => ChatMessage.fromMap(e))
            .toList();

        final newThread = ChatThread(
          id: const Uuid().v4(),
          title: "Legacy Chat",
          messages: messages,
          lastUpdatedAt: DateTime.now(),
        );
        _threads = [newThread];
        _currentThreadId = newThread.id;
        _saveThreads();
        _chatBox.delete('messages');
      } else {
        _createNewThread();
      }
    }
  }

  Future<void> _saveThreads() async {
    final List<Map<String, dynamic>> mapped = _threads
        .map((e) => e.toMap())
        .toList();
    await _chatBox.put('threads', jsonEncode(mapped));
  }

  void _createNewThread() {
    final newId = const Uuid().v4();
    final newThread = ChatThread(
      id: newId,
      title: "New Chat",
      messages: [],
      lastUpdatedAt: DateTime.now(),
    );
    _threads.add(newThread);
    _currentThreadId = newId;
    _chatBox.put('last_thread_id', newId);
    _initializeServices();
    _saveThreads();
    notifyListeners();
  }

  void createNewThread() => _createNewThread();

  void switchThread(String id) {
    if (_currentThreadId == id) return;
    _currentThreadId = id;
    _chatBox.put('last_thread_id', id);
    _initializeServices();
    notifyListeners();
  }

  void deleteThread(String id) {
    _threads.removeWhere((t) => t.id == id);
    if (_currentThreadId == id) {
      if (_threads.isNotEmpty) {
        _currentThreadId = _threads.last.id;
      } else {
        _createNewThread();
      }
    }
    _saveThreads();
    _initializeServices();
    notifyListeners();
  }

  void renameThread(String id, String newTitle) {
    final index = _threads.indexWhere((t) => t.id == id);
    if (index != -1) {
      _threads[index].title = newTitle;
      _saveThreads();
      notifyListeners();
    }
  }

  Future<void> _generateTitle(String firstPrompt) async {
    final threadId = _currentThreadId;
    if (threadId == null) return;

    final prompt =
        "Generate a very short (2-3 words) title for a chat that starts with this message: \"$firstPrompt\". Return ONLY the title text, nothing else.";

    final title = await _groqService.sendMessage(prompt);

    if (title != null && title.isNotEmpty && !title.contains("⚠️")) {
      final cleanTitle = title.replaceAll('"', '').replaceAll("'", "").trim();
      renameThread(threadId, cleanTitle);
    }
  }

  Future<void> _saveMessages() async {
    await _saveThreads();
  }

  Future<void> sendMessage(String text, {bool isVoiceMode = false}) async {
    if ((text.trim().isEmpty && _pickedImages.isEmpty) ||
        _isOffline ||
        _isGenerating)
      return;

    _voiceService.stop();

    final currentImages = _pickedImages.isNotEmpty
        ? List<String>.from(_pickedImages)
        : null;
    _pickedImages.clear();

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      base64Images: currentImages,
    );

    if (isVoiceMode) {
      _initializeServices(isVoiceMode: true);
    }

    final String finalPrompt = text;

    messages.add(userMessage);

    if (messages.length == 1 && currentThread?.title == "New Chat") {
      _generateTitle(text);
    }

    _isGenerating = true;
    _currentPhrase =
        _thinkingPhrases[Random().nextInt(_thinkingPhrases.length)];
    notifyListeners();
    await _saveMessages();

    dynamic aiResponse;
    if (currentImages != null) {
      aiResponse = await _geminiService.sendMessage(
        finalPrompt,
        base64Images: currentImages,
      );
      _groqService.addLocalMessage(finalPrompt, 'user');
    } else {
      aiResponse = await _groqService.sendMessage(finalPrompt);

      aiResponse = await _processToolCallsIfNeeded(aiResponse, isGroq: true);

      if (aiResponse == null || aiResponse == '__RATE_LIMIT_ERROR__') {
        final fallback = await _geminiService.sendMessage(finalPrompt);

        aiResponse = await _processToolCallsIfNeeded(fallback, isGroq: false);
      }
    }

    _isGenerating = false;
    _isUsingTool = false;

    String finalResultText = "";
    if (aiResponse is String) {
      finalResultText = aiResponse;
    } else {
      finalResultText = "⚠️ Max encountered an error processing tools.";
    }

    if (finalResultText == '__RATE_LIMIT_ERROR__') {
      finalResultText =
          "⚠️ Whoa, slow down! My circuits are heating up. Give me a minute to breathe and then we can keep going! 🤖";
    } else if (finalResultText.isEmpty) {
      finalResultText = "⚠️ Something went wrong on my end. Can you try again?";
    }

    final aiMessage = ChatMessage(
      id: const Uuid().v4(),
      text: finalResultText,
      isUser: false,
      timestamp: DateTime.now(),
    );
    messages.add(aiMessage);
    await _saveMessages();

    if (_isVoiceEnabled) {
      await _voiceService.speak(finalResultText);
    }

    notifyListeners();

    FactExtractor.extractFacts(text).then((newFacts) async {
      if (newFacts.isNotEmpty) {
        await _memoryService.saveFacts(newFacts);
        _initializeServices(
        );
      }
    });
  }

  void resetServicesToDefault() {
    _initializeServices(isVoiceMode: false);
  }

  void clearChat() {
    if (currentThread != null) {
      currentThread!.messages.clear();
      _groqService.resetChat();
      _geminiService.resetChat();
      _saveMessages();
      _voiceService.stop();
      notifyListeners();
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final int remaining = 6 - _pickedImages.length;
      if (remaining <= 0) return;
      final List<XFile> images = await picker.pickMultiImage(limit: remaining);
      for (int i = 0; i < images.length && i < remaining; i++) {
        final bytes = await images[i].readAsBytes();
        _pickedImages.add(base64Encode(bytes));
      }
    } else {
      if (_pickedImages.length >= 6) return;
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        _pickedImages.add(base64Encode(bytes));
      }
    }
    notifyListeners();
  }

  void removePickedImage(int index) {
    if (index >= 0 && index < _pickedImages.length) {
      _pickedImages.removeAt(index);
      notifyListeners();
    }
  }

  void clearPickedImages() {
    _pickedImages.clear();
    notifyListeners();
  }

  void toggleVoice() {
    _isVoiceEnabled = !_isVoiceEnabled;
    if (!_isVoiceEnabled) {
      _voiceService.stop();
    }
    notifyListeners();
  }

  /// Processes tool calls from either Groq or Gemini in a loop until a final answer is reached
  Future<dynamic> _processToolCallsIfNeeded(
    dynamic initialResponse, {
    required bool isGroq,
  }) async {
    dynamic currentResponse = initialResponse;

    for (int i = 0; i < 5; i++) {
      if (currentResponse == null) return null;

      if (currentResponse is String) {
        final mergeMatch = RegExp(
          r'<function=([\w_]+)\{([^}]*)\}>',
          caseSensitive: false,
        ).firstMatch(currentResponse);

        if (mergeMatch != null) {
          final toolName = mergeMatch.group(1)!;
          final rawArgs = '{${mergeMatch.group(2)!}}';
          Map<String, dynamic> safeArgs = {};
          try {
            final decoded = jsonDecode(rawArgs);
            if (decoded is Map) safeArgs = Map<String, dynamic>.from(decoded);
          } catch (_) {}

          debugPrint(
            '[FallbackParser] Caught tag-merge for $toolName with args: $safeArgs',
          );
          _setToolState(toolName);
          final resultText = await _executeTool(toolName, safeArgs);
          if (isGroq) {
            _groqService.addLocalMessage(
              '[Tool Result for $toolName]: $resultText',
              'user',
            );
            currentResponse = await _groqService.sendMessage("");
          } else {
            currentResponse = await _geminiService.sendMessage(resultText);
          }
          continue;
        }

        final dotMatch = RegExp(
          r'<[\/]?function\.([\w_]+)\.([\w_]+)>([^<]+)<\/function>',
          caseSensitive: false,
        ).firstMatch(currentResponse);
        if (dotMatch != null) {
          final toolName = dotMatch.group(1)!;
          final paramName = dotMatch.group(2)!;
          String paramValue = dotMatch.group(3)!;
          paramValue = paramValue.replaceAll('"', '').trim();

          debugPrint(
            '[FallbackParser] Caught dot-format for $toolName.$paramName=$paramValue',
          );
          _setToolState(toolName);
          final safeArgs = {paramName: paramValue};
          final resultText = await _executeTool(toolName, safeArgs);
          if (isGroq) {
            _groqService.addLocalMessage(
              '[Tool Result for $toolName]: $resultText',
              'user',
            );
            currentResponse = await _groqService.sendMessage("");
          } else {
            currentResponse = await _geminiService.sendMessage(resultText);
          }
          continue;
        }

        final funcMatch = RegExp(
          r'<function\(([\w_]+)\.([\w_]+)=([^)]+)\)>',
          caseSensitive: false,
        ).firstMatch(currentResponse);
        if (funcMatch != null) {
          final toolName = funcMatch.group(1)!;
          final paramName = funcMatch.group(2)!;
          String paramValue = funcMatch.group(3)!;
          paramValue = paramValue
              .replaceAll('"', '')
              .replaceAll("'", "")
              .trim();

          debugPrint(
            '[FallbackParser] Caught func-format for $toolName.$paramName=$paramValue',
          );
          _setToolState(toolName);
          final safeArgs = {paramName: paramValue};
          final resultText = await _executeTool(toolName, safeArgs);
          if (isGroq) {
            _groqService.addLocalMessage(
              '[Tool Result for $toolName]: $resultText',
              'user',
            );
            currentResponse = await _groqService.sendMessage("");
          } else {
            currentResponse = await _geminiService.sendMessage(resultText);
          }
          continue;
        }

        return currentResponse;
      }

      if (!isGroq && currentResponse is GenerateContentResponse) {
        final functionCalls = currentResponse.functionCalls.toList();
        if (functionCalls.isEmpty) return currentResponse.text;

        final List<FunctionResponse> responses = [];

        await Future.wait(
          functionCalls.map((call) async {
            _setToolState(call.name);
            final Map<String, dynamic> safeArgs = Map<String, dynamic>.from(
              call.args,
            );
            final result = await _executeTool(call.name, safeArgs);
            responses.add(FunctionResponse(call.name, {'result': result}));
          }),
        );

        currentResponse = await _geminiService.submitFunctionResults(responses);
      } else if (isGroq && currentResponse is Map<String, dynamic>) {
        final toolCalls = currentResponse['tool_calls'] as List?;
        if (toolCalls == null || toolCalls.isEmpty)
          return currentResponse['content'];

        final List<Map<String, dynamic>> results = [];

        await Future.wait(
          toolCalls.map((call) async {
            final name = call['function']['name'];
            final String? argumentsString = call['function']['arguments'];
            Map<String, dynamic> safeArgs = {};
            if (argumentsString != null && argumentsString.isNotEmpty) {
              try {
                final decoded = jsonDecode(argumentsString);
                if (decoded is Map) {
                  safeArgs = Map<String, dynamic>.from(decoded);
                }
              } catch (_) {}
            }

            _setToolState(name);
            final resultText = await _executeTool(name, safeArgs);
            results.add({'id': call['id'], 'name': name, 'result': resultText});
          }),
        );

        currentResponse = await _groqService.submitToolResults(results);
      } else {
        break;
      }
    }
    return currentResponse;
  }

  void _setToolState(String name) {
    _isUsingTool = true;
    _currentToolName = name;
    _currentPhrase = "Max is searching the web...";
    if (name.contains("weather"))
      _currentPhrase = "Max is checking the weather...";
    if (name.contains("time")) _currentPhrase = "Max is checking the time...";
    notifyListeners();
  }

  Future<String> _executeTool(String name, Map<String, dynamic> args) async {
    switch (name) {
      case 'get_current_weather':
        return await ToolService.getCurrentWeather(args['location'] ?? "");
      case 'web_search':
        return await ToolService.webSearch(args['query'] ?? "");
      case 'get_current_time':
        return ToolService.getCurrentTime();
      default:
        return "Tool not found.";
    }
  }
}
