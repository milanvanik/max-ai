import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/constants.dart';

class GeminiService {
  /// The model string for the Generative AI SDK.
  /// Change this constant and do a FULL RESTART (not Hot Reload) to pick up.
  static const String _modelName = 'gemini-2.0-flash';

  late GenerativeModel _model;
  late ChatSession _chatSession;

  final List<Tool> _tools = [
    Tool(functionDeclarations: [
      FunctionDeclaration(
        'get_current_weather',
        'Get the current weather in a given location',
        Schema.object(
          properties: {
            'location': Schema.string(description: 'The city and state, e.g. San Francisco, CA'),
          },
          requiredProperties: ['location'],
        ),
      ),
      FunctionDeclaration(
        'web_search',
        'Search the live internet for up-to-date information, news, or specific facts',
        Schema.object(
          properties: {
            'query': Schema.string(description: 'The search query'),
          },
          requiredProperties: ['query'],
        ),
      ),
      FunctionDeclaration(
        'get_current_time',
        "Get the current date and time on the user's system",
        Schema.object(properties: {}),
      ),
    ])
  ];

  GeminiService({required String systemPrompt}) {
    // Model is created inside the constructor body — NOT as a field initializer.
    // This guarantees a fresh model string on every instantiation,
    // defeating the Hot Reload singleton problem.
    _model = GenerativeModel(
      model: _modelName,
      apiKey: Constants.geminiApiKey,
      systemInstruction: Content.system(systemPrompt),
      tools: _tools,
    );
    _chatSession = _model.startChat();
    debugPrint('[GeminiService] Initialized with model: $_modelName');
  }

  void resetChat() {
    _chatSession = _model.startChat();
  }

  // Sync historical messages for the vision request context
  void setHistory(List<Content> history) {
    _chatSession = _model.startChat(history: history);
  }

  Future<dynamic> sendMessage(String text, {List<String>? base64Images}) async {
    try {
      final List<Part> parts = [TextPart(text)];

      if (base64Images != null) {
        for (final img in base64Images) {
          final imageBytes = base64Decode(img);
          parts.add(DataPart('image/jpeg', imageBytes));
        }
      }

      final response = await _chatSession.sendMessage(Content.multi(parts));
      
      // Check for function calls
      final functionCalls = response.functionCalls.toList();
      if (functionCalls.isNotEmpty) {
        return response; // Return the full response for ChatProvider to process
      }

      return response.text;
    } catch (e) {
      if (e.toString().contains('429') || e.toString().contains('Quota exceeded')) {
        return '__RATE_LIMIT_ERROR__';
      }
      debugPrint('Gemini API Error: $e');
      return null;
    }
  }

  /// Submits the results of function calls back to Gemini
  Future<dynamic> submitFunctionResults(List<FunctionResponse> results) async {
    final response = await _chatSession.sendMessage(
      Content.functionResponses(results),
    );
    
    // The response after a function result might be another function call or the final text
    final functionCalls = response.functionCalls.toList();
    if (functionCalls.isNotEmpty) {
      return response;
    }
    return response.text;
  }
}
