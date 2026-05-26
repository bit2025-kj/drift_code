import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/quiz_model.dart';
import 'package:nafa_edu/services/quiz_history_storage.dart';

// ── Quiz list ──────────────────────────────────────────────────────────────────

final quizListProvider = FutureProvider.family<List<QuizModel>, int?>((ref, matiereId) async {
  final params = <String, dynamic>{};
  if (matiereId != null) params['matiere_id'] = matiereId;
  final res = await ApiClient.instance.dio.get(ApiEndpoints.quizList, queryParameters: params);
  return (res.data as List).map((q) => QuizModel.fromJson(q)).toList();
});

// ── Mes sessions ──────────────────────────────────────────────────────────────

class QuizSessionSummary {
  final String sessionId;
  final String quizId;
  final String quizTitle;
  final double? score;
  final bool isCompleted;
  final DateTime startedAt;
  final String? matiere;

  const QuizSessionSummary({
    required this.sessionId,
    required this.quizId,
    required this.quizTitle,
    this.score,
    required this.isCompleted,
    required this.startedAt,
    this.matiere,
  });

  factory QuizSessionSummary.fromJson(Map<String, dynamic> j) => QuizSessionSummary(
        sessionId: j['session_id'],
        quizId: j['quiz_id'] ?? '',
        quizTitle: j['quiz_title'] ?? '',
        score: j['score']?.toDouble(),
        isCompleted: j['is_completed'] ?? false,
        startedAt: DateTime.parse(j['started_at']),
        matiere: j['matiere'],
      );
}

final mySessionsProvider = FutureProvider<List<QuizSessionSummary>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.mySessions);
  return (res.data as List).map((s) => QuizSessionSummary.fromJson(s)).toList();
});

// ── Stats quiz ────────────────────────────────────────────────────────────────

class QuizStatsModel {
  final int totalSessions;
  final double avgScore;
  final double bestScore;
  final int currentStreak;
  final int? rank;
  final int totalPoints;

  const QuizStatsModel({
    required this.totalSessions,
    required this.avgScore,
    required this.bestScore,
    required this.currentStreak,
    this.rank,
    required this.totalPoints,
  });

  factory QuizStatsModel.fromJson(Map<String, dynamic> j) => QuizStatsModel(
        totalSessions: j['total_sessions'] ?? 0,
        avgScore: (j['avg_score'] ?? 0).toDouble(),
        bestScore: (j['best_score'] ?? 0).toDouble(),
        currentStreak: j['current_streak'] ?? 0,
        rank: j['rank'],
        totalPoints: j['total_points'] ?? 0,
      );
}

final quizStatsProvider = FutureProvider<QuizStatsModel>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.quizStats);
  return QuizStatsModel.fromJson(res.data);
});

// ── Génération quiz ───────────────────────────────────────────────────────────

class GenerateQuizState {
  final bool isLoading;
  final String? error;
  final String? sessionId;
  final QuizModel? quiz;
  final List<QuestionModel> questions;

  const GenerateQuizState({
    this.isLoading = false,
    this.error,
    this.sessionId,
    this.quiz,
    this.questions = const [],
  });

  GenerateQuizState copyWith({
    bool? isLoading,
    String? error,
    String? sessionId,
    QuizModel? quiz,
    List<QuestionModel>? questions,
  }) =>
      GenerateQuizState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        sessionId: sessionId ?? this.sessionId,
        quiz: quiz ?? this.quiz,
        questions: questions ?? this.questions,
      );
}

class GenerateQuizNotifier extends StateNotifier<GenerateQuizState> {
  GenerateQuizNotifier() : super(const GenerateQuizState());

  Future<bool> generate({
    required int matiereId,
    int? classeId,
    String difficulty = 'moyen',
    int questionCount = 10,
    String? topic,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.instance.dio.post(ApiEndpoints.generateQuiz, data: {
        'matiere_id': matiereId,
        if (classeId != null) 'classe_id': classeId,
        'difficulty': difficulty,
        'question_count': questionCount,
        if (topic != null && topic.isNotEmpty) 'topic': topic,
      });
      final quiz = QuizModel.fromJson(res.data['quiz']);
      final questions = (res.data['questions'] as List)
          .map((q) => QuestionModel.fromJson(q))
          .toList();
      state = state.copyWith(
        isLoading: false,
        sessionId: res.data['session_id'],
        quiz: quiz,
        questions: questions,
      );
      return true;
    } catch (e) {
      final msg = _parseError(e);
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  void reset() => state = const GenerateQuizState();

  String _parseError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['detail'] != null) return data['detail'].toString();
    } catch (_) {}
    return 'Erreur lors de la génération du quiz';
  }
}

final generateQuizProvider = StateNotifierProvider<GenerateQuizNotifier, GenerateQuizState>(
  (_) => GenerateQuizNotifier(),
);

// ── Génération depuis un fichier (PDF/image) ──────────────────────────────────

class GenerateFromFileNotifier extends StateNotifier<GenerateQuizState> {
  GenerateFromFileNotifier() : super(const GenerateQuizState());

  Future<bool> generate({
    required PlatformFile file,
    required int matiereId,
    String difficulty = 'moyen',
    int questionCount = 10,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Impossible de lire le fichier');

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
          contentType: DioMediaType.parse(_mimeType(file.name)),
        ),
        'matiere_id': matiereId,
        'difficulty': difficulty,
        'question_count': questionCount,
      });

      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.generateQuizFromFile,
        data: formData,
      );
      final quiz = QuizModel.fromJson(res.data['quiz']);
      final questions = (res.data['questions'] as List)
          .map((q) => QuestionModel.fromJson(q))
          .toList();
      state = state.copyWith(
        isLoading: false,
        sessionId: res.data['session_id'],
        quiz: quiz,
        questions: questions,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  void reset() => state = const GenerateQuizState();

  String _mimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _parseError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['detail'] != null) return data['detail'].toString();
    } catch (_) {}
    return 'Erreur lors de la génération du quiz';
  }
}

final generateFromFileProvider = StateNotifierProvider<GenerateFromFileNotifier, GenerateQuizState>(
  (_) => GenerateFromFileNotifier(),
);

// ── Génération depuis le parcours de l'élève ──────────────────────────────────

class GenerateFromProfileNotifier extends StateNotifier<GenerateQuizState> {
  GenerateFromProfileNotifier() : super(const GenerateQuizState());

  Future<bool> generate({
    int? matiereId,
    String difficulty = 'moyen',
    int questionCount = 10,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.generateQuizFromProfile,
        data: {
          if (matiereId != null) 'matiere_id': matiereId,
          'difficulty': difficulty,
          'question_count': questionCount,
        },
      );
      final quiz = QuizModel.fromJson(res.data['quiz']);
      final questions = (res.data['questions'] as List)
          .map((q) => QuestionModel.fromJson(q))
          .toList();
      state = state.copyWith(
        isLoading: false,
        sessionId: res.data['session_id'],
        quiz: quiz,
        questions: questions,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  void reset() => state = const GenerateQuizState();

  String _parseError(dynamic e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['detail'] != null) return data['detail'].toString();
    } catch (_) {}
    return 'Profil incomplet ou erreur réseau';
  }
}

final generateFromProfileProvider = StateNotifierProvider<GenerateFromProfileNotifier, GenerateQuizState>(
  (_) => GenerateFromProfileNotifier(),
);

// ── Historique quiz local ─────────────────────────────────────────────────────

final localQuizHistoryProvider = FutureProvider<List<QuizHistoryEntry>>((ref) {
  return QuizHistoryStorage.getAll();
});
