import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/quiz_model.dart';
import 'package:nafa_edu/providers/auth_provider.dart';
import 'package:nafa_edu/providers/education_provider.dart';
import 'package:nafa_edu/providers/quiz_provider.dart';
import 'package:nafa_edu/screens/quiz/quiz_history_screen.dart';
import 'package:nafa_edu/screens/quiz/quiz_session_screen.dart';
import 'package:nafa_edu/widgets/network_error_widget.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Quiz IA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAIBanner(context),
          const SizedBox(height: 20),
          _buildStatsCard(ref),
          const SizedBox(height: 20),
          _buildInProgressSection(context, ref),
          _buildHistorySection(context, ref),
        ],
      ),
    );
  }

  // ── AI banner ─────────────────────────────────────────────────────────────────

  Widget _buildAIBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B5BDB), Color(0xFF7048E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B5BDB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiz IA personnalisé',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Génère un quiz depuis un cours PDF/photo ou selon ton niveau et tes matières.',
                  style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.85), fontSize: 12, height: 1.45),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => _showGenerateSheet(context),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text('Générer un quiz',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3B5BDB),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 68, height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 30))),
          ),
        ],
      ),
    );
  }

  // ── Stats card ────────────────────────────────────────────────────────────────

  Widget _buildStatsCard(WidgetRef ref) {
    final statsAsync = ref.watch(quizStatsProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mes statistiques',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          statsAsync.when(
            loading: () => const SizedBox(
                height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, __) => _StatsGrid(quiz: '—', score: '—', streak: '—', rank: '—'),
            data: (s) => _StatsGrid(
              quiz: '${s.totalSessions}',
              score: '${s.avgScore.toStringAsFixed(0)}%',
              streak: '${s.currentStreak}',
              rank: s.rank != null ? '${s.rank}' : '—',
            ),
          ),
        ],
      ),
    );
  }

  // ── In-progress section ───────────────────────────────────────────────────────

  Widget _buildInProgressSection(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(mySessionsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quiz en cours',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        sessionsAsync.when(
          loading: () => const SizedBox(
              height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (e, _) => NetworkErrorWidget(
              error: e,
              compact: true,
              onRetry: () => ref.invalidate(mySessionsProvider)),
          data: (sessions) {
            final inProgress = sessions.where((s) => !s.isCompleted).toList();
            if (inProgress.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.play_circle_outline_rounded,
                        size: 36, color: AppColors.textHint),
                    const SizedBox(height: 8),
                    Text('Aucun quiz en cours',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Lance un quiz depuis le bouton ci-dessus',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              );
            }
            return SizedBox(
              height: 116,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: inProgress.length,
                itemBuilder: (_, i) {
                  final s = inProgress[i];
                  final colors = [AppColors.primary, AppColors.success, AppColors.accent, AppColors.warning];
                  return _InProgressCard(session: s, color: colors[i % colors.length]);
                },
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── History section ───────────────────────────────────────────────────────────

  Widget _buildHistorySection(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(localQuizHistoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Mon historique',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          historyAsync.maybeWhen(
            data: (entries) => entries.isNotEmpty
                ? GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const QuizHistoryScreen())),
                    child: Text('Voir tout',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ]),
        const SizedBox(height: 10),
        historyAsync.when(
          loading: () => const SizedBox(
              height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (e, _) => NetworkErrorWidget(
              error: e,
              compact: true,
              onRetry: () => ref.invalidate(localQuizHistoryProvider)),
          data: (entries) {
            if (entries.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_rounded, size: 36, color: AppColors.textHint),
                    const SizedBox(height: 8),
                    Text('Aucun quiz terminé',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Tes résultats apparaîtront ici après chaque quiz',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              );
            }
            return Column(
              children: [
                ...entries.take(3).map((e) => _HistoryCard(
                      entry: e,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => QuizHistoryScreen(focusId: e.sessionId))),
                    )),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showGenerateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GenerateQuizSheet(),
    );
  }
}

// ── Stats grid ─────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final String quiz;
  final String score;
  final String streak;
  final String rank;

  const _StatsGrid({required this.quiz, required this.score, required this.streak, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        _StatBox(value: quiz, label: 'Quiz tentés', icon: Icons.quiz_outlined, color: AppColors.primary),
        const SizedBox(width: 10),
        _StatBox(value: score, label: 'Score moyen', icon: Icons.trending_up, color: AppColors.success),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _StatBox(
            value: '$streak 🔥', label: 'Série actuelle',
            icon: Icons.local_fire_department, color: AppColors.accent),
        const SizedBox(width: 10),
        _StatBox(
            value: rank, label: 'Classement', icon: Icons.emoji_events,
            color: AppColors.warning, sublabel: rank != '—' ? 'Top 10%' : null),
      ]),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String? sublabel;

  const _StatBox({required this.value, required this.label, required this.icon, required this.color, this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            if (sublabel != null)
              Text(sublabel!, style: GoogleFonts.inter(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
          ]),
        ]),
      ),
    );
  }
}

