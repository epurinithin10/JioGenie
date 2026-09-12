import 'citation.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  String content;
  List<Citation> citations;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    List<Citation>? citations,
    DateTime? timestamp,
  })  : citations = citations ?? [],
        timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    var rawCitations = json['citations'] as List<dynamic>? ?? [];
    List<Citation> parsedCitations = rawCitations
        .map((c) => Citation.fromJson(c as Map<String, dynamic>))
        .toList();

    return ChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      citations: parsedCitations,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'citations': citations.map((c) => c.toJson()).toList(),
    'timestamp': timestamp.toIso8601String(),
  };
}
