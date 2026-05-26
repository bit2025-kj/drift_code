import 'package:flutter/material.dart';

class QuizModel {
  final String id;
  final String title;
  final String? description;
  final String difficulty;
  final int questionCount;
  final int durationMinutes;
  final bool isAiGenerated;
  final int playsCount;
  final double avgScore;
  final String? matiereName;
  final String? classeName;

  const QuizModel({
    required this.id,
    required this.title,
    this.description,
    required this.difficulty,
    required this.questionCount,
    required this.durationMinutes,
    required this.isAiGenerated,
    required this.playsCount,
    required this.avgScore,
    this.matiereName,
    this.classeName,
  });

  factory QuizModel.fromJson(Map<String, dynamic> j) => QuizModel(
        id: j['id'],
        title: j['title'],
        description: j['description'],
        difficulty: j['difficulty'] ?? 'moyen',
        questionCount: j['question_count'] ?? 10,
        durationMinutes: j['duration_minutes'] ?? 30,
        isAiGenerated: j['is_ai_generated'] ?? false,
        playsCount: j['plays_count'] ?? 0,
        avgScore: (j['avg_score'] ?? 0).toDouble(),
        matiereName: j['matiere_name'],
        classeName: j['classe_name'],
      );

  String get difficultyLabel {
    switch (difficulty) {
      case 'facile': return 'Facile';
      case 'difficile': return 'Difficile';
      default: return 'Moyen';
    }
  }
}

class QuestionModel {
  final String id;
  final String content;
  final Map<String, String> options;
  final int order;
  final int points;
  final String? correctAnswer;
  final String? explanation;

  const QuestionModel({
    required this.id,
    required this.content,
    required this.options,
    required this.order,
    required this.points,
    this.correctAnswer,
    this.explanation,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> j) => QuestionModel(
        id: j['id'],
        content: j['content'],
        options: Map<String, String>.from(j['options']),
        order: j['order'] ?? 0,
        points: j['points'] ?? 1,
        correctAnswer: j['correct_answer'],
        explanation: j['explanation'],
      );
}

// ── Historique quiz (local + en ligne) ────────────────────────────────────────

class QuizHistoryQuestion {
  final String id;
  final String content;
  final Map<String, String> options;
  final String correctAnswer;
  final String? explanation;
  final int order;

  const QuizHistoryQuestion({
    required this.id,
    required this.content,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    required this.order,
  });

  factory QuizHistoryQuestion.fromJson(Map<String, dynamic> j) => QuizHistoryQuestion(
        id: j['id'],
        content: j['content'],
        options: Map<String, String>.from(j['options']),
        correctAnswer: j['correct_answer'] ?? '',
        explanation: j['explanation'],
        order: j['order'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'content': content, 'options': options,
        'correct_answer': correctAnswer, 'explanation': explanation, 'order': order,
      };
}

class QuizHistoryEntry {
  final String sessionId;
  final String quizId;
  final String quizTitle;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final int durationSeconds;
  final String? matiereName;
  final DateTime completedAt;
  final List<QuizHistoryQuestion> questions;
  final Map<String, String> answers;

  const QuizHistoryEntry({
    required this.sessionId,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.durationSeconds,
    this.matiereName,
    required this.completedAt,
    this.questions = const [],
    this.answers = const {},
  });

  factory QuizHistoryEntry.fromJson(Map<String, dynamic> j) => QuizHistoryEntry(
        sessionId: j['session_id'],
        quizId: j['quiz_id'] ?? '',
        quizTitle: j['quiz_title'] ?? '',
        score: (j['score'] ?? 0).toDouble(),
        correctAnswers: j['correct_answers'] ?? 0,
        totalQuestions: j['total_questions'] ?? 0,
        durationSeconds: j['duration_seconds'] ?? 0,
        matiereName: j['matiere_name'],
        completedAt: j['completed_at'] is String
            ? DateTime.parse(j['completed_at'])
            : DateTime.now(),
        questions: (j['questions'] as List? ?? [])
            .map((q) => QuizHistoryQuestion.fromJson(q))
            .toList(),
        answers: j['answers'] != null
            ? Map<String, String>.from(j['answers'])
            : {},
      );

  Map<String, dynamic> toJson() => {
        'session_id': sessionId, 'quiz_id': quizId, 'quiz_title': quizTitle,
        'score': score, 'correct_answers': correctAnswers,
        'total_questions': totalQuestions, 'duration_seconds': durationSeconds,
        'matiere_name': matiereName,
        'completed_at': completedAt.toIso8601String(),
        'questions': questions.map((q) => q.toJson()).toList(),
        'answers': answers,
      };

  Color get scoreColor {
    if (score >= 80) return const Color(0xFF2ECC71);
    if (score >= 60) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  String get scoreLabel {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bien';
    if (score >= 40) return 'Passable';
    return 'À revoir';
  }

  String get durationLabel {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }
}

class QuizSessionResult {
  final String sessionId;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final int durationSeconds;
  final int pointsEarned;
  final List<QuestionModel> questionsWithAnswers;

  const QuizSessionResult({
    required this.sessionId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.durationSeconds,
    required this.pointsEarned,
    required this.questionsWithAnswers,
  });

  factory QuizSessionResult.fromJson(Map<String, dynamic> j) => QuizSessionResult(
        sessionId: j['session_id'],
        score: (j['score'] ?? 0).toDouble(),
        correctAnswers: j['correct_answers'] ?? 0,
        totalQuestions: j['total_questions'] ?? 0,
        durationSeconds: j['duration_seconds'] ?? 0,
        pointsEarned: j['points_earned'] ?? 0,
        questionsWithAnswers: (j['questions_with_answers'] as List)
            .map((q) => QuestionModel.fromJson(q))
            .toList(),
      );
}
