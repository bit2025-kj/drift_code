import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafa_edu/config/constants.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/models/document_model.dart';
import 'package:nafa_edu/services/download_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class DocumentReaderScreen extends ConsumerStatefulWidget {
  final DocumentModel document;
  /// Pre-saved local file path (from downloads screen). When provided,
  /// the reader reads bytes from disk without any network request.
  final String? localPath;

  const DocumentReaderScreen({
    super.key,
    required this.document,
    this.localPath,
  });

  @override
  ConsumerState<DocumentReaderScreen> createState() =>
      _DocumentReaderScreenState();
}

class _DocumentReaderScreenState extends ConsumerState<DocumentReaderScreen> {
  // ── PDF controllers ────────────────────────────────────────────────────────
  final _pdfKey = GlobalKey<SfPdfViewerState>();
  late final PdfViewerController _pdfController;
  final _searchController = TextEditingController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();

  // ── Load state ─────────────────────────────────────────────────────────────
  Uint8List? _pdfBytes;
  double _loadProgress = 0;
  bool _isLoading = true;
  String? _error;

  // ── Reader UI state ────────────────────────────────────────────────────────
  bool _overlayVisible = true;
  bool _nightMode = false;
  bool _showSearch = false;

  // ── Reading progress ───────────────────────────────────────────────────────
  int _currentPage = 1;
  int _totalPages = 0;
  Set<int> _bookmarkedPages = {};

