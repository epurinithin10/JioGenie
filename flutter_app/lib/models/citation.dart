class Citation {
  final String title;
  final String url;
  final String category;

  Citation({
    required this.title,
    required this.url,
    required this.category,
  });

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'category': category,
  };
}
