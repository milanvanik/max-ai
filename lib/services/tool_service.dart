import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class ToolService {
  static final Dio _dio = Dio();

  /// Fetches real-time weather from OpenWeatherMap
  static Future<String> getCurrentWeather(String location) async {
    try {
      final apiKey = Constants.openWeatherApiKey;
      if (apiKey.isEmpty) return "Error: OpenWeather API key is missing.";

      final response = await _dio.get(
        'https://api.openweathermap.org/data/2.5/weather',
        queryParameters: {'q': location, 'appid': apiKey, 'units': 'metric'},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final temp = data['main']['temp'];
        final description = data['weather'][0]['description'];
        final city = data['name'];
        return "The current weather in $city is $temp°C with $description.";
      }
      return "Error: Could not find weather for $location.";
    } catch (e) {
      debugPrint("Weather Tool Error: $e");
      return "Error: Failed to fetch weather data.";
    }
  }

  /// Searches the web via Tavily AI Search
  static Future<String> webSearch(String query) async {
    try {
      final apiKey = Constants.tavilyApiKey;
      if (apiKey.isEmpty) return "Error: Tavily API key is missing.";

      final response = await _dio.post(
        'https://api.tavily.com/search',
        data: {
          'api_key': apiKey,
          'query': query,
          'search_depth': 'basic',
          'include_answer': true,
          'max_results': 3,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final String? directAnswer = data['answer'];
        final List<dynamic> results = data['results'] ?? [];

        if (directAnswer != null && directAnswer.isNotEmpty) {
          return "Search Result: $directAnswer";
        }

        if (results.isNotEmpty) {
          final snippets = results
              .map((r) => "- ${r['title']}: ${r['content']}")
              .join("\n");
          return "Search Results:\n$snippets";
        }
      }
      return "No search results found for '$query'.";
    } catch (e) {
      debugPrint("Search Tool Error: $e");
      return "Error: Web search failed.";
    }
  }

  /// Returns the current system date and time
  static String getCurrentTime() {
    final now = DateTime.now();
    return "The current date and time is ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}.";
  }
}
