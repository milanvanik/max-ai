import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class FactExtractor {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<List<String>> extractFacts(String message) async {
    final triggerWords = ["i", "my", "i am", "i'm", "mine", "remember", "prefer", "like", "love", "hate"];
    final lowerMessage = message.toLowerCase();
    
    bool containsTrigger = false;
    for (final word in triggerWords) {
      if (RegExp(r'\b' + word + r'\b').hasMatch(lowerMessage)) {
        containsTrigger = true;
        break;
      }
    }

    if (!containsTrigger || message.length < 5) {
      return [];
    }

    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${Constants.groqApiKey}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: {
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a fact extraction engine. Extract strictly personal, permanent, or important facts about the user from the following message. Convert pronouns to third person (e.g., "I like apples" -> "User likes apples"). Return ONLY a raw JSON array of strings representing the facts, e.g., ["User likes apples", "User lives in New York"]. If no clear personal facts are found, return exactly []. Do not include markdown formatting or markdown code blocks like ```json.'
            },
            {
              'role': 'user',
              'content': message,
            }
          ],
          'temperature': 0.0,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final String aiResponse = data['choices'][0]['message']['content'];
        
        try {
          String cleanJson = aiResponse.replaceAll('```json', '').replaceAll('```', '').trim();
          final List<dynamic> parsed = jsonDecode(cleanJson);
          return parsed.cast<String>();
        } catch (e) {
          debugPrint('FactExtractor JSON Parsing Error: $e');
          debugPrint('Raw response was: $aiResponse');
          return [];
        }
      }
    } catch (e) {
      debugPrint('FactExtractor API Exception: $e');
    }
    
    return [];
  }
}
