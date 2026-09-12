class KnowledgeDoc {
  final String id;
  final String title;
  final String category;
  final String url;
  final List<String> keywords;
  final String content;

  KnowledgeDoc({
    required this.id,
    required this.title,
    required this.category,
    required this.url,
    required this.keywords,
    required this.content,
  });

  factory KnowledgeDoc.fromJson(Map<String, dynamic> json) {
    var rawKeywords = json['keywords'] as List<dynamic>? ?? [];
    List<String> parsedKeywords = rawKeywords.map((k) => k.toString()).toList();

    return KnowledgeDoc(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      url: json['url'] as String? ?? '',
      keywords: parsedKeywords,
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'url': url,
    'keywords': keywords,
    'content': content,
  };
}
