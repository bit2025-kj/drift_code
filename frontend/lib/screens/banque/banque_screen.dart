import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafa_edu/config/constants.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/models/document_model.dart';
import 'package:nafa_edu/providers/document_provider.dart';
import 'package:nafa_edu/screens/banque/document_detail_screen.dart';
import 'package:nafa_edu/screens/banque/document_reader_screen.dart';
import 'package:nafa_edu/providers/education_provider.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/services/download_manager.dart';
import 'package:nafa_edu/screens/main_shell.dart';
import 'package:nafa_edu/screens/downloads_screen.dart';
import 'package:nafa_edu/screens/ai_chat/ai_chat_screen.dart';
import 'package:nafa_edu/services/sync_service.dart';
import 'package:nafa_edu/widgets/network_error_widget.dart';
import 'package:nafa_edu/screens/home/publish_sheet.dart';
import 'package:nafa_edu/providers/notification_provider.dart';
import 'package:nafa_edu/screens/notifications/notification_screen.dart';
import 'package:shimmer/shimmer.dart';

class BanqueScreen extends ConsumerStatefulWidget {
  const BanqueScreen({super.key});

  @override
  ConsumerState<BanqueScreen> createState() => _BanqueScreenState();
}

class _BanqueScreenState extends ConsumerState<BanqueScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  int? _selectedLevel;
  int? _selectedClasse;
  int? _selectedMatiere;
  int? _selectedTypeExamen;
  int? _selectedAnnee;
  bool? _hasCorrige;
  String _sortBy = 'recent';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final levelId = ref.read(banqueLevelFilterProvider);
      if (levelId != null) {
        setState(() => _selectedLevel = levelId);
        _applyFilters();
        ref.read(banqueLevelFilterProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(documentProvider.notifier).applyFilter(
      DocumentFilter(
        levelId: _selectedLevel,
        classeId: _selectedClasse,
        matiereId: _selectedMatiere,
        typeExamenId: _selectedTypeExamen,
        annee: _selectedAnnee,
        hasCorrige: _hasCorrige,
        q: _searchController.text.isEmpty ? null : _searchController.text,
        sortBy: _sortBy,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedLevel = null;
      _selectedClasse = null;
      _selectedMatiere = null;
      _selectedTypeExamen = null;
      _selectedAnnee = null;
      _hasCorrige = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(banqueLevelFilterProvider, (_, next) {
      if (next != null) {
        setState(() => _selectedLevel = next);
        _applyFilters();
        ref.read(banqueLevelFilterProvider.notifier).state = null;
      }
    });

    final state = ref.watch(documentProvider);
    final notifCount = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, notifCount)),
          SliverToBoxAdapter(child: _buildSearchRow(context)),
          SliverToBoxAdapter(child: _buildActionButtons(context)),
          SliverToBoxAdapter(child: _buildTypeCards()),
          SliverToBoxAdapter(child: _buildFilterSection()),
          SliverToBoxAdapter(child: _buildResultsHeader(state)),
          if (state.isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (state.error != null)
            SliverFillRemaining(
              child: OfflineAwareErrorWidget(
                isOffline: !ref.watch(isOnlineProvider),
                onRetry: _applyFilters,
              ),
            )
          else if (state.documents.isEmpty)
            SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFDEE2E6)),
                  const SizedBox(height: 12),
                  Text('Aucun résultat trouvé',
                      style: GoogleFonts.inter(color: const Color(0xFF868E96), fontSize: 15, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _DocumentCard(doc: state.documents[i]),
                childCount: state.documents.length,
              ),
            ),
          SliverToBoxAdapter(child: _buildOfflineBanner(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, int notifCount) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Banque de sujets',
                    style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23))),
                const SizedBox(height: 2),
                Text('Trouvez et révisez les meilleurs sujets',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF868E96), fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: Color(0xFFF1F3F5), shape: BoxShape.circle),
            child: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF495057)),
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
                  width: 40, height: 40,
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

  // ── Search + Filtres ──────────────────────────────────────────────────────────

  void _onSearchChanged(String _) {
    setState(() {}); // refresh suffix icon
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _applyFilters);
  }

  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) => _applyFilters(),
          onChanged: _onSearchChanged,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Rechercher un sujet, une matière, un examen...',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFADB5BD)),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFFADB5BD)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFFADB5BD)),
                    onPressed: () { _searchController.clear(); _applyFilters(); },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7048E8), Color(0xFF3B5BDB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7048E8).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Causer avec l'IA",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const PublishSheet(),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Ajouter un sujet',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Level quick-select ────────────────────────────────────────────────────────

  IconData _levelIconFor(String slug) {
    switch (slug) {
      case 'primaire': return Icons.child_friendly_rounded;
      case 'college': return Icons.school_rounded;
      case 'lycee': return Icons.auto_stories_rounded;
      case 'universite': return Icons.account_balance_rounded;
      case 'concours': return Icons.emoji_events_rounded;
      default: return Icons.folder_rounded;
    }
  }

  Color _levelColorFor(String? hex) {
    if (hex == null) return AppColors.primary;
    try {
      return Color(int.parse('FF${hex.replaceAll("#", "")}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Widget _buildLevelCard(String label, IconData icon, bool selected, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 80,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? accent : const Color(0xFFE9ECEF), width: selected ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: selected ? accent : const Color(0xFF868E96)),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : const Color(0xFF495057),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCards() {
    final levelsAsync = ref.watch(levelsProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 82,
        child: levelsAsync.when(
          loading: () => ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, __) => Shimmer.fromColors(
              baseColor: const Color(0xFFE9ECEF),
              highlightColor: const Color(0xFFF8F9FA),
              child: Container(width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (levels) => ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: levels.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                return _buildLevelCard('Tous', Icons.apps_rounded, _selectedLevel == null, AppColors.primary, () {
                  setState(() { _selectedLevel = null; _selectedClasse = null; _selectedTypeExamen = null; });
                  _applyFilters();
                });
              }
              final level = levels[i - 1];
              final selected = _selectedLevel == level.id;
              final color = _levelColorFor(level.color);
              return _buildLevelCard(level.name, _levelIconFor(level.slug), selected, color, () {
                setState(() {
                  _selectedLevel = selected ? null : level.id;
                  _selectedClasse = null;
                  _selectedTypeExamen = null;
                });
                _applyFilters();
              });
            },
          ),
        ),
      ),
    );
  }

  // ── Filter section inline ─────────────────────────────────────────────────────

  void _showOptionSheet({
    required BuildContext ctx,
    required String title,
    required List<(String, int?)> options,
    required int? current,
    required void Function(int?) onSelect,
  }) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.55),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFDEE2E6), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 14),
                  Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    for (final (label, id) in options)
                      GestureDetector(
                        onTap: () {
                          onSelect(current == id ? null : id);
                          Navigator.pop(sheetCtx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: current == id ? AppColors.primary : const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: current == id ? AppColors.primary : const Color(0xFFE9ECEF)),
                          ),
                          child: Text(label,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: current == id ? Colors.white : const Color(0xFF495057))),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickLevel(BuildContext ctx) {
    final levels = ref.read(levelsProvider).valueOrNull ?? [];
    _showOptionSheet(
      ctx: ctx, title: 'Niveau scolaire',
      options: [('Tous', null), ...levels.map((l) => (l.name, l.id as int?))],
      current: _selectedLevel,
      onSelect: (id) {
        setState(() { _selectedLevel = id; _selectedClasse = null; _selectedTypeExamen = null; });
        _applyFilters();
      },
    );
  }

  void _pickClasse(BuildContext ctx) {
    final levels = ref.read(levelsProvider).valueOrNull ?? [];
    final classes = _selectedLevel != null
        ? (levels.where((l) => l.id == _selectedLevel).firstOrNull?.classes ?? [])
        : levels.expand((l) => l.classes).toList();
    if (classes.isEmpty) return;
    _showOptionSheet(
      ctx: ctx, title: 'Classe',
      options: [('Toutes', null), ...classes.map((c) => (c.name, c.id as int?))],
      current: _selectedClasse,
      onSelect: (id) { setState(() => _selectedClasse = id); _applyFilters(); },
    );
  }

  void _pickMatiere(BuildContext ctx) {
    final matieres = ref.read(matieresProvider).valueOrNull ?? [];
    _showOptionSheet(
      ctx: ctx, title: 'Matière',
      options: [('Toutes', null), ...matieres.map((m) => (m.name, m.id as int?))],
      current: _selectedMatiere,
      onSelect: (id) { setState(() => _selectedMatiere = id); _applyFilters(); },
    );
  }

  void _pickType(BuildContext ctx) {
    final types = _selectedLevel != null
        ? (ref.read(typesExamensByLevelProvider(_selectedLevel)).valueOrNull ?? [])
        : (ref.read(typesExamensProvider).valueOrNull ?? []);
    if (types.isEmpty) return;
    _showOptionSheet(
      ctx: ctx, title: 'Type d\'examen',
      options: [('Tous', null), ...types.map((t) => (t.name, t.id as int?))],
      current: _selectedTypeExamen,
      onSelect: (id) { setState(() => _selectedTypeExamen = id); _applyFilters(); },
    );
  }

  void _pickAnnee(BuildContext ctx) {
    final years = ref.read(yearsProvider).valueOrNull ?? [];
    _showOptionSheet(
      ctx: ctx, title: 'Année',
      options: [('Toutes', null), ...years.map((y) => ('$y', y as int?))],
      current: _selectedAnnee,
      onSelect: (id) { setState(() => _selectedAnnee = id); _applyFilters(); },
    );
  }

  Widget _buildFilterSection() {
    final levels = ref.watch(levelsProvider).valueOrNull ?? [];
    final matieres = ref.watch(matieresProvider).valueOrNull ?? [];
    final allTypes = ref.watch(typesExamensProvider).valueOrNull ?? [];

    String levelLabel = 'Tous';
    String classeLabel = 'Toutes';
    if (_selectedLevel != null) {
      final level = levels.where((l) => l.id == _selectedLevel).firstOrNull;
      levelLabel = level?.name ?? '—';
      if (_selectedClasse != null) {
        classeLabel = level?.classes.where((c) => c.id == _selectedClasse).firstOrNull?.name ?? '—';
      }
    }
    final matiereLabel = _selectedMatiere != null
        ? (matieres.where((m) => m.id == _selectedMatiere).firstOrNull?.name ?? '—')
        : 'Toutes';
    final typeLabel = _selectedTypeExamen != null
        ? (allTypes.where((t) => t.id == _selectedTypeExamen).firstOrNull?.name ?? '—')
        : 'Tous';

    final activeCount = [
      _selectedLevel, _selectedClasse, _selectedMatiere, _selectedTypeExamen, _selectedAnnee,
    ].where((v) => v != null).length + (_hasCorrige == true ? 1 : 0);

    final chips = [
      (Icons.school_rounded,        'Niveau',       levelLabel,                                  () => _pickLevel(context)),
      (Icons.people_rounded,         'Classe',       classeLabel,                                 () => _pickClasse(context)),
      (Icons.menu_book_rounded,      'Matière',      matiereLabel,                               () => _pickMatiere(context)),
      (Icons.folder_rounded,         'Type examen',  typeLabel,                                   () => _pickType(context)),
      (Icons.calendar_today_rounded, 'Année',        _selectedAnnee != null ? '$_selectedAnnee' : 'Toutes', () => _pickAnnee(context)),
      (Icons.check_circle_rounded,   'Avec corrigé', _hasCorrige == true ? 'Oui' : 'Tous',
          () { setState(() => _hasCorrige = _hasCorrige == true ? null : true); _applyFilters(); }),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Affiner votre recherche',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23))),
              if (activeCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                  child: Text('$activeCount', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
              const Spacer(),
              if (activeCount > 0)
                GestureDetector(
                  onTap: _resetFilters,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text('Réinitialiser',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ]),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.0,
            children: [
              for (final (icon, label, value, onTap) in chips)
                GestureDetector(
                  onTap: onTap,
                  child: _buildFilterChip({'icon': icon, 'label': label, 'value': value}),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(Map<String, dynamic> filter) {
    final hasValue = filter['value'] != 'Tous' && filter['value'] != 'Toutes' && filter['value'] != '—';
    return Container(
      decoration: BoxDecoration(
        color: hasValue ? AppColors.primary.withValues(alpha: 0.05) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasValue ? AppColors.primary.withValues(alpha: 0.2) : const Color(0xFFE9ECEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          children: [
            Icon(filter['icon'] as IconData, size: 12,
                color: hasValue ? AppColors.primary : const Color(0xFF868E96)),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(filter['label'] as String,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF868E96), fontWeight: FontWeight.w500)),
                  Text(filter['value'] as String,
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          color: hasValue ? AppColors.primary : const Color(0xFF495057),
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: Color(0xFFADB5BD)),
          ],
        ),
      ),
    );
  }

  // ── Results header ────────────────────────────────────────────────────────────

  Widget _buildResultsHeader(DocumentListState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${state.total} ',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                TextSpan(
                  text: 'résultats trouvés',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF495057)),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showSortSheet(context),
            child: Row(
              children: [
                Text('Trier par ', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF868E96))),
                Text(_sortLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _isGridView = false),
            child: Icon(Icons.view_list_rounded,
                size: 22, color: !_isGridView ? AppColors.primary : const Color(0xFFADB5BD)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _isGridView = true),
            child: Icon(Icons.grid_view_rounded,
                size: 22, color: _isGridView ? AppColors.primary : const Color(0xFFADB5BD)),
          ),
        ],
      ),
    );
  }

  String get _sortLabel {
    switch (_sortBy) {
      case 'popular': return 'Populaires';
      case 'likes': return 'Plus aimés';
      default: return 'Plus récents';
    }
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDEE2E6), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Trier par', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...['recent', 'popular', 'likes'].map((v) {
              final labels = {'recent': 'Plus récents', 'popular': 'Populaires', 'likes': 'Plus aimés'};
              final sel = _sortBy == v;
              return ListTile(
                title: Text(labels[v]!, style: GoogleFonts.inter(fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                trailing: sel ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _sortBy = v);
                  _applyFilters();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Offline banner ────────────────────────────────────────────────────────────

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B5BDB), Color(0xFF4DABF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.15), shape: BoxShape.circle),
            child: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Travaillez hors ligne',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Téléchargez vos sujets et révisez même sans connexion internet.',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha:0.85), height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Voir mes\ntéléchargements',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ── Document Card ─────────────────────────────────────────────────────────────

