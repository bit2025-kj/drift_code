import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafa_edu/models/quiz_model.dart';

/// Stockage local de l'historique des quiz via SharedPreferences.
/// Conserve les questions + réponses pour la révision hors ligne.
class QuizHistoryStorage {
  static const _key = 'quiz_history_v1';
  static const _maxEntries = 50;

  static Future<List<QuizHistoryEntry>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.map((j) => QuizHistoryEntry.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(QuizHistoryEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = await getAll();
      all.removeWhere((e) => e.sessionId == entry.sessionId);
      all.insert(0, entry);
      final trimmed = all.take(_maxEntries).toList();
      await prefs.setString(_key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> delete(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = await getAll();
      all.removeWhere((e) => e.sessionId == sessionId);
      await prefs.setString(_key, jsonEncode(all.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
