import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class GroqService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  List<Map<String, dynamic>> _messages = [];

  final String _systemPrompt;

  static const List<Map<String, dynamic>> _toolDefinitions = [
    {
      "type": "function",
      "function": {
        "name": "get_current_weather",
        "description": "Get the current weather in a given location",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {
              "type": "string",
              "description": "The city and state, e.g. San Francisco, CA",
            },
          },
          "required": ["location"],
        },
      },
    },
    {
      "type": "function",
      "function": {
        "name": "web_search",
        "description": "Search the live internet for up-to-date information, news, or specific facts",
        "parameters": {
          "type": "object",
          "properties": {
            "query": {
              "type": "string",
              "description": "The search query",
            },
          },
          "required": ["query"],
        },
      },
    },
    {
      "type": "function",
      "function": {
        "name": "get_current_time",
        "description": "Get the current date and time on the user's system",
        "parameters": {
          "type": "object",
          "properties": {},
          "required": [],
          "additionalProperties": false,
        },
      },
    },
  ];

  GroqService({required String systemPrompt, List<Map<String, dynamic>>? history}) 
    : _systemPrompt = systemPrompt {
    _messages.add({
      'role': 'system',
      'content': systemPrompt,
    });
    
    if (history != null) {
      _messages.addAll(history);
    }
  }

  void resetChat() {
    _messages = [
      {'role': 'system', 'content': _systemPrompt}
    ];
  }

  void addLocalMessage(String text, String role) {
    _messages.add({
      'role': role,
      'content': text,
    });
  }

  Future<dynamic> sendMessage(String text) async {
    try {
      if (text.isNotEmpty) {
        _messages.add({
          'role': 'user',
          'content': text,
        });
      }
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${Constants.groqApiKey}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko)',
          },
        ),
        data: {
          'model': Constants.groqModel,
          'messages': _messages,
          'temperature': 0.4,
          'tools': _toolDefinitions,
          'tool_choice': 'auto',
          'parallel_tool_calls': false,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final message = data['choices'][0]['message'];
        
        final Map<String, dynamic> sanitizedMessage = {
          'role': 'assistant',
          'content': message['content'],
        };
        
        if (message['tool_calls'] != null) {
          sanitizedMessage['tool_calls'] = (message['tool_calls'] as List).map((tc) => {
            'id': tc['id'],
            'type': tc['type'],
            'function': tc['function'],
          }).toList();
          _messages.add(sanitizedMessage);
          return sanitizedMessage;
        }

        sanitizedMessage['content'] = sanitizedMessage['content'] ?? "";
        _messages.add(sanitizedMessage);
        return sanitizedMessage['content'];
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 429) {
          return '__RATE_LIMIT_ERROR__';
        }
        if (e.response?.statusCode == 400) {
          final errorBody = e.response?.data;
          final errorMsg = (errorBody is Map) 
              ? (errorBody['error']?['message'] ?? errorBody.toString())
              : errorBody.toString();
          debugPrint('Groq 400 Error → $errorMsg');
        }
      }
      debugPrint('Groq API Exception: $e');
      return null;
    }
  }

  Future<dynamic> submitToolResults(List<Map<String, dynamic>> results) async {
    for (var res in results) {
      _messages.add({
        "role": "tool",
        "tool_call_id": res['id'],
        "name": res['name'],
        "content": res['result'],
      });
    }
    
    return sendMessage(""); 
  }
}
