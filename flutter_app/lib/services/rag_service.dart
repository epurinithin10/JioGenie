import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/knowledge_doc.dart';
import '../models/citation.dart';

class RagService {
  List<KnowledgeDoc> _docs = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<KnowledgeDoc> get docs => _docs;

  static final Set<String> _stopWords = {
    "a", "about", "above", "after", "again", "against", "all", "am", "an", "and",
    "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being",
    "below", "between", "both", "but", "by", "can", "can't", "cannot", "could",
    "did", "do", "does", "doing", "don't", "down", "during", "each", "few", "for",
    "from", "further", "had", "has", "have", "having", "he", "her", "here", "hers",
    "how", "i", "if", "in", "into", "is", "it", "its", "me", "more", "most", "my",
    "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "our",
    "so", "some", "such", "than", "that", "the", "their", "them", "then", "there",
    "these", "they", "this", "those", "to", "too", "under", "until", "up", "very",
    "was", "we", "were", "what", "when", "where", "which", "while", "who", "whom",
    "why", "with", "would", "you", "your", "please", "tell", "give", "need", "want"
  };

  static final Map<String, List<String>> _synonyms = {
    "recharge": ["prepaid", "plan", "pack", "validity", "tariff", "data"],
    "broadband": ["jiofiber", "airfiber", "wifi", "router", "fiber"],
    "wifi": ["broadband", "jiofiber", "airfiber", "router"],
    "sim": ["esim", "port", "mnp", "activation"],
    "port": ["mnp", "switch", "transfer", "upc"],
    "unlimited": ["true 5g", "welcome offer", "data"],
    "care": ["customer", "helpline", "complaint", "number", "support", "198", "199"],
    "hotline": ["customer", "helpline", "complaint", "198", "199"],
    "ott": ["netflix", "prime", "hotstar", "jiocinema", "sonyliv", "zee5"],
    "roaming": ["international", "flight", "abroad", "usa", "uae"]
  };

  Future<void> loadKnowledgeBase() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/jio_knowledge.json');
      final List<dynamic> data = json.decode(jsonString);
      _docs = data.map((item) => KnowledgeDoc.fromJson(item as Map<String, dynamic>)).toList();
      _isLoaded = true;
    } catch (e) {
      _docs = [];
    }
  }

  List<KnowledgeDoc> retrieve(String query, {int topK = 4}) {
    if (_docs.isEmpty) return [];

    final cleanQuery = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s₹]'), ' ');
    final rawTokens = cleanQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1 && !_stopWords.contains(t))
        .toList();

    final queryTokens = List<String>.from(rawTokens);
    for (final tok in rawTokens) {
      if (_synonyms.containsKey(tok)) {
        queryTokens.addAll(_synonyms[tok]!);
      }
    }

    final numericMatches = RegExp(r'\b\d+\b')
        .allMatches(query)
        .map((m) => m.group(0)!)
        .toList();

    final scored = <MapEntry<KnowledgeDoc, double>>[];

    for (final doc in _docs) {
      double score = 0;
      final titleLower = doc.title.toLowerCase();
      final contentLower = doc.content.toLowerCase();
      final keywords = doc.keywords.map((k) => k.toLowerCase()).toList();
      final categoryLower = doc.category.toLowerCase();

      for (final tok in queryTokens) {
        if (titleLower.contains(tok)) score += 6.0;
        if (keywords.any((k) => k.contains(tok))) score += 4.5;
        if (categoryLower.contains(tok)) score += 3.0;
        if (contentLower.contains(tok)) {
          final count = RegExp(RegExp.escape(tok)).allMatches(contentLower).length;
          score += (count * 1.2).clamp(0.0, 6.0);
        }
      }

      for (final num in numericMatches) {
        if (titleLower.contains(num) || contentLower.contains(num)) {
          score += 8.5;
        }
      }

      if (score > 0) {
        scored.add(MapEntry(doc, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(topK).map((e) => e.key).toList();
  }

  List<Citation> getCitations(List<KnowledgeDoc> matchedDocs) {
    return matchedDocs.map((doc) => Citation(
      title: doc.title,
      url: doc.url,
      category: doc.category,
    )).toList();
  }

  String buildGroundedPrompt(String baseSystemPrompt, List<KnowledgeDoc> matchedDocs) {
    if (matchedDocs.isEmpty) {
      return baseSystemPrompt;
    }

    final contextBuffer = StringBuffer();
    contextBuffer.writeln(baseSystemPrompt);
    contextBuffer.writeln('\n\nVERIFIED JIO KNOWLEDGE CONTEXT:');

    for (var i = 0; i < matchedDocs.length; i++) {
      final d = matchedDocs[i];
      contextBuffer.writeln('[Source ${i + 1}: ${d.title} | ${d.url}]');
      contextBuffer.writeln(d.content);
      contextBuffer.writeln();
    }

    contextBuffer.writeln(
      'INSTRUCTIONS: Answer the user\'s question accurately using the verified knowledge context above. '
      'Cite plan prices (with ₹ symbol), validity, data allowances, and official URLs. If specific details are missing, clarify politely.',
    );

    return contextBuffer.toString();
  }
}