// ── In-progress card ───────────────────────────────────────────────────────────

class _InProgressCard extends StatefulWidget {
  final QuizSessionSummary session;
  final Color color;

  const _InProgressCard({required this.session, required this.color});

  @override
  State<_InProgressCard> createState() => _InProgressCardState();
}

class _InProgressCardState extends State<_InProgressCard> {
  bool _isLoading = false;

  Future<void> _continue() async {
    if (widget.session.quizId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.instance.dio.get(
          ApiEndpoints.quizDetail(widget.session.quizId));
      final sessionId = res.data['session_id'] as String;
      final quiz = QuizModel.fromJson(res.data['quiz']);
      final questions = (res.data['questions'] as List)
          .map((q) => QuestionModel.fromJson(q))
          .toList();
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => QuizSessionScreen(
              sessionId: sessionId, quiz: quiz, questions: questions),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Erreur de chargement')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.session.matiere ?? 'Quiz IA',
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700, color: widget.color),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              widget.session.quizTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _continue,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
              child: _isLoading
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Continuer'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── History card ───────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final QuizHistoryEntry entry;
  final VoidCallback onTap;

  const _HistoryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = entry.scoreColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text('${entry.score.toInt()}%',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.quizTitle,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                if (entry.matiereName != null)
                  Text('${entry.matiereName} · ',
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                Text('${entry.correctAnswers}/${entry.totalQuestions}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 18),
        ]),
      ),
    );
  }
}

// ── Generate quiz sheet ────────────────────────────────────────────────────────

enum _QuizSource { cours, parcours }

class _GenerateQuizSheet extends ConsumerStatefulWidget {
  const _GenerateQuizSheet();

  @override
  ConsumerState<_GenerateQuizSheet> createState() => _GenerateQuizSheetState();
}

class _GenerateQuizSheetState extends ConsumerState<_GenerateQuizSheet> {
  _QuizSource _source = _QuizSource.cours;
  int? _selectedMatiereId;
  String _difficulty = 'moyen';
  int _questionCount = 10;
  PlatformFile? _selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _generate() async {
    final nav = Navigator.of(context);

    if (_source == _QuizSource.cours) {
      if (_selectedFile == null || _selectedMatiereId == null) return;
      final ok = await ref.read(generateFromFileProvider.notifier).generate(
        file: _selectedFile!,
        matiereId: _selectedMatiereId!,
        difficulty: _difficulty,
        questionCount: _questionCount,
      );
      if (ok) {
        final s = ref.read(generateFromFileProvider);
        nav.pop();
        nav.push(MaterialPageRoute(
          builder: (_) => QuizSessionScreen(
              sessionId: s.sessionId!, quiz: s.quiz!, questions: s.questions),
        ));
      } else {
        final err = ref.read(generateFromFileProvider).error;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Erreur')));
      }
    } else {
      final ok = await ref.read(generateFromProfileProvider.notifier).generate(
        matiereId: _selectedMatiereId,
        difficulty: _difficulty,
        questionCount: _questionCount,
      );
      if (ok) {
        final s = ref.read(generateFromProfileProvider);
        nav.pop();
        nav.push(MaterialPageRoute(
          builder: (_) => QuizSessionScreen(
              sessionId: s.sessionId!, quiz: s.quiz!, questions: s.questions),
        ));
      } else {
        final err = ref.read(generateFromProfileProvider).error;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Erreur')));
      }
    }
  }

  bool get _isLoading {
    if (_source == _QuizSource.cours) return ref.watch(generateFromFileProvider).isLoading;
    return ref.watch(generateFromProfileProvider).isLoading;
  }

