import 'message.dart';

class ChatThread {
  final String id;
  String title;
  final List<ChatMessage> messages;
  final DateTime lastUpdatedAt;

  ChatThread({
    required this.id,
    required this.title,
    required this.messages,
    required this.lastUpdatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toMap()).toList(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  factory ChatThread.fromMap(Map<String, dynamic> map) {
    return ChatThread(
      id: map['id'],
      title: map['title'],
      messages: (map['messages'] as List)
          .map((m) => ChatMessage.fromMap(m))
          .toList(),
      lastUpdatedAt: DateTime.parse(map['lastUpdatedAt']),
    );
  }
}
