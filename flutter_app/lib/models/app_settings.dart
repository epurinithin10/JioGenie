import '../constants/default_settings.dart';

class AppSettings {
  String provider; // 'groq' or 'mock'
  String apiKey;
  String systemPrompt;
  double temperature;

  AppSettings({
    this.provider = 'groq',
    String? apiKey,
    String? systemPrompt,
    this.temperature = 0.4,
  })  : apiKey = apiKey ?? DefaultSettings.builtinGroqKey,
        systemPrompt = systemPrompt ?? DefaultSettings.defaultSystemPrompt;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      provider: json['provider'] as String? ?? 'groq',
      apiKey: json['apiKey'] as String? ?? DefaultSettings.builtinGroqKey,
      systemPrompt: json['systemPrompt'] as String? ?? DefaultSettings.defaultSystemPrompt,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.4,
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'apiKey': apiKey,
    'systemPrompt': systemPrompt,
    'temperature': temperature,
  };
}
