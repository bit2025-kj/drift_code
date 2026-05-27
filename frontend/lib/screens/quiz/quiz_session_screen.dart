import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String? _selectedAnswer; // null = pas encore répondu pour cette question
  bool _isSubmitting = false;
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
        if (mounted) setState(() => _secondsLeft--);
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

  void _selectAnswer(String questionId, String answer) {
    if (_selectedAnswer != null) return; // déjà répondu
    HapticFeedback.lightImpact();
    setState(() {
      _answers[questionId] = answer;
      _selectedAnswer = answer;
    });
  }

  void _goNext() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    } else {
      _submit();
    }
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
      if (mounted) setState(() { _result = result; _isSubmitting = false; });
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
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
    // Soumission en cours
    if (_isSubmitting) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                'Calcul de ton score…',
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Résultat disponible
    if (_result != null) {
      return _ResultScreen(
        result: _result!,
        quiz: widget.quiz,
        answers: _answers,
      );
    }

    final q = widget.questions[_currentIndex];
    final options = q.options.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final isAnswered = _selectedAnswer != null;
    final isCorrect = isAnswered && _selectedAnswer == q.correctAnswer;
    final isLast = _currentIndex == widget.questions.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.quiz.title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () { _timer?.cancel(); Navigator.pop(context); },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _timerColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
          // ── Barre de progression ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} / ${widget.questions.length}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    if (isAnswered)
                      AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 14,
                              color: isCorrect ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCorrect ? 'Bonne réponse !' : 'Mauvaise réponse',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isCorrect ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / widget.questions.length,
                    minHeight: 5,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // ── Question + options ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
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
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, height: 1.55),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Options
                  ...options.map((opt) {
                    final isSelected = _selectedAnswer == opt.key;
                    final isCorrectOpt = opt.key == q.correctAnswer;

                    // Couleurs selon l'état
                    Color bg;
                    Color borderColor;
                    double borderWidth;
                    Color labelBg;
                    Color labelText;
                    Color textColor;
                    Widget? trailing;

                    if (isAnswered) {
                      if (isCorrectOpt) {
                        bg = AppColors.success.withValues(alpha: 0.09);
                        borderColor = AppColors.success;
                        borderWidth = 2;
                        labelBg = AppColors.success;
                        labelText = Colors.white;
                        textColor = AppColors.success;
                        trailing = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20);
                      } else if (isSelected) {
                        bg = AppColors.error.withValues(alpha: 0.09);
                        borderColor = AppColors.error;
                        borderWidth = 2;
                        labelBg = AppColors.error;
                        labelText = Colors.white;
                        textColor = AppColors.error;
                        trailing = const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20);
                      } else {
                        bg = AppColors.surface;
                        borderColor = AppColors.border;
                        borderWidth = 1;
                        labelBg = AppColors.surfaceVariant;
                        labelText = AppColors.textSecondary;
                        textColor = AppColors.textSecondary;
                        trailing = null;
                      }
                    } else {
                      // Pas encore répondu
                      bg = AppColors.surface;
                      borderColor = AppColors.border;
                      borderWidth = 1;
                      labelBg = AppColors.surfaceVariant;
                      labelText = AppColors.textSecondary;
                      textColor = AppColors.textPrimary;
                      trailing = null;
                    }

                    return GestureDetector(
                      onTap: () => _selectAnswer(q.id, opt.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: borderWidth),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: labelBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  opt.key,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: labelText,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opt.value,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: textColor,
                                  fontWeight: (isAnswered && (isCorrectOpt || isSelected))
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (trailing != null) ...[
                              const SizedBox(width: 6),
                              trailing,
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                  // Explication (apparaît après réponse)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: isAnswered && q.explanation != null && q.explanation!.isNotEmpty
                        ? Container(
                            key: const ValueKey('explication'),
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    q.explanation!,
                                    style: GoogleFonts.inter(
                                        fontSize: 12, height: 1.5, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-explication')),
                  ),
                ],
              ),
            ),
          ),

          // ── Bouton action ────────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isAnswered
                ? Padding(
                    key: const ValueKey('btn-next'),
                    padding: EdgeInsets.fromLTRB(
                        16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _goNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isLast ? AppColors.success : AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Voir mon score' : 'Question suivante',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast
                                  ? Icons.emoji_events_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Padding(
                    key: const ValueKey('hint'),
                    padding: EdgeInsets.fromLTRB(
                        16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
                    child: SizedBox(
                      height: 54,
                      child: Center(
                        child: Text(
                          'Sélectionne une réponse pour continuer',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textHint),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Écran de résultat ──────────────────────────────────────────────────────────

class _ResultScreen extends StatelessWidget {
  final QuizSessionResult result;
  final QuizModel quiz;
  final Map<String, String> answers;

  const _ResultScreen({
    required this.result,
    required this.quiz,
    required this.answers,
  });

  Color get _scoreColor {
    if (result.score >= 80) return AppColors.success;
    if (result.score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String get _scoreMessage {
    if (result.score >= 80) return 'Excellent ! 🎉';
    if (result.score >= 60) return 'Bien joué ! 👏';
    if (result.score >= 40) return 'Continue comme ça ! 💪';
    return 'À revoir, ne lâche pas ! 📚';
  }

  String get _grade {
    if (result.score >= 90) return 'A+';
    if (result.score >= 80) return 'A';
    if (result.score >= 70) return 'B';
    if (result.score >= 60) return 'C';
    if (result.score >= 50) return 'D';
    return 'E';
  }

  String _formatDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return m > 0 ? '${m}m ${sec}s' : '${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final wrongCount = result.totalQuestions - result.correctAnswers;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // Fermer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Fermer'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Score circle ─────────────────────────────────────────────────
            Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _scoreColor.withValues(alpha: 0.08),
                  border: Border.all(color: _scoreColor, width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${result.score.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: _scoreColor),
                    ),
                    Text(
                      _grade,
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _scoreColor.withValues(alpha: 0.65)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Text(
                _scoreMessage,
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                quiz.title,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats grid ───────────────────────────────────────────────────
            Row(children: [
              _StatTile(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                value: '${result.correctAnswers}',
                label: 'Correctes',
              ),
              const SizedBox(width: 10),
              _StatTile(
                icon: Icons.cancel_rounded,
                color: AppColors.error,
                value: '$wrongCount',
                label: 'Incorrectes',
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _StatTile(
                icon: Icons.star_rounded,
                color: AppColors.accent,
                value: '+${result.pointsEarned}',
                label: 'Points XP',
              ),
              const SizedBox(width: 10),
              _StatTile(
                icon: Icons.timer_outlined,
                color: AppColors.primary,
                value: _formatDuration(result.durationSeconds),
                label: 'Durée',
              ),
            ]),

            const SizedBox(height: 24),

            // ── Récapitulatif ────────────────────────────────────────────────
            Text('Récapitulatif',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),

            ...result.questionsWithAnswers.asMap().entries.map((e) {
              final q = e.value;
              final userAns = answers[q.id];
              final isCorrect = userAns != null &&
                  q.correctAnswer != null &&
                  userAns == q.correctAnswer;
              final wasSkipped = userAns == null;

              return Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: wasSkipped
                      ? AppColors.surfaceVariant
                      : (isCorrect ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: wasSkipped
                        ? AppColors.border
                        : (isCorrect ? AppColors.success : AppColors.error)
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      wasSkipped
                          ? Icons.remove_circle_outline
                          : isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                      size: 16,
                      color: wasSkipped
                          ? AppColors.textHint
                          : (isCorrect ? AppColors.success : AppColors.error),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Q${e.key + 1}: ${q.content}',
                        style: GoogleFonts.inter(
                            fontSize: 12, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isCorrect && !wasSkipped && q.correctAnswer != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '→ ${q.correctAnswer}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // ── Action ───────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Nouveau quiz',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