class _DocumentCard extends ConsumerStatefulWidget {
  final DocumentModel doc;
  const _DocumentCard({required this.doc});

  @override
  ConsumerState<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends ConsumerState<_DocumentCard> {
  bool _isFavorite = false;
  bool _isDownloading = false;

  Color get _accentColor {
    final badge = widget.doc.badgeLabel;
    if (badge == 'BAC') return const Color(0xFFE03131);
    if (badge == 'BEPC' || badge == 'CEP') return const Color(0xFF1C7ED6);
    if (badge == 'CONCOURS') return const Color(0xFF2F9E44);
    if (badge.contains('EXAMEN') || badge.contains('blanc')) return const Color(0xFFE67700);
    if (widget.doc.isOfficial) return const Color(0xFF1C7ED6);
    return const Color(0xFF7048E8);
  }

  Color _badgeColor(String label) {
    if (label == 'OFFICIEL') return const Color(0xFF3B5BDB);
    if (label == 'BAC') return const Color(0xFF3B5BDB);
    if (label == 'CONCOURS') return const Color(0xFF2F9E44);
    if (label.contains('EXAMEN')) return const Color(0xFFE67700);
    if (label == 'COMMUNAUTÉ') return const Color(0xFF7048E8);
    return AppColors.primary;
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);
    try {
      await ApiClient.instance.dio.post(ApiEndpoints.favoriteDocument(widget.doc.id));
    } catch (_) {
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    }
  }

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      final path = await DownloadManager.instance.downloadDocument(widget.doc);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(path != null ? '${widget.doc.title} téléchargé' : 'Erreur de téléchargement'),
          backgroundColor: path != null ? AppColors.success : AppColors.error,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de téléchargement'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  // ── Preview (top half) ────────────────────────────────────────────────────────

