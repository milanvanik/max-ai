import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class FactExtractor {
  static final Dio _dio = Dio();
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  /// Extracts permanent biographical facts from a conversation window.
  /// [history] should be a list of recent messages in [{role, content}] format.
  static Future<List<String>> extractFacts(List<Map<String, String>> history) async {
    if (history.isEmpty) return [];

    final String conversationText = history
        .map((m) => '${m['role'] == 'user' ? 'User' : 'Max'}: ${m['content']}')
        .join('\n');

    if (conversationText.trim().length < 5) return [];

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
          'model': Constants.groqModel,
          'messages': [
            {
              'role': 'system',
              'content': '''You are a strict biographical fact extraction engine.

RULES (follow exactly):
1. Extract ONLY permanent facts the user explicitly stated: Name, Age, Profession, Location, Preferences, Family, Goals.
2. Literal-only: extract ONLY what was clearly and directly stated. Do NOT infer, assume, or interpret beyond the exact words.
3. Type-validation gate: if the value does not match the category (e.g. a car brand given as a color, a color given as a car model), discard that field entirely — return nothing for it.
4. If a fact is nonsensical or semantically incoherent, return []. Silence is always better than a wrong or guessed fact.
5. Do NOT extract transient requests (e.g. "User wants coffee", "User is asking about weather").
6. Convert to 3rd person: "I love chess" → "User loves chess".
7. Return ONLY a raw JSON array of strings, e.g. ["User is a pilot", "User loves chess"]. Return [] if nothing qualifies. No markdown, no explanation.'''
            },
            {
              'role': 'user',
              'content': conversationText,
            }
          ],
          'temperature': 0.0,
        },
      );

      if (response.statusCode == 200) {
        final String aiResponse = response.data['choices'][0]['message']['content'];
        try {
          final String clean = aiResponse.replaceAll('```json', '').replaceAll('```', '').trim();
          final List<dynamic> parsed = jsonDecode(clean);
          return parsed.cast<String>();
        } catch (e) {
          debugPrint('FactExtractor JSON Parse Error: $e | Raw: $aiResponse');
          return [];
        }
      }
    } catch (e) {
      debugPrint('FactExtractor API Exception: $e');
    }

    return [];
  }
}
