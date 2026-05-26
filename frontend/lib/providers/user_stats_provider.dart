import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/user_model.dart';

// ── Stats utilisateur ─────────────────────────────────────────────────────────

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.myStats);
  return UserStats.fromJson(res.data);
});

// ── Badges ────────────────────────────────────────────────────────────────────

class BadgeModel {
  final int id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final DateTime earnedAt;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> j) => BadgeModel(
        id: j['id'],
        name: j['name'],
        description: j['description'],
        icon: j['icon'],
        color: j['color'],
        earnedAt: DateTime.parse(j['earned_at']),
      );
}

final userBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.myBadges);
  return (res.data as List).map((b) => BadgeModel.fromJson(b)).toList();
});

// ── Favoris (liste complète pour profil) ──────────────────────────────────────

final myFavoritesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.myFavorites);
  return List<Map<String, dynamic>>.from(res.data['items'] ?? []);
});

// ── Téléchargements ───────────────────────────────────────────────────────────

final myDownloadsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.myDownloads);
  return List<Map<String, dynamic>>.from(res.data['items'] ?? []);
});

// ── Achats ────────────────────────────────────────────────────────────────────

final myPurchasesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.myPurchases);
  return List<Map<String, dynamic>>.from(res.data['items'] ?? []);
});

// ── Activité récente ──────────────────────────────────────────────────────────

final activityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get(ApiEndpoints.myActivity);
    return List<Map<String, dynamic>>.from(res.data);
  } catch (_) {
    return [];
  }
});

// ── Classement ────────────────────────────────────────────────────────────────

final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.leaderboard);
  return List<Map<String, dynamic>>.from(res.data);
});
