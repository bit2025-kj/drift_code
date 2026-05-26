import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/quiz_model.dart';
import 'package:nafa_edu/services/quiz_history_storage.dart';

class QuizSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final QuizModel quiz;
  final List<QuestionModel> questions;

  const QuizSessionScreen({
    super.key,
    required this.sessionId,
    required this.quiz,
    required this.questions,
  });

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen> {
  int _currentIndex = 0;
  final Map<String, String> _answers = {};
  bool _isSubmitting = false;
  bool _isCompleted = false;
  QuizSessionResult? _result;
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.quiz.durationMinutes * 60;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        _submit();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft < 60) return AppColors.error;
    if (_secondsLeft < 180) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    _timer?.cancel();
    final elapsed = widget.quiz.durationMinutes * 60 - _secondsLeft;
    setState(() => _isSubmitting = true);
    try {
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.submitSession(widget.sessionId),
        data: {'answers': _answers, 'duration_seconds': elapsed},
      );
      final result = QuizSessionResult.fromJson(res.data);
      _saveToHistory(result);
      setState(() {
        _result = result;
        _isCompleted = true;
        _isSubmitting = false;
      });
    } catch (_) {
      setState(() => _isSubmitting = false);
    }
  }

  void _saveToHistory(QuizSessionResult result) {
    final entry = QuizHistoryEntry(
      sessionId: widget.sessionId,
      quizId: widget.quiz.id,
      quizTitle: widget.quiz.title,
      score: result.score,
      correctAnswers: result.correctAnswers,
      totalQuestions: result.totalQuestions,
      durationSeconds: result.durationSeconds,
      matiereName: widget.quiz.matiereName,
      completedAt: DateTime.now(),
      questions: result.questionsWithAnswers.map((q) => QuizHistoryQuestion(
        id: q.id,
        content: q.content,
        options: q.options,
        correctAnswer: q.correctAnswer ?? '',
        explanation: q.explanation,
        order: q.order,
      )).toList(),
      answers: Map<String, String>.from(_answers),
    );
    QuizHistoryStorage.save(entry);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted && _result != null) {
      return _ResultView(result: _result!, quiz: widget.quiz);
    }

    final q = widget.questions[_currentIndex];
    final options = q.options.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.quiz.title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _timerColor.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: _timerColor),
                const SizedBox(width: 4),
                Text(
                  _timerLabel,
                  style: TextStyle(fontWeight: FontWeight.w700, color: _timerColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Question ${_currentIndex + 1}/${widget.questions.length}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '${_answers.length} répondues',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / widget.questions.length,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      q.content,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...options.map((entry) {
                    final selected = _answers[q.id] == entry.key;
                    return GestureDetector(
                      onTap: () => setState(() => _answers[q.id] = entry.key),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary.withValues(alpha:0.08) : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primary : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: selected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
            child: Row(
              children: [
                if (_currentIndex > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentIndex--),
                      child: const Text('Précédent'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: _currentIndex < widget.questions.length - 1
                      ? ElevatedButton(
                          onPressed: () => setState(() => _currentIndex++),
                          child: const Text('Suivant'),
                        )
                      : ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Soumettre', style: TextStyle(color: Colors.white)),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Écran de résultat ──────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final QuizSessionResult result;
  final QuizModel quiz;

  const _ResultView({required this.result, required this.quiz});

  Color get _scoreColor {
    if (result.score >= 80) return AppColors.success;
    if (result.score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String get _scoreMessage {
    if (result.score >= 80) return 'Excellent !';
    if (result.score >= 60) return 'Bien joué !';
    if (result.score >= 40) return 'Peut mieux faire';
    return 'Continue tes efforts';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Résultat'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Fermer'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_scoreColor.withValues(alpha:0.7), _scoreColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  _scoreMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  '${result.score.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.correctAnswers} / ${result.totalQuestions} correctes',
                  style: TextStyle(color: Colors.white.withValues(alpha:0.9), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ResultStat('+${result.pointsEarned} XP', 'Points gagnés', AppColors.accent),
              const SizedBox(width: 12),
              _ResultStat(_formatDuration(result.durationSeconds), 'Durée', AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Détail des réponses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...result.questionsWithAnswers.asMap().entries.map((e) {
            final q = e.value;
            final hasCorrect = q.correctAnswer != null;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasCorrect
                    ? AppColors.success.withValues(alpha:0.06)
                    : AppColors.error.withValues(alpha:0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasCorrect
                      ? AppColors.success.withValues(alpha:0.3)
                      : AppColors.error.withValues(alpha:0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        hasCorrect ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: hasCorrect ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Q${e.key + 1}: ${q.content}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      q.explanation!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Retour à l\'accueil'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ResultStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
