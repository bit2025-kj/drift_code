import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Top bar first
              SliverToBoxAdapter(child: _buildTopBar(context, user, notifCount)),
              // Onboarding carousel (3 auto-scrolling cards)
              const SliverToBoxAdapter(child: _OnboardingCarousel()),
              // Search + categories below the hero (revealed on scroll)
              SliverToBoxAdapter(child: _buildSearchRow(context, ref)),
              SliverToBoxAdapter(child: _buildCategories(context, ref, levelsAsync)),
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  '🔥 Tendances', 'Voir tout ›',
                  onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
                ),
              ),
              SliverToBoxAdapter(
                child: trending.when(
                  data: (docs) => docs.isEmpty
                      ? _buildEmptySection('Aucun document tendance pour le moment')
                      : _buildTrendingCards(context, ref, docs),
                  loading: () => _buildShimmerRow(155, 185),
                  error: (e, _) => NetworkErrorWidget(error: e, compact: true, onRetry: () => ref.invalidate(trendingDocumentsProvider)),
                ),
),
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  '⏱ Continuer la révision', 'Voir tout ›',
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
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  '🆕 Nouveaux sujets', 'Voir tout ›',
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
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  '⭐ Recommandés pour toi', 'Voir tout ›',
                  onTap: () => ref.read(tabIndexProvider.notifier).state = 1,
                ),
              ),
              SliverToBoxAdapter(child: _buildRecommendedSection(context, ref)),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          // Draggable + collapsible FABs
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

  // ── Top bar ───────────────────────────────────────────────────────────────────

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
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Nafa ',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23)),
                      ),
                      TextSpan(
                        text: 'Edu',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary.withValues(alpha: 0.3),),
                      ),
                    ],
                  ),
                ),
                Text(
                  firstName.isNotEmpty ? 'Bonjour, $firstName 👋' : 'Révise. Apprends. Réussis.',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF868E96), fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
            child: Stack(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: const BoxDecoration(color: Color(0xFFF1F3F5), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_outlined, size: 20, color: Color(0xFF495057)),
                ),
                if (notifCount > 0)
                  Positioned(
                    top: 4, right: 4,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: Color(0xFFFA5252), shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          notifCount > 9 ? '9+' : '$notifCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
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


Widget _buildSearchRow(BuildContext context, WidgetRef ref) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE9ECEF),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                // Ici tu peux gérer la recherche
                print(value);

                // Exemple Riverpod :
                // ref.read(searchProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un sujet, une matière...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFADB5BD),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Color(0xFFADB5BD),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        GestureDetector(
          onTap: () {
            ref.read(tabIndexProvider.notifier).state = 1;
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    ),
  );
}


  // ── Categories (Primaire, Collège…) → Banque with level filter ───────────────

  Widget _buildCategories(BuildContext context, WidgetRef ref, AsyncValue<List<EducationLevel>> levelsAsync) {
    const catDesign = {
      'primaire': {'icon': Icons.child_care_rounded, 'color': Color(0xFF7048E8), 'bg': Color(0xFFF3F0FF), 'border': Color(0xFFD0BFFF)},
      'college':  {'icon': Icons.menu_book_rounded,  'color': Color(0xFF1C7ED6), 'bg': Color(0xFFE7F5FF), 'border': Color(0xFFA5D8FF)},
      'lycee':    {'icon': Icons.school_rounded,      'color': Color(0xFF2F9E44), 'bg': Color(0xFFEBFBEE), 'border': Color(0xFFB2F2BB)},
      'universite':{'icon': Icons.account_balance_rounded,'color': Color(0xFFE67700),'bg': Color(0xFFFFF4E6),'border': Color(0xFFFFD8A8)},
      'concours': {'icon': Icons.emoji_events_rounded,'color': Color(0xFFE03131), 'bg': Color(0xFFFFF5F5), 'border': Color(0xFFFFC9C9)},
    };

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
              final slug = level.slug.toLowerCase()
                  .replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('ê', 'e');
              final designKey = catDesign.keys.firstWhere(
                (k) => slug.contains(k) || k.contains(slug.split(' ').first),
                orElse: () => 'lycee',
              );
              final design = catDesign[designKey]!;
              return GestureDetector(
                onTap: () {
                  ref.read(banqueLevelFilterProvider.notifier).state = level.id;
                  ref.read(tabIndexProvider.notifier).state = 1;
                },
                child: Container(
                  width: 76,
                  decoration: BoxDecoration(
                    color: design['bg'] as Color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: design['border'] as Color),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(design['icon'] as IconData, color: design['color'] as Color, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        level.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF343A40)),
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

  // ── Section header ────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, String action, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      child: Row(
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23))),
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

  // ── Trending cards ────────────────────────────────────────────────────────────

  Widget _buildTrendingCards(BuildContext context, WidgetRef ref, List<DocumentModel> docs) {
    final pdfColors = [
      const Color(0xFFE03131), const Color(0xFF7048E8),
      const Color(0xFF1C7ED6), const Color(0xFF2F9E44), const Color(0xFFE67700),
    ];
    final badges = [
      {'label': 'OFFICIEL',  'color': const Color(0xFF2F9E44), 'bg': const Color(0xFFD3F9D8)},
      {'label': 'POPULAIRE', 'color': const Color(0xFFE67700), 'bg': const Color(0xFFFFE8CC)},
      {'label': 'NOUVEAU',   'color': const Color(0xFF3B5BDB), 'bg': const Color(0xFFDBE4FF)},
    ];

    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: docs.length.clamp(0, 8),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final doc = docs[i];
          final pdfColor = pdfColors[i % pdfColors.length];
          final badge = doc.isOfficial
              ? {'label': 'OFFICIEL', 'color': const Color(0xFF2F9E44), 'bg': const Color(0xFFD3F9D8)}
              : badges[i % badges.length];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentReaderScreen(document: doc))),
            child: Container(
              width: 155,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9ECEF)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 2))],
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
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: badge['bg'] as Color, borderRadius: BorderRadius.circular(6)),
                          child: Text(badge['label'] as String,
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: badge['color'] as Color)),
                        ),
                       GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6, top: 1),
                          child: Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFFADB5BD)),
                        ),
                      ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: pdfColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(doc.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded, color: pdfColor, size: 22),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(doc.title,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23), height: 1.3)),
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc))),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFE03131)),
                          Text(' ${doc.likesCount}',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF495057))),
                          const SizedBox(width: 4),
                          Text('• ${_formatCount(doc.downloadsCount)} téléch.',
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFADB5BD))),
                          const Spacer(),
                          const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFFADB5BD)),
                        ],
                      ),
                    ),
                  ),
                  if (doc.hasCorrige)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFD3F9D8), borderRadius: BorderRadius.circular(6)),
                        child: Text('Avec corrigé',
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: const Color(0xFF2F9E44))),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                    child: GestureDetector(
                      onTap: () async {
                        if (!await requireAuth(context, ref)) return;
                        if (!context.mounted) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AiChatScreen(attachedDocument: doc)));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF7048E8), Color(0xFF3B5BDB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text('Analyser avec l\'IA',
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
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

  // ── Revision cards ────────────────────────────────────────────────────────────

  Widget _buildRevisionCards(BuildContext context, List<DocumentModel> docs) {
    final colors = [const Color(0xFF7048E8), const Color(0xFF2F9E44), const Color(0xFF1C7ED6)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: docs.asMap().entries.map((entry) {
          final doc = entry.value;
          final color = colors[entry.key % colors.length];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc))),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9ECEF)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.picture_as_pdf_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.title,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${doc.classeName ?? ''} ${doc.matiereName != null ? '• ${doc.matiereName}' : ''}',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF868E96))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.download_done_rounded, size: 13, color: Color(0xFF2F9E44)),
                            const SizedBox(width: 4),
                            Text('Téléchargé',
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF2F9E44), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFADB5BD), size: 20),
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
            border: Border.all(color: const Color(0xFFE9ECEF)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha:0.08), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commence ta révision', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('Télécharge des sujets pour les retrouver ici',
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF868E96))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFADB5BD), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Nouveaux sujets ───────────────────────────────────────────────────────────

  Widget _buildNewDocs(BuildContext context, WidgetRef ref, List<DocumentModel> docs) {
    final pdfColors = [const Color(0xFFE03131), const Color(0xFF7048E8), const Color(0xFF1C7ED6), const Color(0xFF2F9E44)];
    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: docs.length.clamp(0, 6),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final doc = docs[i];
          final color = pdfColors[i % pdfColors.length];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentReaderScreen(document: doc))),
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9ECEF)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 6, offset: const Offset(0, 2))],
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
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFDBE4FF), borderRadius: BorderRadius.circular(6)),
                          child: Text('NOUVEAU',
                              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc))),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFADB5BD)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(doc.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded, color: color, size: 20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.title,
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D23), height: 1.35)),
                        if (doc.levelName != null)
                          Text(doc.levelName!,
                              style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF868E96)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
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
                          gradient: const LinearGradient(colors: [Color(0xFF7048E8), Color(0xFF3B5BDB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text('Analyser avec l\'IA',
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
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

  // ── Recommandés ───────────────────────────────────────────────────────────────

  Widget _buildRecommendedSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9ECEF)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.smart_toy_rounded, color: Color(0xFF3B5BDB), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quiz IA personnalisé',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23))),
                  const SizedBox(height: 3),
                  Text('Génère un quiz adapté à ton niveau et révise efficacement.',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF868E96), height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => ref.read(tabIndexProvider.notifier).state = 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B5BDB), Color(0xFF4DABF7)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text('Créer un quiz',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────────

  Widget _buildEmptySection(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(msg, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFADB5BD))),
    );
  }

  // ── Shimmer placeholder ───────────────────────────────────────────────────────

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
          decoration: BoxDecoration(color: const Color(0xFFE9ECEF), borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  String _formatCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  // ── Sheets ────────────────────────────────────────────────────────────────────

  void _showPublishSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PublishSheet(),
    );
  }

  void _showAIChat(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
  }
}

