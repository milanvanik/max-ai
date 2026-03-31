import 'package:hive/hive.dart';

class MemoryService {
  final Box _memoryBox = Hive.box('user_memory');

  List<String> getFacts() {
    final dynamic facts = _memoryBox.get('facts', defaultValue: <String>[]);
    if (facts is List) {
      return facts.cast<String>().toList();
    }
    return [];
  }

  Future<void> saveFacts(List<String> newFacts) async {
    final List<String> currentFacts = getFacts();
    
    // Merge without duplicates
    for (final fact in newFacts) {
      if (!currentFacts.contains(fact)) {
        currentFacts.add(fact);
      }
    }

    await _memoryBox.put('facts', currentFacts);
  }

  Future<void> clearMemory() async {
    await _memoryBox.clear();
  }
}
