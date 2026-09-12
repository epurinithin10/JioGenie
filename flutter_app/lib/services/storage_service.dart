import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _chatsKey = 'jiogenie_flutter_chats_v1';
  static const String _activeIdKey = 'jiogenie_flutter_active_id_v1';
  static const String _settingsKey = 'jiogenie_flutter_settings_v1';

  Future<List<ChatSession>> loadChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_chatsKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> list = json.decode(jsonString);
      return list.map((item) => ChatSession.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveChats(List<ChatSession> chats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(chats.map((c) => c.toJson()).toList());
      await prefs.setString(_chatsKey, jsonString);
    } catch (_) {}
  }

  Future<String?> loadActiveId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeIdKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveId(String? id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (id == null) {
        await prefs.remove(_activeIdKey);
      } else {
        await prefs.setString(_activeIdKey, id);
      }
    } catch (_) {}
  }

  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_settingsKey);
      if (jsonString == null || jsonString.isEmpty) return AppSettings();

      final map = json.decode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(map);
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(settings.toJson());
      await prefs.setString(_settingsKey, jsonString);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chatsKey);
      await prefs.remove(_activeIdKey);
    } catch (_) {}
  }
}