// ── Onboarding Carousel ───────────────────────────────────────────────────────

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
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_page + 1) % _count;
      _pageCtrl.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToDownloads() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));

  Widget _downloadBtn() => GestureDetector(
        onTap: _goToDownloads,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.download_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text('Télécharger',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ]),
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
              children: [_card1(cardH), _card2(cardH), _card3(cardH)],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_count, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : const Color(0xFFCED4DA),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _card1(double cardH) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A2560), Color(0xFF2B4ABF), Color(0xFF3D70D6)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned(right: -30, top: -30,
            child: Container(width: 170, height: 170,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle))),
          Positioned(left: -20, bottom: 30,
            child: Container(width: 110, height: 110,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), shape: BoxShape.circle))),
          Positioned(right: 0, bottom: 0,
            child: Image.asset('assets/images/hero_student.png',
                height: cardH * 0.88, fit: BoxFit.contain)),
          Positioned(left: 20, top: 18, right: 130,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(text: TextSpan(children: [
                TextSpan(text: 'Prépare tes examens avec ',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
                TextSpan(text: 'Nafa Edu',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFFFFC078), height: 1.3)),
              ])),
              const SizedBox(height: 7),
              Text('Des milliers de sujets et une IA pour réussir.',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.82), height: 1.5)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => ref.read(tabIndexProvider.notifier).state = 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.play_circle_filled_rounded, color: Color(0xFF1A2560), size: 15),
                    const SizedBox(width: 5),
                    Text('Commencer le quiz',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1A2560))),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              _downloadBtn(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _card2(double cardH) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A1D96), Color(0xFF6D28D9), Color(0xFF7C3AED)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned(right: -40, top: -40,
            child: Container(width: 190, height: 190,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), shape: BoxShape.circle))),
          Positioned(left: -20, bottom: 20,
            child: Container(width: 110, height: 110,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), shape: BoxShape.circle))),
          Positioned(right: 16, top: 0, bottom: 0,
            child: Center(
              child: Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 46),
              ),
            ),
          ),
          Positioned(left: 20, top: 18, right: 124,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('ESPACE ENSEIGNANT',
                  style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 8),
              Text('Deviens enseignant sur Nafa Edu',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
              const SizedBox(height: 6),
              Text('Partage tes cours et aide les élèves du Burkina.',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.82), height: 1.5)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherRequestScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.send_rounded, color: Color(0xFF6D28D9), size: 14),
                    const SizedBox(width: 5),
                    Text('Soumettre ma candidature',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF6D28D9))),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              _downloadBtn(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _card3(double cardH) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF065F46), Color(0xFF047857), Color(0xFF0D9488)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned(right: -40, top: -40,
            child: Container(width: 200, height: 200,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle))),
          Positioned(left: -20, bottom: 10,
            child: Container(width: 110, height: 110,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), shape: BoxShape.circle))),
          Positioned(right: 14, top: 0, bottom: 0,
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 82, height: 82,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 8),
                Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4 + i * 0.2),
                    shape: BoxShape.circle,
                  ),
                ))),
              ]),
            ),
          ),
          Positioned(left: 20, top: 18, right: 120,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('INTELLIGENCE ARTIFICIELLE',
                  style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 8),
              Text('Ton assistant IA pédagogique',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)),
              const SizedBox(height: 6),
              Text('Pose tes questions et génère des quiz intelligents.',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.82), height: 1.5)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  if (!await requireAuth(context, ref)) return;
                  if (!mounted) return;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.chat_bubble_rounded, color: Color(0xFF047857), size: 14),
                    const SizedBox(width: 5),
                    Text("Discuter avec l'IA",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF047857))),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              _downloadBtn(),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Draggable + collapsible FAB pair ──────────────────────────────────────────

class _DraggableFABGroup extends StatefulWidget {
  final VoidCallback onAITap;
  final VoidCallback onPublishTap;
  const _DraggableFABGroup({required this.onAITap, required this.onPublishTap});

  @override
  State<_DraggableFABGroup> createState() => _DraggableFABGroupState();
}

class _DraggableFABGroupState extends State<_DraggableFABGroup> {
  // Negative sentinel → initialised on first build from MediaQuery
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
    if (_top < 0) {
      _top = MediaQuery.of(context).size.height * 0.58;
    }

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
            _fab(
              icon: Icons.smart_toy_rounded,
              label: "Causer avec l'IA",
              color: const Color(0xFF7048E8),
              onTap: () { _wake(); widget.onAITap(); },
            ),
            const SizedBox(height: 10),
            _fab(
              icon: Icons.upload_file_rounded,
              label: 'Publier un sujet',
              color: AppColors.primary,
              onTap: () { _wake(); widget.onPublishTap(); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _fab({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: _expanded ? 16 : 13, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: color.withValues(alpha:0.4), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            // AnimatedSize collapses the label width to 0 smoothly
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
