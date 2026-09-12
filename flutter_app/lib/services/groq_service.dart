import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_settings.dart';

class GroqService {
  http.Client? _activeClient;
  bool _isCancelled = false;

  void cancel() {
    _isCancelled = true;
    _activeClient?.close();
    _activeClient = null;
  }

  Stream<String> streamChat({
    required String query,
    required String systemPrompt,
    required AppSettings settings,
  }) async* {
    _isCancelled = false;

    if (settings.provider == 'mock') {
      yield* _streamMock(query);
      return;
    }

    final apiKey = settings.apiKey.trim();
    if (apiKey.isEmpty) {
      throw Exception('Groq API Key missing. Please open Settings and enter your API key.');
    }

    _activeClient = http.Client();

    final request = http.Request(
      'POST',
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
    );

    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    });

    request.body = json.encode({
      'model': 'openai/gpt-oss-120b',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': query}
      ],
      'temperature': settings.temperature,
      'stream': true,
    });

    http.StreamedResponse response;
    try {
      response = await _activeClient!.send(request);
    } catch (e) {
      if (_isCancelled) return;
      rethrow;
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Groq returned HTTP ${response.statusCode}: $body');
    }

    final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in stream) {
      if (_isCancelled) break;
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('data: ')) continue;
      final dataStr = trimmed.substring(6).trim();
      if (dataStr == '[DONE]') break;

      try {
        final decoded = json.decode(dataStr) as Map<String, dynamic>;
        final choices = decoded['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final delta = choices[0]['delta'] as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            yield content;
          }
        }
      } catch (_) {
        // Skip malformed chunk
      }
    }
  }

  Stream<String> _streamMock(String query) async* {
    final mockAnswer =
        '### ⚡ JioGenie Offline Smart Assistant\n\n'
        'You asked about: **$query**.\n\n'
        'To access real-time live answers with verified data from https://www.jio.com/, '
        'switch the active engine to **Groq Cloud LPU + Jio.com RAG** in Settings ⚙️ and ensure your Groq API key is set!';

    final words = mockAnswer.split(' ');
    for (final word in words) {
      if (_isCancelled) break;
      yield '$word ';
      await Future.delayed(const Duration(milliseconds: 35));
    }
  }
}