  DocumentModel get doc => widget.document;
  String get _posKey => 'pdf_pos_${doc.id}';
  String get _bookmarkKey => 'pdf_bm_${doc.id}';
  bool get _isBookmarked => _bookmarkedPages.contains(_currentPage);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    if (doc.isImage) {
      setState(() => _isLoading = false);
    } else {
      _loadDocument();
    }
  }

  @override
  void dispose() {
    if (!doc.isImage && _totalPages > 0) _savePdfPosition();
    if (!kIsWeb) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pdfController.dispose();
    _searchController.dispose();
    _searchResult.clear();
    super.dispose();
  }

  // ── Document loading ───────────────────────────────────────────────────────

  /// Loads PDF bytes either from a local saved file or via Dio (with auth).
  /// Using SfPdfViewer.memory avoids all CORS issues on Flutter Web and
  /// works identically on mobile/desktop.
  Future<void> _loadDocument() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadProgress = 0; _error = null; });

    try {
      Uint8List bytes;

      if (widget.localPath != null && !kIsWeb) {
        // ── Offline: read from saved file ───────────────────────────────────
        final file = File(widget.localPath!);
        if (!await file.exists()) {
          throw Exception('Fichier introuvable sur cet appareil');
        }
        bytes = await file.readAsBytes();
      } else {
        // ── Online: download via authenticated Dio client ───────────────────
        if (doc.fileUrl == null || doc.fileUrl!.isEmpty) {
          throw Exception('URL du document introuvable');
        }
        final fileUrl = doc.fileUrl!.startsWith('http')
            ? doc.fileUrl!
            : '${AppConstants.baseUrl}${doc.fileUrl}';
        final response = await ApiClient.instance.dio.get<List<int>>(
          fileUrl,
          options: Options(responseType: ResponseType.bytes),
          onReceiveProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() => _loadProgress = received / total);
            }
          },
        );
        if (response.data == null) throw Exception('Réponse vide du serveur');
        bytes = Uint8List.fromList(response.data!);
      }

      if (mounted) {
        setState(() { _pdfBytes = bytes; _isLoading = false; });
        _loadSavedState();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  // ── Reading state (position + bookmarks) ──────────────────────────────────

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt(_posKey) ?? 1;
    final bms = prefs.getStringList(_bookmarkKey) ?? [];
    if (mounted) {
      setState(() => _bookmarkedPages = bms.map(int.parse).toSet());
    }
    if (savedPage > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted && _totalPages > 0) {
            _pdfController.jumpToPage(savedPage);
          }
        });
      });
    }
  }

  Future<void> _savePdfPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_posKey, _currentPage);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _toggleBookmark() async {
    final page = _currentPage;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_bookmarkedPages.contains(page)) {
        _bookmarkedPages.remove(page);
      } else {
        _bookmarkedPages.add(page);
      }
    });
    await prefs.setStringList(
        _bookmarkKey, _bookmarkedPages.map((p) => p.toString()).toList());
  }

  Future<void> _saveToDownloads() async {
    final result = await DownloadManager.instance.downloadDocument(doc);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        result != null
            ? 'Document sauvegardé hors ligne'
            : 'Erreur de téléchargement',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
      backgroundColor: result != null ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }

  Future<void> _downloadCorrige() async {
    final result = await DownloadManager.instance.downloadDocument(doc, isCorrige: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        result != null ? 'Corrigé sauvegardé' : 'Erreur de téléchargement',
        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
      backgroundColor: result != null ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
    ));
  }

  void _performSearch(String text) {
    if (text.trim().isEmpty) {
      _searchResult.clear();
      setState(() {});
      return;
    }
    _searchResult = _pdfController.searchText(text);
    _searchResult.addListener(() { if (mounted) setState(() {}); });
  }

  void _openToc() => _pdfKey.currentState?.openBookmarkView();

  void _toggleOverlay() => setState(() => _overlayVisible = !_overlayVisible);

  // ── SfPdfViewer callbacks ──────────────────────────────────────────────────

  void _onPdfLoaded(PdfDocumentLoadedDetails d) {
    setState(() => _totalPages = d.document.pages.count);
  }

  void _onPageChanged(PdfPageChangedDetails d) {
    setState(() => _currentPage = d.newPageNumber);
    _savePdfPosition();
  }

  void _onPdfError(PdfDocumentLoadFailedDetails d) {
    setState(() => _error = d.description);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = _nightMode || doc.isImage;
    final bg = isDark ? const Color(0xFF0D0F12) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        // ── Main content ───────────────────────────────────────────────────
        if (_isLoading)
          _buildLoading()
        else if (_error != null)
          _buildError()
        else if (doc.isImage)
          GestureDetector(
            onTap: _toggleOverlay,
            behavior: HitTestBehavior.translucent,
            child: _buildImageViewer(),
          )
        else
          GestureDetector(
            onTap: _toggleOverlay,
            behavior: HitTestBehavior.translucent,
            child: _buildPdfViewer(),
          ),

        // ── Top bar — always visible so user can go back ───────────────────
        AnimatedOpacity(
          opacity: _isLoading || _error != null || _overlayVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_isLoading && _error == null && !_overlayVisible,
            child: _buildTopBar(isDark),
          ),
        ),

        // ── Bottom bar — only when PDF is loaded ───────────────────────────
        if (!_isLoading && _error == null && !doc.isImage && _totalPages > 0)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _overlayVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_overlayVisible,
                child: _buildBottomBar(isDark),
              ),
            ),
          ),

        // ── Search panel ───────────────────────────────────────────────────
        if (!doc.isImage && _showSearch && !_isLoading && _error == null)
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildSearchPanel(isDark),
          ),
      ]),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Container(
      color: const Color(0xFF0D0F12),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Icon(
              doc.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
              color: AppColors.primary, size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chargement du document…',
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            doc.fileSizeLabel,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _loadProgress > 0 ? _loadProgress : null,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
          ),
          if (_loadProgress > 0) ...[
            const SizedBox(height: 10),
            Text(
              '${(_loadProgress * 100).toInt()} %',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.white54),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      color: const Color(0xFF0D0F12),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppColors.error, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Impossible de charger le document',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 160,
              child: ElevatedButton.icon(
                onPressed: _loadDocument,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('Réessayer',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── PDF viewer (memory — works on all platforms) ───────────────────────────

  Widget _buildPdfViewer() {
    final Widget viewer = SfPdfViewer.memory(
      _pdfBytes!,
      key: _pdfKey,
      controller: _pdfController,
      canShowScrollHead: false,
      canShowScrollStatus: false,
      onDocumentLoaded: _onPdfLoaded,
      onPageChanged: _onPageChanged,
      onDocumentLoadFailed: _onPdfError,
    );

    return _nightMode
        ? ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              -1,  0,  0, 0, 255,
               0, -1,  0, 0, 255,
               0,  0, -1, 0, 255,
               0,  0,  0, 1,   0,
            ]),
            child: viewer,
          )
        : viewer;
  }

  // ── Image viewer ────────────────────────────────────────────────────────────

  Widget _buildImageViewer() {
    Widget image;
    if (widget.localPath != null && !kIsWeb) {
      image = Image.file(File(widget.localPath!), fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildImageError());
    } else {
      image = CachedNetworkImage(
        imageUrl: doc.fileUrl!.startsWith('http')
            ? doc.fileUrl!
            : '${AppConstants.baseUrl}${doc.fileUrl}',
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(
              color: Colors.white38, strokeWidth: 2),
        ),
        errorWidget: (_, __, ___) => _buildImageError(),
      );
    }

    if (_nightMode) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1,   0,
        ]),
        child: image,
      );
    }

    return Container(
      color: _nightMode ? const Color(0xFF121212) : Colors.black,
      child: InteractiveViewer(
        minScale: 0.5, maxScale: 8.0,
        child: Center(child: image),
      ),
    );
  }

  Widget _buildImageError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image_rounded,
            color: Colors.white24, size: 72),
        const SizedBox(height: 12),
        Text('Image introuvable',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
      ],
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(bool isDark) {
    final safeTop = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(6, safeTop + 4, 6, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? Colors.black : Colors.white)
                .withValues(alpha: isDark ? 0.78 : 0.97),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(children: [
        _iconBtn(Icons.arrow_back_rounded, isDark,
            () => Navigator.pop(context)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                doc.title,
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1D23),
                ),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              Text(
                _totalPages > 0
                    ? 'Page $_currentPage / $_totalPages'
                    : [doc.matiereName, doc.annee?.toString()]
                        .where((e) => e != null)
                        .join(' • '),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : const Color(0xFF868E96),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        if (!doc.isImage && !_isLoading && _error == null) ...[
          _iconBtn(Icons.search_rounded, isDark, () {
            setState(() { _showSearch = !_showSearch; _overlayVisible = true; });
          }, active: _showSearch),
          _iconBtn(Icons.format_list_bulleted_rounded, isDark, _openToc),
          if (_totalPages > 0)
            _iconBtn(
              _isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              isDark, _toggleBookmark,
              active: _isBookmarked,
            ),
        ],
        _iconBtn(
          _nightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          isDark,
          () => setState(() => _nightMode = !_nightMode),
          active: _nightMode,
        ),
        if (!_isLoading && _error == null) ...[
          _iconBtn(Icons.download_rounded, isDark, _saveToDownloads),
          if (doc.hasCorrige)
            _iconBtn(Icons.check_circle_outline_rounded, isDark, _downloadCorrige),
        ],
      ]),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool isDark) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1D23);
    final dimColor = isDark ? Colors.white38 : const Color(0xFFCED4DA);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, safeBottom + 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            (isDark ? Colors.black : Colors.white)
                .withValues(alpha: isDark ? 0.88 : 0.97),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            trackHeight: 3,
          ),
          child: Slider(
            value: _currentPage.toDouble().clamp(1.0, _totalPages.toDouble()),
            min: 1, max: _totalPages.toDouble(),
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary
                .withValues(alpha: isDark ? 0.22 : 0.15),
            onChanged: (v) {
              final p = v.toInt();
              setState(() => _currentPage = p);
              _pdfController.jumpToPage(p);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navBtn(Icons.first_page_rounded, textColor, dimColor,
                _currentPage > 1 ? () => _pdfController.jumpToPage(1) : null),
            _navBtn(Icons.chevron_left_rounded, textColor, dimColor,
                _currentPage > 1
                    ? () { setState(() => _currentPage--); _pdfController.previousPage(); }
                    : null),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.07),
                ),
                boxShadow: isDark ? null : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10),
                ],
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
            _navBtn(Icons.chevron_right_rounded, textColor, dimColor,
                _currentPage < _totalPages
                    ? () { setState(() => _currentPage++); _pdfController.nextPage(); }
                    : null),
            _navBtn(Icons.last_page_rounded, textColor, dimColor,
                _currentPage < _totalPages
                    ? () => _pdfController.jumpToPage(_totalPages)
                    : null),
          ],
        ),
      ]),
    );
  }

  // ── Search panel ────────────────────────────────────────────────────────────

  Widget _buildSearchPanel(bool isDark) {
    final safeTop = MediaQuery.of(context).padding.top;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1D23);

    return Container(
      padding: EdgeInsets.fromLTRB(14, safeTop + 10, 14, 14),
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                style: GoogleFonts.inter(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Rechercher dans le document…',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 20, color: Colors.grey.shade500),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.07)
                      : const Color(0xFFF1F3F5),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() => _showSearch = false);
                _searchResult.clear();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close_rounded, color: textColor, size: 22),
              ),
            ),
          ]),
          if (_searchResult.hasResult || _searchResult.isSearchCompleted) ...[
            const SizedBox(height: 8),
            Row(children: [
              Text(
                _searchResult.totalInstanceCount > 0
                    ? '${_searchResult.currentInstanceIndex} / ${_searchResult.totalInstanceCount} résultats'
                    : 'Aucun résultat',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
              const Spacer(),
              if (_searchResult.totalInstanceCount > 0) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.keyboard_arrow_up_rounded,
                      color: textColor, size: 22),
                  onPressed: () {
                    _searchResult.previousInstance();
                    setState(() {});
                  },
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: textColor, size: 22),
                  onPressed: () {
                    _searchResult.nextInstance();
                    setState(() {});
                  },
                ),
              ],
            ]),
          ],
        ]),
      ),
    );
  }

  // ── Button helpers ─────────────────────────────────────────────────────────

  Widget _iconBtn(
    IconData icon,
    bool isDark,
    VoidCallback? onTap, {
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.85)
              : isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white,
          shape: BoxShape.circle,
          boxShadow: (!isDark && !active)
              ? [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 8)]
              : null,
        ),
        child: Icon(icon, size: 17,
            color: active ? Colors.white : isDark ? Colors.white : const Color(0xFF1A1D23)),
      ),
    );
  }

  Widget _navBtn(
    IconData icon,
    Color activeColor,
    Color dimColor,
    VoidCallback? onTap,
  ) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? (_nightMode
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white)
              : Colors.transparent,
          boxShadow: (!_nightMode && enabled)
              ? [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8)]
              : null,
        ),
        child: Icon(icon, size: 22,
            color: enabled ? activeColor : dimColor),
      ),
    );
  }
}
