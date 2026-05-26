import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';

// ── Modèles légers ────────────────────────────────────────────────────────────

class EducationLevel {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;
  final List<EducationClasse> classes;

  const EducationLevel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
    this.classes = const [],
  });

  factory EducationLevel.fromJson(Map<String, dynamic> j) => EducationLevel(
        id: j['id'],
        name: j['name'],
        slug: j['slug'],
        icon: j['icon'],
        color: j['color'],
        classes: (j['classes'] as List? ?? [])
            .map((c) => EducationClasse.fromJson(c))
            .toList(),
      );
}

class EducationClasse {
  final int id;
  final String name;
  final String slug;
  final int? levelId;

  const EducationClasse({
    required this.id,
    required this.name,
    required this.slug,
    this.levelId,
  });

  factory EducationClasse.fromJson(Map<String, dynamic> j) => EducationClasse(
        id: j['id'],
        name: j['name'],
        slug: j['slug'],
        levelId: j['level_id'],
      );
}

class EducationMatiere {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;

  const EducationMatiere({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
  });

  factory EducationMatiere.fromJson(Map<String, dynamic> j) => EducationMatiere(
        id: j['id'],
        name: j['name'],
        slug: j['slug'],
        icon: j['icon'],
        color: j['color'],
      );
}

class TypeExamen {
  final int id;
  final String name;
  final String slug;

  const TypeExamen({required this.id, required this.name, required this.slug});

  factory TypeExamen.fromJson(Map<String, dynamic> j) =>
      TypeExamen(id: j['id'], name: j['name'], slug: j['slug']);
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Niveaux d'éducation avec leurs classes imbriquées
final levelsProvider = FutureProvider<List<EducationLevel>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.levels);
  return (res.data as List).map((l) => EducationLevel.fromJson(l)).toList();
});

/// Toutes les matières
final matieresProvider = FutureProvider<List<EducationMatiere>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.matieres);
  return (res.data as List).map((m) => EducationMatiere.fromJson(m)).toList();
});

/// Classes filtrées par niveau (null = toutes)
final classesByLevelProvider = FutureProvider.family<List<EducationClasse>, int?>((ref, levelId) async {
  final levels = await ref.watch(levelsProvider.future);
  if (levelId == null) {
    return levels.expand((l) => l.classes).toList();
  }
  return levels.firstWhere((l) => l.id == levelId, orElse: () => const EducationLevel(id: 0, name: '', slug: '')).classes;
});

/// Types d'examens (BAC, BEPC, Concours…)
final typesExamensProvider = FutureProvider<List<TypeExamen>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.typesExamens);
  return (res.data as List).map((t) => TypeExamen.fromJson(t)).toList();
});

/// Années disponibles
final yearsProvider = FutureProvider<List<int>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.years);
  return (res.data as List).cast<int>();
});

/// Types d'examens filtrés par niveau (null = tous les types)
final typesExamensByLevelProvider = FutureProvider.family<List<TypeExamen>, int?>((ref, levelId) async {
  final res = await ApiClient.instance.dio.get(
    ApiEndpoints.typesExamens,
    queryParameters: levelId != null ? {'level_id': levelId} : null,
  );
  return (res.data as List).map((t) => TypeExamen.fromJson(t)).toList();
});