  bool get _canGenerate {
    if (_isLoading) return false;
    if (_source == _QuizSource.cours) return _selectedFile != null && _selectedMatiereId != null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final matieresAsync = ref.watch(matieresProvider);
    final user = ref.watch(authProvider).user;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFDEE2E6), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(children: [
              Text('Générer un Quiz IA',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // Source selector — 2 options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _SourceTile(
                icon: Icons.upload_file_outlined,
                title: 'Depuis un cours',
                subtitle: 'PDF ou photo',
                selected: _source == _QuizSource.cours,
                onTap: () => setState(() => _source = _QuizSource.cours),
              ),
              const SizedBox(width: 10),
              _SourceTile(
                icon: Icons.school_outlined,
                title: 'Mon parcours',
                subtitle: 'Classe & matières',
                selected: _source == _QuizSource.parcours,
                onTap: () => setState(() => _source = _QuizSource.parcours),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Cours: file picker + matière ───────────────────────────
                  if (_source == _QuizSource.cours) ...[
                    Text('Cours (PDF ou photo)', style: _label),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedFile != null
                              ? AppColors.primary.withValues(alpha: 0.06)
                              : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedFile != null
                                ? AppColors.primary
                                : const Color(0xFFDEE2E6),
                            width: _selectedFile != null ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            _selectedFile != null
                                ? Icons.check_circle_outline
                                : Icons.upload_file_rounded,
                            color: _selectedFile != null ? AppColors.primary : AppColors.textHint,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFile?.name ?? 'Sélectionner un fichier',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: _selectedFile != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: _selectedFile != null
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_selectedFile == null)
                                  Text('PDF, JPG ou PNG',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, color: AppColors.textHint)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Matière', style: _label),
                    const SizedBox(height: 8),
                    matieresAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Erreur de chargement'),
                      data: (matieres) => DropdownButtonFormField<int?>(
                        value: _selectedMatiereId,
                        hint: Text('Choisir une matière',
                            style: GoogleFonts.inter(fontSize: 13)),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        items: matieres
                            .map((m) => DropdownMenuItem<int?>(
                                value: m.id,
                                child: Text(m.name,
                                    style: GoogleFonts.inter(fontSize: 13))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedMatiereId = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Parcours: user card + optional matière ─────────────────
                  if (_source == _QuizSource.parcours) ...[
                    if (user != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.08),
                              AppColors.primary.withValues(alpha: 0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.school_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.fullName,
                                    style: GoogleFonts.inter(
                                        fontSize: 13, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  if (user.levelName != null)
                                    _badge(user.levelName!, AppColors.primary),
                                  if (user.classeName != null) ...[
                                    const SizedBox(width: 6),
                                    _badge(user.classeName!, AppColors.success),
                                  ],
                                ]),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    const SizedBox(height: 16),
                    Text('Matière (optionnel)', style: _label),
                    const SizedBox(height: 8),
                    matieresAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const Text('Erreur de chargement'),
                      data: (matieres) => DropdownButtonFormField<int?>(
                        value: _selectedMatiereId,
                        hint: Text('Auto (selon ta classe)',
                            style: GoogleFonts.inter(fontSize: 13)),
                        decoration: InputDecoration(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Auto (selon ta classe)',
                                  style: GoogleFonts.inter(fontSize: 13))),
                          ...matieres.map((m) => DropdownMenuItem<int?>(
                              value: m.id,
                              child: Text(m.name,
                                  style: GoogleFonts.inter(fontSize: 13)))),
                        ],
                        onChanged: (v) => setState(() => _selectedMatiereId = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Difficulté ─────────────────────────────────────────────
                  Text('Difficulté', style: _label),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final d in ['facile', 'moyen', 'difficile'])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: OutlinedButton(
                              onPressed: () => setState(() => _difficulty = d),
                              style: OutlinedButton.styleFrom(
                                backgroundColor:
                                    _difficulty == d ? AppColors.primary : null,
                                foregroundColor:
                                    _difficulty == d ? Colors.white : AppColors.textPrimary,
                                side: BorderSide(
                                    color: _difficulty == d
                                        ? AppColors.primary
                                        : AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: Text(
                                d[0].toUpperCase() + d.substring(1),
                                style: GoogleFonts.inter(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Nombre de questions ────────────────────────────────────
                  Row(children: [
                    Text('Questions', style: _label),
                    const Spacer(),
                    Text('$_questionCount',
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ]),
                  Slider(
                    value: _questionCount.toDouble(),
                    min: 5, max: 30, divisions: 5,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _questionCount = v.toInt()),
                  ),
                  const SizedBox(height: 8),

                  // ── Generate button ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _canGenerate ? _generate : null,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        _isLoading
                            ? 'Génération en cours…'
                            : _source == _QuizSource.cours
                                ? 'Analyser et générer'
                                : 'Générer selon mon parcours',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _label => GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D23));

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}

// ── Source tile ────────────────────────────────────────────────────────────────

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFDEE2E6),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Icon(icon, size: 20,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : const Color(0xFF1A1D23),
                    )),
                Text(subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.textSecondary,
                    )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
