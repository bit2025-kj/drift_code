import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/db/local_database.dart';
import 'package:nafa_edu/models/document_model.dart';
import 'package:nafa_edu/screens/banque/document_reader_screen.dart';
import 'package:nafa_edu/services/download_manager.dart';
import 'package:nafa_edu/services/sync_service.dart';

class OfflineDashboardScreen extends ConsumerStatefulWidget {
  const OfflineDashboardScreen({super.key});

  @override
  ConsumerState<OfflineDashboardScreen> createState() => _OfflineDashboardScreenState();
}

class _OfflineDashboardScreenState extends ConsumerState<OfflineDashboardScreen> with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  double _storageSizeMb = 0.0;
  late AnimationController _syncAnimCtrl;

  @override
  void initState() {
    super.initState();
    _syncAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _loadStorageSize();
  }

  @override
  void dispose() {
    _syncAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStorageSize() async {
    final size = await DownloadManager.instance.getTotalSizeMb();
    if (mounted) {
      setState(() => _storageSizeMb = size);
    }
  }

  Future<void> _triggerSync() async {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Pas de connexion Internet disponible.',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });
    _syncAnimCtrl.repeat();

    try {
      final res = await SyncService.instance.syncAll();
      if (mounted) {
        _loadStorageSize();
        ref.invalidate(pendingSyncCountProvider);
        ref.invalidate(downloadsProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    res.message,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: res.failed > 0 ? AppColors.warning : AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la synchronisation : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        _syncAnimCtrl.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);
    final downloadsAsync = ref.watch(downloadsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Faso Offline First',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23)),
        ),
        actions: [
          _buildNetworkStatusTag(isOnline),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadStorageSize();
          ref.invalidate(pendingSyncCountProvider);
          ref.invalidate(downloadsProvider);
        },
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStorageWidget(),
            const SizedBox(height: 16),
            _buildSyncQueueWidget(pendingCountAsync, isOnline),
            const SizedBox(height: 24),
            _buildSectionTitle('📚 Sujets téléchargés'),
            const SizedBox(height: 10),
            _buildDownloadsSection(downloadsAsync),
            const SizedBox(height: 24),
            _buildSectionTitle('🤖 Quiz résolus en attente de sync'),
            const SizedBox(height: 10),
            _buildOfflineQuizzesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkStatusTag(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFEBFBEE) : const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? const Color(0xFFB2F2BB) : const Color(0xFFFFC9C9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF2F9E44) : const Color(0xFFE03131),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'En ligne' : 'Hors ligne',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isOnline ? const Color(0xFF2F9E44) : const Color(0xFFE03131),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageWidget() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: (_storageSizeMb / 500.0).clamp(0.02, 1.0), // Max fictif de 500Mo pour la jauge
                  strokeWidth: 8,
                  backgroundColor: const Color(0xFFF1F3F5),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF228BE6)),
                ),
              ),
              const Icon(Icons.storage_rounded, color: Color(0xFF228BE6), size: 28),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Espace Nafa Edu',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_storageSizeMb.toStringAsFixed(1)} Mo occupés',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF228BE6)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stockage local rapide et 100% hors ligne',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF868E96)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncQueueWidget(AsyncValue<int> pendingAsync, bool isOnline) {
    return pendingAsync.when(
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(),
      data: (count) {
        final hasPending = count > 0;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasPending
                  ? [const Color(0xFF1A2560), const Color(0xFF2B4ABF)]
                  : [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: hasPending ? Colors.transparent : const Color(0xFFE9ECEF)),
            boxShadow: [
              BoxShadow(
                color: hasPending
                    ? const Color(0xFF2B4ABF).withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sync_problem_rounded,
                    color: hasPending ? Colors.white : const Color(0xFF868E96),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Synchronisation asynchrone',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasPending ? Colors.white : const Color(0xFF495057),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                hasPending
                    ? '$count opération(s) en attente de réseau'
                    : 'Toutes les révisions sont synchronisées !',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: hasPending ? Colors.white : const Color(0xFF1A1D23),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasPending
                    ? 'Vos points XP, streaks et quiz résolus hors ligne seront téléversés dès le retour d\'une connexion.'
                    : 'Votre assiduité et vos scores sont pleinement à jour sur le serveur national.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: hasPending ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF868E96),
                  height: 1.4,
                ),
              ),
              if (hasPending) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _triggerSync,
                    icon: _isSyncing
                        ? RotationTransition(
                            turns: _syncAnimCtrl,
                            child: const Icon(Icons.sync_rounded, size: 16),
                          )
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: Text(
                      _isSyncing ? 'Synchronisation...' : 'Synchroniser maintenant',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A2560),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23)),
    );
  }

  Widget _buildDownloadsSection(AsyncValue<List<CachedDocument>> downloadsAsync) {
    return downloadsAsync.when(
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Erreur : $e'),
      data: (downloads) {
        if (downloads.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.download_done_rounded, color: Color(0xFFDEE2E6), size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun document hors ligne',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF868E96)),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: downloads.length,
          itemBuilder: (_, i) => _buildDownloadCard(downloads[i]),
        );
      },
    );
  }

  Widget _buildDownloadCard(CachedDocument doc) {
    final isImg = doc.isImage;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isImg ? const Color(0xFFE3F2FD) : const Color(0xFFFFEEE6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isImg ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
              color: isImg ? const Color(0xFF228BE6) : const Color(0xFFFA5252),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${doc.matiereName ?? ''} · ${doc.classeName ?? ''}',
                  style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF868E96)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isImg ? Icons.fullscreen_rounded : Icons.menu_book_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentReaderScreen(
                  document: DocumentModel(
                    id: doc.id,
                    title: doc.title,
                    levelId: 0,
                    isOfficial: doc.isOfficial,
                    hasCorrige: doc.hasCorrige,
                    downloadsCount: 0,
                    viewsCount: 0,
                    likesCount: doc.rating.toInt(),
                    fileSizeKb: doc.fileSizeKb,
                    createdAt: doc.downloadedAt,
                    fileUrl: doc.fileUrl,
                    fileType: doc.fileType,
                    levelName: doc.levelName,
                    classeName: doc.classeName,
                    matiereName: doc.matiereName,
                    typeExamenName: doc.typeExamenName,
                    annee: doc.annee,
                  ),
                  localPath: doc.localFilePath,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(
                    'Supprimer ?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  content: Text('Voulez-vous supprimer ce sujet de votre appareil ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await DownloadManager.instance.deleteDownload(doc.id);
                _loadStorageSize();
                ref.invalidate(downloadsProvider);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineQuizzesSection() {
    return FutureBuilder<List<OfflineQuizSession>>(
      future: localDb.getPendingQuizSessions(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
        }
        final sessions = snap.data ?? [];
        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.offline_bolt_outlined, color: Color(0xFFDEE2E6), size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun quiz résolu hors ligne',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF868E96)),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          itemBuilder: (_, i) {
            final s = sessions[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBFBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${s.score.toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2F9E44),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.quizTitle,
                          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${s.matiereName ?? 'Quiz'} · ${s.correctAnswers}/${s.totalQuestions} réponses correctes',
                          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF868E96)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'En attente',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD9480F),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
