import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../utils/constants.dart';

class MemoryService {
  final Box _memoryBox = Hive.box('user_memory');
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  List<String> getFacts() {
    final dynamic facts = _memoryBox.get('facts', defaultValue: <String>[]);
    if (facts is List) {
      return facts.cast<String>().toList();
    }
    return [];
  }

  /// Merges [newFacts] into the existing fact list using an LLM to resolve conflicts.
  /// If an incoming fact contradicts or supersedes an existing one (same topic), the new one wins.
  Future<void> saveFacts(List<String> newFacts) async {
    if (newFacts.isEmpty) return;

    final List<String> currentFacts = getFacts();
    if (currentFacts.isEmpty) {
      await _memoryBox.put('facts', newFacts);
      return;
    }

    final merged = await _resolveAndMerge(currentFacts, newFacts);
    await _memoryBox.put('facts', merged);
  }

  Future<List<String>> _resolveAndMerge(
    List<String> existing,
    List<String> incoming,
  ) async {
    final String existingStr = existing.map((f) => '- $f').join('\n');
    final String incomingStr = incoming.map((f) => '- $f').join('\n');

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
              'content': '''You are a fact list curator. You will be given two lists of biographical facts about a user.

RULES:
1. Merge both lists into one unified, deduplicated list.
2. If an INCOMING fact contradicts or updates an EXISTING fact on the same topic, keep ONLY the incoming (newer) fact and discard the old one.
3. If both are on different topics, keep both.
4. Never invent new facts. Never modify the wording of facts beyond merging.
5. Return ONLY a raw JSON array of strings. No markdown, no explanation.'''
            },
            {
              'role': 'user',
              'content': 'EXISTING FACTS:\n$existingStr\n\nINCOMING NEW FACTS:\n$incomingStr',
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
          debugPrint('MemoryService merge parse error: $e');
        }
      }
    } catch (e) {
      debugPrint('MemoryService merge API error: $e');
    }

    // Fallback: naive append without duplicates
    final merged = List<String>.from(existing);
    for (final fact in incoming) {
      if (!merged.contains(fact)) merged.add(fact);
    }
    return merged;
  }

  Future<void> saveFullFactList(List<String> facts) async {
    await _memoryBox.put('facts', facts);
  }

  Future<void> clearAllFacts() async {
    await _memoryBox.clear();
  }
}