  Widget _buildPreview(DocumentModel doc) {
    if (doc.isImage && doc.fileUrl != null) {
      return _buildImagePreview(doc);
    }
    if (!doc.isImage && doc.thumbnailUrl != null) {
      return _buildThumbnailPreview(doc);
    }
    return _buildPdfPreview(doc);
  }

  Widget _buildThumbnailPreview(DocumentModel doc) {
    final url = doc.thumbnailUrl!.startsWith('http') 
        ? doc.thumbnailUrl! 
        : '${AppConstants.baseUrl}${doc.thumbnailUrl}';
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildShimmer(),
          errorWidget: (_, __, ___) => _buildPdfPreview(doc),
        ),
        Positioned(
          left: 0, right: 0, bottom: 0, height: 48,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8, right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf_rounded, size: 10, color: Colors.white),
                const SizedBox(width: 4),
                Text('PDF', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ),
        if (doc.annee != null)
          Positioned(
            bottom: 8, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${doc.annee}',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview(DocumentModel doc) {
    final url = doc.fileUrl!.startsWith('http') 
        ? doc.fileUrl! 
        : '${AppConstants.baseUrl}${doc.fileUrl}';
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildShimmer(),
          errorWidget: (_, __, ___) => Container(
            color: const Color(0xFF1A1D23),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_rounded, color: Colors.white.withValues(alpha: 0.3), size: 36),
                const SizedBox(height: 6),
                Text('IMAGE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white38)),
              ],
            ),
          ),
        ),
        // bottom gradient for readability
        Positioned(
          left: 0, right: 0, bottom: 0, height: 48,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
              ),
            ),
          ),
        ),
        // image badge bottom-right
        Positioned(
          bottom: 8, right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_rounded, size: 10, color: Colors.white),
                const SizedBox(width: 4),
                Text('IMAGE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfPreview(DocumentModel doc) {
    final color = _accentColor;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.25)!],
        ),
      ),
      child: Stack(
        children: [
          // subtle dot pattern
          Positioned.fill(
            child: CustomPaint(painter: _DotPatternPainter(Colors.white.withValues(alpha: 0.06))),
          ),
          // centered icon + file size
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  doc.fileSizeLabel,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // PDF badge bottom-right
          Positioned(
            bottom: 8, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, size: 10, color: Colors.white),
                  const SizedBox(width: 4),
                  Text('PDF', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
          ),
          // annee badge bottom-left
          if (doc.annee != null)
            Positioned(
              bottom: 8, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${doc.annee}',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE9ECEF),
      highlightColor: const Color(0xFFF8F9FA),
      child: Container(color: Colors.white),
    );
  }

  Widget _buildBadgePill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final badge = doc.badgeLabel;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DocumentReaderScreen(document: doc)),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9ECEF)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top: preview ─────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 148,
                    width: double.infinity,
                    child: _buildPreview(doc),
                  ),
                ),
                // type badge — top-left
                if (badge.isNotEmpty)
                  Positioned(
                    top: 10, left: 10,
                    child: _buildBadgePill(badge, _badgeColor(badge)),
                  ),
                if (doc.isOfficial)
                  Positioned(
                    top: 10, left: badge.isNotEmpty ? null : 10,
                    right: badge.isNotEmpty ? null : null,
                    child: Padding(
                      padding: EdgeInsets.only(left: badge.isNotEmpty ? 60 : 0),
                      child: _buildBadgePill('OFFICIEL', _badgeColor('OFFICIEL')),
                    ),
                  ),
                // bookmark — top-right
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        size: 16,
                        color: _isFavorite ? const Color(0xFFFFD43B) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Bottom: info ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          doc.title,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D23)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                  if ([doc.classeName, doc.matiereName].any((e) => e != null)) ...[
                    const SizedBox(height: 3),
                    Text(
                      [doc.classeName, doc.matiereName].where((e) => e != null).join(' • '),
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF868E96)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.download_outlined, size: 13, color: Color(0xFF868E96)),
                      const SizedBox(width: 3),
                      Text(_formatCount(doc.downloadsCount),
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF868E96))),
                      const SizedBox(width: 8),
                      const Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFE03131)),
                      const SizedBox(width: 3),
                      Text(
                        _formatCount(doc.likesCount),
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF868E96)),
                      ),
                      if (doc.hasCorrige) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD3F9D8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Corrigé',
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF2F9E44))),
                        ),
                      ],
                      const Spacer(),
                      // AI button
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AiChatScreen(attachedDocument: widget.doc),
                          ),
                        ),
                        child: Container(
                          width: 30, height: 30,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7048E8).withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.smart_toy_rounded, size: 15, color: Color(0xFF7048E8)),
                        ),
                      ),
                      // Download button
                      GestureDetector(
                        onTap: _isDownloading ? null : _download,
                        child: _isDownloading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.download_rounded, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text('Télécharger',
                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dot pattern painter for PDF preview background ────────────────────────────

class _DotPatternPainter extends CustomPainter {
  final Color color;
  const _DotPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 16.0;
    const radius = 1.5;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => old.color != color;
}

