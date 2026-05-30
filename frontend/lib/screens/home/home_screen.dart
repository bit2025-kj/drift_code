import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/models/document_model.dart';
import 'package:nafa_edu/providers/document_provider.dart';
import 'package:nafa_edu/providers/auth_provider.dart';
import 'package:nafa_edu/providers/education_provider.dart';
import 'package:nafa_edu/screens/banque/document_detail_screen.dart';
import 'package:nafa_edu/screens/banque/document_reader_screen.dart';
import 'package:nafa_edu/screens/main_shell.dart';
import 'package:nafa_edu/screens/home/publish_sheet.dart';
import 'package:nafa_edu/providers/notification_provider.dart';
import 'package:nafa_edu/screens/ai_chat/ai_chat_screen.dart';
import 'package:nafa_edu/screens/notifications/notification_screen.dart';
import 'package:nafa_edu/screens/marketplace/teacher_request_screen.dart';
import 'package:nafa_edu/screens/downloads_screen.dart';
import 'package:nafa_edu/widgets/network_error_widget.dart';
import 'package:nafa_edu/core/utils/auth_utils.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final trending = ref.watch(trendingDocumentsProvider);
    final newDocs = ref.watch(newDocumentsProvider);
    final recentDownloads = ref.watch(myRecentDownloadsProvider);
    final levelsAsync = ref.watch(levelsProvider);
    final notifCount = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Clean Top Bar ──
              SliverToBoxAdapter(child: _buildTopBar(context, user, notifCount)),
              
              // ── Onboarding Carousel (Simplified) ──
              const SliverToBoxAdapter(child: _OnboardingCarousel()),
              
              // ── Search + Categories ──
              SliverToBoxAdapter(child: _buildSearchRow(context, ref)),
              SliverToBoxAdapter(child: _buildCategories(context, ref, levelsAsync)),
              
              // ── Trending Documents ──
              SliverToBoxAdapter(
                child: _buildSectionHeader('🔥 Tendances', 'Voir tout ›',
                  onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
                ),
              ),
              SliverToBoxAdapter(
                child: trending.when(
                  data: (docs) => docs.isEmpty
                      ? _buildEmptySection('Aucun document tendance')
                      : _buildTrendingCards(context, ref, docs),
                  loading: () => _buildShimmerRow(155, 185),
                  error: (e, _) => NetworkErrorWidget(error: e, compact: true, onRetry: () => ref.invalidate(trendingDocumentsProvider)),
                ),
              ),
              
              // ── Recent Downloads (Revision) ──
              SliverToBoxAdapter(
                child: _buildSectionHeader('⏱ Continuer la révision', 'Voir tout ›',
                  onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
                ),
              ),
              SliverToBoxAdapter(
                child: recentDownloads.when(
                  data: (docs) => docs.isEmpty
                      ? _buildRevisionEmpty(context, ref)
                      : _buildRevisionCards(context, docs),
                  loading: () => _buildShimmerRow(280, 80),
                  error: (_, __) => _buildRevisionEmpty(context, ref),
                ),
              ),
              
              // ── New Documents ──
              SliverToBoxAdapter(
                child: _buildSectionHeader('🆕 Nouveaux sujets', 'Voir tout ›',
                  onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
                ),
              ),
              SliverToBoxAdapter(
                child: newDocs.when(
                  data: (docs) => docs.isEmpty
                      ? _buildEmptySection('Aucun nouveau document')
                      : _buildNewDocs(context, ref, docs),
                  loading: () => _buildShimmerRow(140, 160),
                  error: (e, _) => NetworkErrorWidget(error: e, compact: true, onRetry: () => ref.invalidate(newDocumentsProvider)),
                ),
              ),
              
              // ── AI Recommendation ──
              SliverToBoxAdapter(
                child: _buildSectionHeader('⭐ Recommandés pour toi', 'Voir tout ›',
                  onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
                ),
              ),
              SliverToBoxAdapter(child: _buildRecommendedSection(context, ref)),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          
          // ── Minimal Draggable FABs ──
          _DraggableFABGroup(
            onAITap: () async {
              if (!await requireAuth(context, ref)) return;
              if (!context.mounted) return;
              _showAIChat(context);
            },
            onPublishTap: () async {
              if (!await requireAuth(context, ref)) return;
              if (!context.mounted) return;
              _showPublishSheet(context);
            },
          ),
        ],
      ),
    );
  }

  // ── CLEAN TOP BAR ──
  Widget _buildTopBar(BuildContext context, dynamic user, int notifCount) {
    final firstName = user?.fullName?.split(' ').first ?? '';
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 12),
      child: Row(
        children: [
          Image.asset('assets/logo.jpeg', width: 44, height: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nafa Edu',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  firstName.isNotEmpty ? 'Bonjour, $firstName 👋' : 'Révise. Apprends. Réussis.',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
            child: Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.textTertiary),
                ),
                if (notifCount > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          notifCount > 9 ? '9+' : '$notifCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CLEAN SEARCH ROW ──
  Widget _buildSearchRow(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: TextField(
                onChanged: (value) {},
                decoration: InputDecoration(
                  hintText: 'Rechercher un sujet...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── UNIFORM CATEGORIES ──
  Widget _buildCategories(BuildContext context, WidgetRef ref, AsyncValue<List<EducationLevel>> levelsAsync) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 88,
        child: levelsAsync.when(
          loading: () => _buildShimmerRow(76, 88),
          error: (_, __) => const SizedBox.shrink(),
          data: (levels) => ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: levels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final level = levels[i];
              final icons = [
                Icons.child_care_rounded,
                Icons.menu_book_rounded,
                Icons.school_rounded,
                Icons.account_balance_rounded,
                Icons.emoji_events_rounded,
              ];
              final icon = icons[i % icons.length];
              
              return GestureDetector(
                onTap: () {
                  ref.read(banqueLevelFilterProvider.notifier).state = level.id;
                  ref.read(tabIndexProvider.notifier).state = 1;
                },
                child: Container(
                  width: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: AppColors.primary, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        level.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── SECTION HEADER ──
  Widget _buildSectionHeader(String title, String action, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      child: Row(
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(action, style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── TRENDING CARDS (MINIMAL) ──
  Widget _buildTrendingCards(BuildContext context, WidgetRef ref, List<DocumentModel> docs) {
    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: docs.length.clamp(0, 8),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final doc = docs[i];
          final isBadged = doc.isOfficial || i % 3 == 0;
          
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentReaderScreen(document: doc))),
            child: Container(
              width: 155,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  if (isBadged)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'OFFICIEL',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ),
                  
                  // Icon
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        doc.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      doc.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3),
                    ),
                  ),
                  
                  // Stats
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite_rounded, size: 12, color: AppColors.error),
                        Text(' ${doc.likesCount}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        Text('• ${_formatCount(doc.downloadsCount)} téléch.', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  
                  // AI Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: GestureDetector(
                      onTap: () async {
                        if (!await requireAuth(context, ref)) return;
                        if (!context.mounted) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AiChatScreen(attachedDocument: doc)));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text('Analyser', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── REVISION CARDS ──
  Widget _buildRevisionCards(BuildContext context, List<DocumentModel> docs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: docs.asMap().entries.map((entry) {
          final doc = entry.value;
          
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.title,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${doc.classeName ?? ''} ${doc.matiereName != null ? '• ${doc.matiereName}' : ''}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.download_done_rounded, size: 13, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text('Téléchargé', style: GoogleFonts.inter(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRevisionEmpty(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commence ta révision', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('Télécharge des sujets', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── NEW DOCUMENTS ──
  Widget _buildNewDocs(BuildContext context, WidgetRef ref, List<DocumentModel> docs) {
    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: docs.length.clamp(0, 6),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final doc = docs[i];
          
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentReaderScreen(document: doc))),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('NOUVEAU', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc))),
                          child: const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(doc.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3)),
                        if (doc.levelName != null)
                          Text(doc.levelName!, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: GestureDetector(
                      onTap: () async {
                        if (!await requireAuth(context, ref)) return;
                        if (!context.mounted) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AiChatScreen(attachedDocument: doc)));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text('Analyser', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── RECOMMENDED SECTION (MINIMAL) ──
  Widget _buildRecommendedSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quiz IA personnalisé', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Génère un quiz adapté à ton niveau', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => ref.read(tabIndexProvider.notifier).state = 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text('Créer', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── EMPTY STATE ──
  Widget _buildEmptySection(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(msg, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
    );
  }

  // ── SHIMMER PLACEHOLDER ──
  Widget _buildShimmerRow(double width, double height) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: width,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  String _formatCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  void _showPublishSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const PublishSheet());
  }

  void _showAIChat(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
  }
}

// ── CLEAN ONBOARDING CAROUSEL ──
class _OnboardingCarousel extends ConsumerStatefulWidget {
  const _OnboardingCarousel();

  @override
  ConsumerState<_OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends ConsumerState<_OnboardingCarousel> {
  late final PageController _pageCtrl;
  Timer? _timer;
  int _page = 0;
  static const _count = 3;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_page + 1) % _count;
      _pageCtrl.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToDownloads() => Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));

  Widget _downloadBtn() => GestureDetector(
    onTap: _goToDownloads,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.download_rounded, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text('Télécharger', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;
    final topBarH = safeTop + 68.0;
    final cardH = ((screenH - topBarH - 60) / 2).clamp(190.0, 265.0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            height: cardH,
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _page = i),
              children: [_buildCard1(cardH), _buildCard2(cardH), _buildCard3(cardH)],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_count, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCard1(double cardH) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4752E8), Color(0xFF5863F8), Color(0xFF7485FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(right: -40, top: -40, child: Container(width: 180, height: 180, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
            Positioned(left: -20, bottom: 20, child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), shape: BoxShape.circle))),
            Positioned(right: 0, bottom: 0, child: Image.asset('assets/images/hero_student.png', height: cardH * 0.88, fit: BoxFit.contain)),
            Positioned(
              left: 20,
              top: 18,
              right: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prépare tes examens avec Nafa Edu', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
                  const SizedBox(height: 8),
                  Text('Des milliers de sujets et une IA pour réussir.', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.8), height: 1.4)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => ref.read(tabIndexProvider.notifier).state = 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_circle_filled_rounded, color: AppColors.primary, size: 14),
                          const SizedBox(width: 5),
                          Text('Commencer', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _downloadBtn(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard2(double cardH) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4752E8), Color(0xFF5863F8), Color(0xFF7485FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(right: -40, top: -40, child: Container(width: 190, height: 190, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
            Positioned(left: -20, bottom: 20, child: Container(width: 110, height: 110, decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), shape: BoxShape.circle))),
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 18,
              right: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('ENSEIGNANT', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4)),
                  ),
                  const SizedBox(height: 10),
                  Text('Partage tes cours', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
                  const SizedBox(height: 6),
                  Text('Aide les élèves du Burkina.', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherRequestScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.send_rounded, color: AppColors.primary, size: 13),
                          const SizedBox(width: 5),
                          Text('Candidature', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _downloadBtn(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard3(double cardH) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(right: -40, top: -40, child: Container(width: 190, height: 190, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
            Positioned(left: -20, bottom: 20, child: Container(width: 110, height: 110, decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), shape: BoxShape.circle))),
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 38),
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 18,
              right: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('I.A.', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 10),
                  Text('Assistant IA', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
                  const SizedBox(height: 6),
                  Text('Quiz & révisions intelligentes.', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      if (!await requireAuth(context, ref)) return;
                      if (!mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_rounded, color: AppColors.success, size: 13),
                          const SizedBox(width: 5),
                          Text('Discuter', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _downloadBtn(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── MINIMAL DRAGGABLE FAB GROUP (iOS GLASSMORPHISM) ──
class _DraggableFABGroup extends StatefulWidget {
  final VoidCallback onAITap;
  final VoidCallback onPublishTap;
  const _DraggableFABGroup({required this.onAITap, required this.onPublishTap});

  @override
  State<_DraggableFABGroup> createState() => _DraggableFABGroupState();
}

class _DraggableFABGroupState extends State<_DraggableFABGroup> {
  double _top = -1;
  bool _expanded = true;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _scheduleCollapse();
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _scheduleCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _expanded = false);
    });
  }

  void _wake() {
    setState(() => _expanded = true);
    _scheduleCollapse();
  }

  @override
  Widget build(BuildContext context) {
    if (_top < 0) _top = MediaQuery.of(context).size.height * 0.58;

    return Positioned(
      top: _top,
      right: 16,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) {
          setState(() {
            final minTop = MediaQuery.of(context).padding.top + 80.0;
            final maxTop = MediaQuery.of(context).size.height - 180.0;
            _top = (_top + d.delta.dy).clamp(minTop, maxTop);
          });
          _wake();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildFAB(
              icon: Icons.psychology_rounded,
              label: "IA",
              color: const Color(0xFF5863F8),
              onTap: () { _wake(); widget.onAITap(); },
            ),
            const SizedBox(height: 8),
            _buildFAB(
              icon: Icons.add_rounded,
            
              label: 'Publier',
              color: AppColors.primary,
              onTap: () { _wake(); widget.onPublishTap(); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: _expanded ? 14 : 12, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 40),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _expanded
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 18),
                              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
