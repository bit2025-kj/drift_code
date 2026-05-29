import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/providers/document_provider.dart';
import 'package:nafa_edu/providers/education_provider.dart';

class PublishSheet extends ConsumerStatefulWidget {
  const PublishSheet({super.key});

  @override
  ConsumerState<PublishSheet> createState() => _PublishSheetState();
}

class _PublishSheetState extends ConsumerState<PublishSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sessionCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  int? _levelId;
  int? _classeId;
  int? _matiereId;
  int? _typeExamenId;
  int? _annee;

  // Single-file mode
  PlatformFile? _singleFile;
  PlatformFile? _corrige;

  // Multi-page mode
  bool _isMultiPage = false;
  final List<PlatformFile> _pages = [];

  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _error;

  static const int _maxPages = 20;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _sessionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── File picking ──────────────────────────────────────────────────────────────

  Future<void> _pickSingleFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _singleFile = result.files.first);
    }
  }

  Future<void> _pickCorrige() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _corrige = result.files.first);
    }
  }

  Future<void> _pickPageImages() async {
    final remaining = _maxPages - _pages.length;
    if (remaining <= 0) {
      _showError('Maximum $_maxPages pages atteint.');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        final toAdd = result.files.take(remaining).toList();
        _pages.addAll(toAdd);
        if (result.files.length > remaining) {
          _showError('Maximum $_maxPages pages. ${result.files.length - remaining} image(s) ignorée(s).');
        }
      });
    }
  }

  // ── Upload ────────────────────────────────────────────────────────────────────

  Future<MultipartFile> _toMultipart(PlatformFile f) async {
    if (f.bytes != null) return MultipartFile.fromBytes(f.bytes!, filename: f.name);
    if (f.path != null) return MultipartFile.fromFile(f.path!, filename: f.name);
    throw Exception('Impossible de lire: ${f.name}');
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (_titleCtrl.text.trim().isEmpty) { _showError('Le titre est obligatoire.'); return; }
    if (_levelId == null) { _showError('Veuillez sélectionner un niveau scolaire.'); return; }

    if (_isMultiPage) {
      if (_pages.isEmpty) { _showError('Ajoutez au moins une image de page.'); return; }
      await _submitMultiPage();
    } else {
      if (_singleFile == null) { _showError('Ajoutez un fichier PDF ou image.'); return; }
      await _submitSingle();
    }
  }

  Future<void> _submitSingle() async {
    setState(() { _isUploading = true; _uploadProgress = 0; });
    try {
      final Map<String, dynamic> fields = {
        'title': _titleCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        'level_id': _levelId,
        if (_classeId != null) 'classe_id': _classeId,
        if (_matiereId != null) 'matiere_id': _matiereId,
        if (_typeExamenId != null) 'type_examen_id': _typeExamenId,
        if (_annee != null) 'annee': _annee,
        if (_sessionCtrl.text.trim().isNotEmpty) 'session': _sessionCtrl.text.trim(),
        'file': await _toMultipart(_singleFile!),
        if (_corrige != null) 'corrige': await _toMultipart(_corrige!),
      };
      await ApiClient.instance.dio.post(
        ApiEndpoints.uploadDocument,
        data: FormData.fromMap(fields),
        options: Options(sendTimeout: const Duration(minutes: 2), receiveTimeout: const Duration(seconds: 60)),
        onSendProgress: (sent, total) {
          if (total > 0 && mounted) setState(() => _uploadProgress = sent / total);
        },
      );
      _onSuccess('Sujet publié avec succès !');
    } on DioException catch (e) {
      _onDioError(e);
    } catch (e) {
      _onGenericError(e);
    }
  }

  Future<void> _submitMultiPage() async {
    setState(() { _isUploading = true; _uploadProgress = 0; });
    try {
      final pageFiles = await Future.wait(_pages.map(_toMultipart));
      final Map<String, dynamic> fields = {
        'title': _titleCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        'level_id': _levelId,
        if (_classeId != null) 'classe_id': _classeId,
        if (_matiereId != null) 'matiere_id': _matiereId,
        if (_typeExamenId != null) 'type_examen_id': _typeExamenId,
        if (_annee != null) 'annee': _annee,
        if (_sessionCtrl.text.trim().isNotEmpty) 'session': _sessionCtrl.text.trim(),
        'pages': pageFiles,
      };
      await ApiClient.instance.dio.post(
        ApiEndpoints.uploadMultiPageDocument,
        data: FormData.fromMap(fields),
        options: Options(sendTimeout: const Duration(minutes: 5), receiveTimeout: const Duration(seconds: 120)),
        onSendProgress: (sent, total) {
          if (total > 0 && mounted) setState(() => _uploadProgress = sent / total);
        },
      );
      _onSuccess('Sujet multi-pages publié ! (${_pages.length} pages)');
    } on DioException catch (e) {
      _onDioError(e);
    } catch (e) {
      _onGenericError(e);
    }
  }

  void _onSuccess(String msg) {
    ref.invalidate(trendingDocumentsProvider);
    ref.invalidate(newDocumentsProvider);
    ref.read(documentProvider.notifier).refresh();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _onDioError(DioException e) {
    String msg;
    if (e.response != null) {
      final data = e.response!.data;
      msg = (data is Map && data.containsKey('detail'))
          ? 'Erreur : ${data['detail']}'
          : 'Erreur serveur (${e.response!.statusCode}).';
    } else {
      msg = 'Impossible de joindre le serveur. Vérifiez votre connexion.';
    }
    setState(() { _isUploading = false; _error = msg; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFE03131),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _onGenericError(Object e) {
    final msg = 'Erreur inattendue : $e';
    setState(() { _isUploading = false; _error = msg; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFE03131),
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Error helper ──────────────────────────────────────────────────────────────

  void _showError(String msg) {
    setState(() => _error = msg);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFE03131),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _fileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  bool _isImage(String name) =>
      ['jpg', 'jpeg', 'png', 'webp'].contains(name.split('.').last.toLowerCase());

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(levelsProvider);
    final matieresAsync = ref.watch(matieresProvider);
    final typesAsync = ref.watch(typesExamensProvider);
    final yearsAsync = ref.watch(yearsProvider);
    final classesAsync = ref.watch(classesByLevelProvider(_levelId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null) ...[_errorBanner(_error!), const SizedBox(height: 14)],

                  _sectionTitle('Informations générales', Icons.info_outline_rounded),
                  const SizedBox(height: 10),
                  _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Titre du document *'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleCtrl,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: _inputDeco('Ex : BAC Mathématiques Terminale D 2024'),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    const SizedBox(height: 14),
                    _label('Description (optionnel)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descCtrl,
                      style: GoogleFonts.inter(fontSize: 14),
                      maxLines: 3,
                      decoration: _inputDeco('Décris le contenu du document…'),
                    ),
                  ])),

                  const SizedBox(height: 16),
                  _sectionTitle('Classification', Icons.category_outlined),
                  const SizedBox(height: 10),
                  _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Niveau scolaire *'),
                    const SizedBox(height: 8),
                    levelsAsync.when(
                      data: (levels) => Wrap(
                        spacing: 8, runSpacing: 8,
                        children: levels.map((l) {
                          final sel = _levelId == l.id;
                          return GestureDetector(
                            onTap: () => setState(() { _levelId = sel ? null : l.id; _classeId = null; }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : const Color(0xFFF1F3F5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: sel ? AppColors.primary : Colors.transparent),
                              ),
                              child: Text(l.name,
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: sel ? Colors.white : const Color(0xFF495057))),
                            ),
                          );
                        }).toList(),
                      ),
                      loading: () => const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    if (_levelId != null) ...[
                      const SizedBox(height: 14),
                      _label('Classe (optionnel)'),
                      const SizedBox(height: 6),
                      classesAsync.when(
                        data: (classes) => _dropdown<int>(value: _classeId, hint: 'Sélectionner une classe',
                            items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                            onChanged: (v) => setState(() => _classeId = v)),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _label('Matière (optionnel)'),
                    const SizedBox(height: 6),
                    matieresAsync.when(
                      data: (mats) => _dropdown<int>(value: _matiereId, hint: 'Sélectionner une matière',
                          items: mats.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                          onChanged: (v) => setState(() => _matiereId = v)),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 14),
                    _label("Type d'examen (optionnel)"),
                    const SizedBox(height: 6),
                    typesAsync.when(
                      data: (types) => _dropdown<int>(value: _typeExamenId, hint: "Sélectionner un type d'examen",
                          items: types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                          onChanged: (v) => setState(() => _typeExamenId = v)),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Année (optionnel)'),
                        const SizedBox(height: 6),
                        yearsAsync.when(
                          data: (years) => _dropdown<int>(value: _annee, hint: 'Année',
                              items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                              onChanged: (v) => setState(() => _annee = v)),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('Session (optionnel)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _sessionCtrl,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: _inputDeco('Ex : Session normale'),
                        ),
                      ])),
                    ]),
                  ])),

                  const SizedBox(height: 16),
                  _sectionTitle('Fichier à publier', Icons.attach_file_rounded),
                  const SizedBox(height: 10),
                  _buildFileSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── File section ──────────────────────────────────────────────────────────────

  Widget _buildFileSection() {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Mode toggle
      _label('Mode de publication'),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _modeChip(
          icon: Icons.picture_as_pdf_rounded,
          label: 'Fichier unique',
          sublabel: 'PDF ou image',
          selected: !_isMultiPage,
          onTap: () => setState(() { _isMultiPage = false; _pages.clear(); }),
        )),
        const SizedBox(width: 10),
        Expanded(child: _modeChip(
          icon: Icons.photo_library_rounded,
          label: 'Multi-pages',
          sublabel: 'Plusieurs images',
          selected: _isMultiPage,
          onTap: () => setState(() { _isMultiPage = true; _singleFile = null; _corrige = null; }),
        )),
      ]),
      const SizedBox(height: 16),
      const Divider(color: Color(0xFFF1F3F5), thickness: 1.5),
      const SizedBox(height: 14),

      if (_isMultiPage)
        _buildMultiPageSection()
      else
        _buildSingleFileSection(),
    ]));
  }

  Widget _buildSingleFileSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_singleFile != null) ...[
        _fileRow(_singleFile!, onRemove: () => setState(() => _singleFile = null)),
        const SizedBox(height: 10),
      ],
      GestureDetector(
        onTap: _isUploading ? null : _pickSingleFile,
        child: _addButton(
          icon: Icons.add_rounded,
          label: _singleFile == null ? 'Sélectionner un fichier' : 'Remplacer le fichier',
          sublabel: 'PDF, JPG ou PNG',
        ),
      ),
      const SizedBox(height: 16),
      const Divider(color: Color(0xFFF1F3F5), thickness: 1.5),
      const SizedBox(height: 12),
      _label('Corrigé (optionnel)'),
      const SizedBox(height: 8),
      if (_corrige != null)
        _fileRow(_corrige!, onRemove: () => setState(() => _corrige = null))
      else
        GestureDetector(
          onTap: _isUploading ? null : _pickCorrige,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF868E96), size: 18),
              const SizedBox(width: 8),
              Text('Ajouter le fichier corrigé',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF868E96), fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
    ]);
  }

  Widget _buildMultiPageSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Tip banner
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chaque image = une page. Les images seront automatiquement assemblées en un PDF multi-pages. Réorganisez-les dans l\'ordre souhaité.',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, height: 1.5),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),

      // Page counter
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          _pages.isEmpty ? 'Aucune page ajoutée' : '${_pages.length} page${_pages.length > 1 ? 's' : ''} / $_maxPages max',
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700,
              color: _pages.length >= _maxPages ? AppColors.error : const Color(0xFF343A40)),
        ),
        if (_pages.isNotEmpty)
          TextButton.icon(
            onPressed: () => setState(() => _pages.clear()),
            icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColors.error),
            label: Text('Tout effacer', style: GoogleFonts.inter(fontSize: 12, color: AppColors.error)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ]),
      const SizedBox(height: 8),

      // Reorderable page list
      if (_pages.isNotEmpty) ...[
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = _pages.removeAt(oldIndex);
              _pages.insert(newIndex, item);
            });
          },
          children: _pages.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return _pageRow(key: ValueKey('page_$i'), index: i, file: f,
                onRemove: () => setState(() => _pages.removeAt(i)));
          }).toList(),
        ),
        const SizedBox(height: 10),
      ],

      // Add pages button
      if (_pages.length < _maxPages)
        GestureDetector(
          onTap: _isUploading ? null : _pickPageImages,
          child: _addButton(
            icon: Icons.add_photo_alternate_outlined,
            label: _pages.isEmpty ? 'Ajouter des images' : 'Ajouter d\'autres pages',
            sublabel: 'JPG, PNG ou WebP — ${_maxPages - _pages.length} restante(s)',
            accent: const Color(0xFF1C7ED6),
          ),
        ),
    ]);
  }

  // ── Widgets ───────────────────────────────────────────────────────────────────

  Widget _modeChip({
    required IconData icon,
    required String label,
    required String sublabel,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE9ECEF),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(children: [
          Icon(icon, size: 22, color: selected ? AppColors.primary : const Color(0xFFADB5BD)),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(
              fontSize: 12.5, fontWeight: FontWeight.w700,
              color: selected ? AppColors.primary : const Color(0xFF495057))),
          Text(sublabel, style: GoogleFonts.inter(
              fontSize: 10.5, color: selected ? AppColors.primary.withValues(alpha: 0.7) : const Color(0xFFADB5BD))),
        ]),
      ),
    );
  }

  Widget _addButton({required IconData icon, required String label, required String sublabel, Color? accent}) {
    final c = accent ?? AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: c.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: c, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
        const SizedBox(height: 2),
        Text(sublabel, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF868E96))),
      ]),
    );
  }

  Widget _pageRow({required Key key, required int index, required PlatformFile file, required VoidCallback onRemove}) {
    final hasThumb = file.bytes != null;
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Row(children: [
        // Drag handle
        const Padding(
          padding: EdgeInsets.only(right: 10),
          child: Icon(Icons.drag_handle_rounded, size: 22, color: Color(0xFFCED4DA)),
        ),
        // Thumbnail or icon
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF1F3F5),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasThumb
              ? Image.memory(file.bytes!, fit: BoxFit.cover)
              : const Icon(Icons.image_outlined, color: Color(0xFFADB5BD), size: 28),
        ),
        const SizedBox(width: 10),
        // Page number + name
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Page ${index + 1}',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(height: 4),
          Text(file.name,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D23)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(_fileSize(file.size),
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF868E96))),
        ])),
        // Delete button
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF868E96)),
          ),
        ),
      ]),
    );
  }

  Widget _fileRow(PlatformFile f, {required VoidCallback onRemove}) {
    final isImg = _isImage(f.name);
    final color = isImg ? const Color(0xFF1C7ED6) : const Color(0xFFE03131);
    final icon = isImg ? Icons.image_rounded : Icons.picture_as_pdf_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.name,
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D23)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(_fileSize(f.size),
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF868E96))),
        ])),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF868E96)),
          ),
        ),
      ]),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFADAD)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Color(0xFFE03131), size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFE03131), fontWeight: FontWeight.w500))),
      ]),
    );
  }

  // ── Header + Footer ───────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: const Color(0xFFDEE2E6), borderRadius: BorderRadius.circular(2)),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Publier un sujet',
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23))),
              Text('Partage tes documents avec la communauté',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF868E96))),
            ])),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, color: Color(0xFF868E96)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildFooter() {
    final hasFile = _isMultiPage ? _pages.isNotEmpty : _singleFile != null;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_error != null && !_isUploading) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFADAD)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFE03131), size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE03131), fontWeight: FontWeight.w500))),
            ]),
          ),
        ],
        if (_isUploading)
          _buildUploadProgress()
        else
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _submit,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_isMultiPage ? Icons.auto_stories_rounded : Icons.publish_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  !hasFile
                      ? 'Publier'
                      : _isMultiPage
                          ? 'Publier (${_pages.length} page${_pages.length > 1 ? 's' : ''})'
                          : 'Publier ce sujet',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildUploadProgress() {
    return Column(children: [
      Row(children: [
        const SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
        const SizedBox(width: 12),
        Text(
          _isMultiPage
              ? 'Envoi et assemblage en cours… ${(_uploadProgress * 100).toInt()}%'
              : 'Envoi en cours… ${(_uploadProgress * 100).toInt()}%',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D23)),
        ),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _uploadProgress > 0 ? _uploadProgress : null,
          backgroundColor: const Color(0xFFE9ECEF),
          color: AppColors.primary,
          minHeight: 6,
        ),
      ),
    ]);
  }

  // ── UI helpers ────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 6),
      Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
    ]);
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF343A40)));
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFADB5BD)),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: DropdownButton<T>(
        value: value,
        hint: Text(hint, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFADB5BD))),
        isExpanded: true, underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFADB5BD)),
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A1D23)),
        items: [
          DropdownMenuItem<T>(value: null, child: Text(hint, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFADB5BD)))),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }
}
