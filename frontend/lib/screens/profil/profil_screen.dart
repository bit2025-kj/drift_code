import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafa_edu/config/constants.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/user_model.dart';
import 'package:nafa_edu/providers/auth_provider.dart';
import 'package:nafa_edu/providers/user_stats_provider.dart';
import 'package:nafa_edu/screens/downloads_screen.dart';
import 'package:nafa_edu/screens/profil/settings_screen.dart';
import 'package:nafa_edu/screens/quiz/quiz_history_screen.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    setState(() => _uploadingAvatar = true);
    try {
      final multipart = file.bytes != null
          ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
          : await MultipartFile.fromFile(file.path!, filename: file.name);

      await ApiClient.instance.dio.post(
        ApiEndpoints.uploadAvatar,
        data: FormData.fromMap({'file': multipart}),
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Photo de profil mise à jour',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${e.toString()}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const Center(child: CircularProgressIndicator());
    final statsAsync = ref.watch(userStatsProvider);
    final badgesAsync = ref.watch(userBadgesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context, user, statsAsync),
          _buildQuickActions(context, user),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                _buildActivitiesGrid(statsAsync),
                const SizedBox(height: 16),
                _buildProgressSection(statsAsync),
                const SizedBox(height: 16),
                _buildRecentActivity(),
                const SizedBox(height: 16),
                _buildBadgesSection(badgesAsync),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, UserModel user, AsyncValue<UserStats> statsAsync) {
    final level = user.points ~/ 1000 + 1;
    final xpProgress = (user.points % 1000) / 1000;
    final badgesCount = statsAsync.when(data: (s) => s.badgesCount, loading: () => 0, error: (_, __) => 0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B5BDB), Color(0xFF4DABF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(child: Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Nafa Edu', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('Révise. Apprends. Réussis.', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications à venir'), duration: Duration(seconds: 1)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tappable Avatar ──────────────────────────────────────
                  GestureDetector(
                    onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                    child: Stack(
                      children: [
                        _buildAvatarCircle(user, radius: 36),
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: _uploadingAvatar ? Colors.grey : AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _uploadingAvatar
                                ? const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(user.fullName,
                                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF228BE6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(user.isTeacher ? 'PROF' : 'Élève',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (user.classeName != null || user.levelName != null)
                          Text(
                            user.classeName ?? user.levelName ?? '',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                          ),
                        if (user.ville != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 12),
                              const SizedBox(width: 2),
                              Text(user.ville!, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('Niveau', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text('$level',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('${(xpProgress * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text('${user.points} XP',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
                  const Spacer(),
                  Text('${user.points % 1000}/1000 XP',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: xpProgress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _HStat('${user.points}', 'Points'),
                    _hDiv(),
                    _HStat('$badgesCount', 'Badges'),
                    _hDiv(),
                    _HStat('${user.activeDays}', 'Jours actif'),
                    _hDiv(),
                    _HStat('${user.currentStreak}', 'Série 🔥'),
                    _hDiv(),
                    _HStat(user.rank != null ? '${user.rank}' : '—', 'Classement'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar helpers ─────────────────────────────────────────────────────────

  Widget _buildAvatarCircle(UserModel user, {required double radius}) {
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      final url = user.avatarUrl!.startsWith('http')
          ? user.avatarUrl!
          : '${AppConstants.baseUrl}${user.avatarUrl}';
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialsCircle(user, radius),
          errorWidget: (_, __, ___) => _initialsCircle(user, radius),
        ),
      );
    }
    return _initialsCircle(user, radius);
  }

  Widget _initialsCircle(UserModel user, double radius) => CircleAvatar(
    radius: radius,
    backgroundColor: Colors.white.withValues(alpha: 0.25),
    child: Text(user.initials,
        style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.67,
            fontWeight: FontWeight.w800)),
  );

  Widget _HStat(String v, String l) => Column(
    children: [
      Text(v, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      Text(l, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 9), textAlign: TextAlign.center),
    ],
  );

  Widget _hDiv() => Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2));

  // ── Quick Actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, UserModel user) {
    final wallet = _formatFcfa(user.walletBalance);
    final actions = [
      {
        'icon': Icons.favorite_border,
        'label': 'Mes\nfavoris',
        'onTap': () => _showFavoritesSheet(context),
      },
      {
        'icon': Icons.download_outlined,
        'label': 'Mes\ntéléchargements',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen())),
      },
      {
        'icon': Icons.history_outlined,
        'label': 'Historique',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizHistoryScreen())),
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'label': 'Mes\nachats',
        'onTap': () => _showPurchasesSheet(context),
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': wallet,
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Solde: $wallet'), duration: const Duration(seconds: 2)),
        ),
      },
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: actions.map((a) => Expanded(
          child: GestureDetector(
            onTap: a['onTap'] as VoidCallback,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(a['icon'] as IconData, color: AppColors.primary, size: 22),
                const SizedBox(height: 5),
                Text(
                  a['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  void _showFavoritesSheet(BuildContext context) {
    final data = ref.read(myFavoritesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimpleListSheet(
        title: 'Mes favoris',
        icon: Icons.favorite_border,
        provider: data,
        labelKey: 'title',
        subtitleKey: 'matiere_name',
      ),
    );
  }

  void _showPurchasesSheet(BuildContext context) {
    final data = ref.read(myPurchasesProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimpleListSheet(
        title: 'Mes achats',
        icon: Icons.shopping_bag_outlined,
        provider: data,
        labelKey: 'title',
        subtitleKey: 'amount_paid',
        subtitleSuffix: ' FCFA',
      ),
    );
  }

  // ── Activities Grid ────────────────────────────────────────────────────────

  Widget _buildActivitiesGrid(AsyncValue<UserStats> statsAsync) {
    final quizTotal = statsAsync.when(data: (s) => '${s.totalQuizSessions}', loading: () => '...', error: (_, __) => '—');
    final revH = statsAsync.when(
      data: (s) {
        final h = s.revisionHours.toInt();
        final m = ((s.revisionHours - h) * 60).toInt();
        return m > 0 ? '${h}h${m}min' : '${h}h';
      },
      loading: () => '...',
      error: (_, __) => '—',
    );
    final avgScore = statsAsync.when(
        data: (s) => '${s.avgQuizScore.toStringAsFixed(0)}%', loading: () => '...', error: (_, __) => '—');
    final downloads = statsAsync.when(
        data: (s) => '${s.totalDownloads}', loading: () => '...', error: (_, __) => '—');

    final items = [
      {'icon': Icons.quiz_outlined, 'label': 'Quiz réalisés', 'value': quizTotal, 'color': AppColors.primary},
      {'icon': Icons.check_circle_outline, 'label': 'Téléchargements', 'value': downloads, 'color': AppColors.success},
      {'icon': Icons.timer_outlined, 'label': 'Heures de révision', 'value': revH, 'color': AppColors.accent},
      {'icon': Icons.trending_up, 'label': 'Score moyen', 'value': avgScore, 'color': AppColors.warning},
    ];

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
          const Text('Mes activités', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _ActivityTile(items[0])),
              const SizedBox(width: 10),
              Expanded(child: _ActivityTile(items[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ActivityTile(items[2])),
              const SizedBox(width: 10),
              Expanded(child: _ActivityTile(items[3])),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progress Section ───────────────────────────────────────────────────────

  Widget _buildProgressSection(AsyncValue<UserStats> statsAsync) {
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
          const Text('Ma progression', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          statsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Impossible de charger la progression',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            data: (s) {
              if (s.subjectProgress.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_outlined, size: 40, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text('Complétez des quiz pour voir\nvotre progression par matière',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                      ],
                    ),
                  ),
                );
              }
              final colors = [AppColors.primary, AppColors.accent, AppColors.success, AppColors.lycee, AppColors.universite];
              final subjects = s.subjectProgress.take(5).toList().asMap().entries.map((e) => {
                'name': (e.value['matiere_name'] as String?) ?? 'Matière',
                'progress': ((e.value['completion'] as num?)?.toDouble() ?? 0.0) / 100,
                'color': colors[e.key % colors.length],
              }).toList();

              final avgProgress = subjects.isEmpty
                  ? 0.0
                  : subjects.map((s) => s['progress'] as double).reduce((a, b) => a + b) / subjects.length;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80, height: 80,
                        child: CircularProgressIndicator(
                          value: avgProgress,
                          strokeWidth: 10,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      Text('${(avgProgress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: subjects.map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(s['name'] as String,
                                  style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: s['progress'] as double,
                                  minHeight: 6,
                                  backgroundColor: (s['color'] as Color).withValues(alpha: 0.12),
                                  valueColor: AlwaysStoppedAnimation(s['color'] as Color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '${((s['progress'] as double) * 100).toInt()}%',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: s['color'] as Color),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Recent Activity (unified feed) ─────────────────────────────────────────

  Widget _buildRecentActivity() {
    final activityAsync = ref.watch(activityProvider);

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
          const Text('Activité récente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          activityAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(strokeWidth: 2),
            )),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Impossible de charger l\'activité',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Aucune activité récente',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                );
              }
              return Column(
                children: items.take(10).map((item) => _ActivityItem(item)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Badges ─────────────────────────────────────────────────────────────────

  Widget _buildBadgesSection(AsyncValue<List<BadgeModel>> badgesAsync) {
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
          const Text('Mes badges', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          badgesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const Text('Impossible de charger les badges',
                style: TextStyle(color: AppColors.textSecondary)),
            data: (badges) {
              if (badges.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 36, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text('Aucun badge encore — complétez des quiz !',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: badges.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final badge = badges[i];
                    return Column(
                      children: [
                        Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(child: Text(badge.icon, style: const TextStyle(fontSize: 24))),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60,
                          child: Text(badge.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatFcfa(int amount) {
    if (amount == 0) return 'Portefeuille';
    final s = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '$s FCFA';
  }
}

// ── Activity item row ─────────────────────────────────────────────────────────

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ActivityItem(this.item);

  static const _typeConfig = {
    'download': {
      'icon': Icons.download_rounded,
      'color': Color(0xFF0CA678),
    },
    'quiz': {
      'icon': Icons.quiz_rounded,
      'color': Color(0xFF7048E8),
    },
    'forum': {
      'icon': Icons.forum_rounded,
      'color': Color(0xFF1C7ED6),
    },
    'purchase': {
      'icon': Icons.shopping_bag_rounded,
      'color': Color(0xFFE67700),
    },
  };

  @override
  Widget build(BuildContext context) {
    final type = item['type'] as String? ?? 'download';
    final cfg = _typeConfig[type] ?? _typeConfig['download']!;
    final color = cfg['color'] as Color;
    final icon = cfg['icon'] as IconData;
    final title = item['title'] as String? ?? '';
    final subtitle = item['subtitle'] as String? ?? '';
    final timestamp = item['timestamp'] as String?;
    final extra = item['extra'] as Map<String, dynamic>? ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatDate(timestamp),
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
              if (type == 'purchase' && extra['amount'] != null)
                Text('${extra['amount']} FCFA',
                    style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
              if (type == 'quiz' && extra['score'] != null)
                Text('${extra['score']}%',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF7048E8), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays == 1) return 'Hier';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}

// ── Simple list bottom sheet ──────────────────────────────────────────────────

class _SimpleListSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final AsyncValue<List<Map<String, dynamic>>> provider;
  final String labelKey;
  final String? subtitleKey;
  final String subtitleSuffix;

  const _SimpleListSheet({
    required this.title,
    required this.icon,
    required this.provider,
    required this.labelKey,
    this.subtitleKey,
    this.subtitleSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: provider.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Erreur de chargement')),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          const Text('Aucun élément', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final label = item[labelKey]?.toString() ?? '—';
                      final sub = subtitleKey != null ? item[subtitleKey]?.toString() : null;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 18, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                            if (sub != null)
                              Text('$sub$subtitleSuffix',
                                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity tile (stats grid) ────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ActivityTile(this.data);

  @override
  Widget build(BuildContext context) {
    final color = data['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data['icon'] as IconData, color: color, size: 20),
          const SizedBox(height: 8),
          Text(data['value'] as String,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(data['label'] as String,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
