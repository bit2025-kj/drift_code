import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/models/quiz_model.dart';
import 'package:nafa_edu/providers/quiz_provider.dart';
import 'package:nafa_edu/services/quiz_history_storage.dart';

class QuizHistoryScreen extends ConsumerStatefulWidget {
  final String? focusId;

  const QuizHistoryScreen({super.key, this.focusId});

  @override
  ConsumerState<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends ConsumerState<QuizHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFocus(List<QuizHistoryEntry> entries) {
    if (widget.focusId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[widget.focusId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(key!.currentContext!, duration: const Duration(milliseconds: 400));
      }
    });
  }

  Future<void> _delete(String sessionId) async {
    await QuizHistoryStorage.delete(sessionId);
    ref.invalidate(localQuizHistoryProvider);
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer l\'historique'),
        content: const Text('Supprimer tous les quiz enregistrés ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await QuizHistoryStorage.clear();
      ref.invalidate(localQuizHistoryProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(localQuizHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique des quiz'),
        actions: [
          historyAsync.whenOrNull(
            data: (entries) => entries.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () => _clearAll(context),
                    tooltip: 'Tout effacer',
                  )
                : null,
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur de chargement')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha:0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun quiz terminé',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tes résultats apparaîtront ici après chaque quiz.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          _scrollToFocus(entries);

          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final entry = entries[i];
              final key = GlobalKey();
              _itemKeys[entry.sessionId] = key;
              final isHighlighted = entry.sessionId == widget.focusId;

              return _HistoryEntryCard(
                key: key,
                entry: entry,
                highlighted: isHighlighted,
                onDelete: () => _delete(entry.sessionId),
                onReview: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ReviewScreen(entry: entry),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── History entry card ─────────────────────────────────────────────────────────

class _HistoryEntryCard extends StatelessWidget {
  final QuizHistoryEntry entry;
  final bool highlighted;
  final VoidCallback onDelete;
  final VoidCallback onReview;

  const _HistoryEntryCard({
    super.key,
    required this.entry,
    required this.highlighted,
    required this.onDelete,
    required this.onReview,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: highlighted ? entry.scoreColor.withValues(alpha:0.06) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? entry.scoreColor.withValues(alpha:0.4) : AppColors.border,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onReview,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: entry.scoreColor.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${entry.score.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: entry.scoreColor,
                      ),
                    ),
                    Text(
                      entry.scoreLabel,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: entry.scoreColor.withValues(alpha:0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.quizTitle,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (entry.matiereName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.matiereName!,
                              style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${entry.correctAnswers}/${entry.totalQuestions} · ${entry.durationLabel}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(entry.completedAt),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    color: AppColors.primary,
                    onPressed: onReview,
                    tooltip: 'Revoir',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: onDelete,
                    tooltip: 'Supprimer',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Review screen ──────────────────────────────────────────────────────────────

class _ReviewScreen extends StatelessWidget {
  final QuizHistoryEntry entry;

  const _ReviewScreen({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(entry.quizTitle, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: entry.scoreColor.withValues(alpha:0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${entry.score.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: entry.scoreColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entry.questions.isEmpty ? 1 : entry.questions.length,
        itemBuilder: (context, i) {
          if (entry.questions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Les questions détaillées ne sont pas disponibles pour ce quiz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          final q = entry.questions[i];
          final userAnswer = entry.answers[q.id];
          final isCorrect = userAnswer == q.correctAnswer;
          final options = q.options.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.success.withValues(alpha:0.08)
                        : AppColors.error.withValues(alpha:0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    border: Border(
                      bottom: BorderSide(
                        color: isCorrect
                            ? AppColors.success.withValues(alpha:0.2)
                            : AppColors.error.withValues(alpha:0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: isCorrect ? AppColors.success : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Q${i + 1}: ${q.content}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...options.map((opt) {
                        final isUserChoice = userAnswer == opt.key;
                        final isCorrectChoice = q.correctAnswer == opt.key;

                        Color bgColor = Colors.transparent;
                        Color borderColor = AppColors.border;
                        Color textColor = AppColors.textPrimary;
                        IconData? trailingIcon;
                        Color? trailingColor;

                        if (isCorrectChoice) {
                          bgColor = AppColors.success.withValues(alpha:0.08);
                          borderColor = AppColors.success.withValues(alpha:0.4);
                          textColor = AppColors.success;
                          trailingIcon = Icons.check;
                          trailingColor = AppColors.success;
                        } else if (isUserChoice && !isCorrectChoice) {
                          bgColor = AppColors.error.withValues(alpha:0.08);
                          borderColor = AppColors.error.withValues(alpha:0.4);
                          textColor = AppColors.error;
                          trailingIcon = Icons.close;
                          trailingColor = AppColors.error;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isCorrectChoice
                                      ? AppColors.success
                                      : isUserChoice
                                          ? AppColors.error
                                          : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    opt.key,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: (isCorrectChoice || isUserChoice)
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  opt.value,
                                  style: TextStyle(fontSize: 12, color: textColor),
                                ),
                              ),
                              if (trailingIcon != null) ...[
                                const SizedBox(width: 4),
                                Icon(trailingIcon, size: 14, color: trailingColor),
                              ],
                            ],
                          ),
                        );
                      }),
                      if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha:0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  q.explanation!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (userAnswer == null) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Non répondue',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
