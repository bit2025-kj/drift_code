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

  int? _levelId;
  int? _classeId;
  int? _matiereId;
  int? _typeExamenId;
  int? _annee;

  final List<PlatformFile> _files = [];
  PlatformFile? _corrige;

  bool _isUploading = false;
  int _uploadedCount = 0;
  String? _error;

  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _sessionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── File picking ─────────────────────────────────────────────────────────────

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _files.clear();
        _files.add(result.files.first);
      });
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

  // ── Upload ───────────────────────────────────────────────────────────────────

  Future<MultipartFile> _toMultipart(PlatformFile f) async {
    if (f.bytes != null) {
      return MultipartFile.fromBytes(f.bytes!, filename: f.name);
    }
    if (f.path != null) {
      return MultipartFile.fromFile(f.path!, filename: f.name);
    }
    throw Exception('Impossible de lire le fichier: ${f.name}');
  }

  void _showError(String msg) {
    setState(() => _error = msg);
    // Scroll to top so the error banner is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
    // Also show a snackbar so the user sees it regardless of scroll position
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFE03131),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _submit() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    // Validation — each shows snackbar + scrolls to error banner
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('Le titre est obligatoire.');
      return;
    }
    if (_levelId == null) {
      _showError('Veuillez sélectionner un niveau scolaire.');
      return;
    }
    if (_files.isEmpty) {
      _showError('Ajoutez au moins un fichier PDF ou image.');
      return;
    }

    setState(() { _isUploading = true; _uploadedCount = 0; });

    try {
      final f = _files.first;
      final Map<String, dynamic> fields = {
        'title': _titleCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        'level_id': _levelId,
        if (_classeId != null) 'classe_id': _classeId,
        if (_matiereId != null) 'matiere_id': _matiereId,
        if (_typeExamenId != null) 'type_examen_id': _typeExamenId,
        if (_annee != null) 'annee': _annee,
        if (_sessionCtrl.text.trim().isNotEmpty) 'session': _sessionCtrl.text.trim(),
        'file': await _toMultipart(f),
        if (_corrige != null) 'corrige': await _toMultipart(_corrige!),
      };

      await ApiClient.instance.dio.post(
        ApiEndpoints.uploadDocument,
        data: FormData.fromMap(fields),
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      // Refresh all document lists so the new upload is immediately visible
      ref.invalidate(trendingDocumentsProvider);
      ref.invalidate(newDocumentsProvider);
      ref.read(documentProvider.notifier).refresh();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Sujet publié avec succès !',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on DioException catch (e) {
      String msg;
      if (e.response != null) {
        // Extract backend error detail if available
        final data = e.response!.data;
        if (data is Map && data.containsKey('detail')) {
          msg = 'Erreur : ${data['detail']}';
        } else {
          msg = 'Erreur serveur (${e.response!.statusCode}).';
        }
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
    } catch (e) {
      final msg = 'Erreur inattendue : ${e.toString()}';
      setState(() { _isUploading = false; _error = msg; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFE03131),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _fileSize(int bytes) {
    if (bytes < 1024) return '${bytes} o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  bool _isImage(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

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
          // ── Handle + header ──────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFDEE2E6), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Publier un sujet',
                                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D23))),
                            Text('Partage tes documents avec la communauté',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF868E96))),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF868E96)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable form ──────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error banner
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFADAD)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFE03131), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFE03131), fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Section : Informations ────────────────────────────────
                  _sectionTitle('Informations générales', Icons.info_outline_rounded),
                  const SizedBox(height: 10),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Section : Classification ──────────────────────────────
                  _sectionTitle('Classification', Icons.category_outlined),
                  const SizedBox(height: 10),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Niveau
                        _label('Niveau scolaire *'),
                        const SizedBox(height: 8),
                        levelsAsync.when(
                          data: (levels) => Wrap(
                            spacing: 8, runSpacing: 8,
                            children: levels.map((l) {
                              final sel = _levelId == l.id;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _levelId = sel ? null : l.id;
                                  _classeId = null;
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel ? AppColors.primary : const Color(0xFFF1F3F5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: sel ? AppColors.primary : Colors.transparent),
                                  ),
                                  child: Text(l.name,
                                      style: GoogleFonts.inter(
                                          fontSize: 13, fontWeight: FontWeight.w600,
                                          color: sel ? Colors.white : const Color(0xFF495057))),
                                ),
                              );
                            }).toList(),
                          ),
                          loading: () => const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        // Classe (filtered by level)
                        if (_levelId != null) ...[
                          const SizedBox(height: 14),
                          _label('Classe (optionnel)'),
                          const SizedBox(height: 6),
                          classesAsync.when(
                            data: (classes) => _dropdown<int>(
                              value: _classeId,
                              hint: 'Sélectionner une classe',
                              items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                              onChanged: (v) => setState(() => _classeId = v),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],

                        // Matière
                        const SizedBox(height: 14),
                        _label('Matière (optionnel)'),
                        const SizedBox(height: 6),
                        matieresAsync.when(
                          data: (mats) => _dropdown<int>(
                            value: _matiereId,
                            hint: 'Sélectionner une matière',
                            items: mats.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                            onChanged: (v) => setState(() => _matiereId = v),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        // Type d'examen
                        const SizedBox(height: 14),
                        _label("Type d'examen (optionnel)"),
                        const SizedBox(height: 6),
                        typesAsync.when(
                          data: (types) => _dropdown<int>(
                            value: _typeExamenId,
                            hint: "Sélectionner un type d'examen",
                            items: types.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                            onChanged: (v) => setState(() => _typeExamenId = v),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        // Année + Session
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Année (optionnel)'),
                                  const SizedBox(height: 6),
                                  yearsAsync.when(
                                    data: (years) => _dropdown<int>(
                                      value: _annee,
                                      hint: 'Année',
                                      items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                                      onChanged: (v) => setState(() => _annee = v),
                                    ),
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Session (optionnel)'),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _sessionCtrl,
                                    style: GoogleFonts.inter(fontSize: 13),
                                    decoration: _inputDeco('Ex : Session normale'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Section : Fichiers ────────────────────────────────────
                  _sectionTitle('Fichier à publier', Icons.attach_file_rounded),
                  const SizedBox(height: 10),
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File list
                        if (_files.isNotEmpty) ...[
                          ..._files.asMap().entries.map((e) => _fileRow(
                            e.value,
                            onRemove: () => setState(() => _files.removeAt(e.key)),
                          )),
                          const SizedBox(height: 10),
                        ],

                        // Add files button
                        GestureDetector(
                          onTap: _isUploading ? null : _pickFiles,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha:0.04),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha:0.3),
                                width: 1.5,
                                // dashed simulation via plain border
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha:0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
                                ),
                                const SizedBox(height: 8),
                                Text(_files.isEmpty ? 'Sélectionner un fichier' : 'Remplacer le fichier',
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                const SizedBox(height: 2),
                                Text('PDF, JPG ou PNG — un seul fichier par sujet',
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF868E96))),
                              ],
                            ),
                          ),
                        ),

                        // Corrigé
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF868E96), size: 18),
                                  const SizedBox(width: 8),
                                  Text('Ajouter le fichier corrigé',
                                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF868E96), fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Sticky footer ────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Inline error near button
                if (_error != null && !_isUploading) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFADAD)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFE03131), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFE03131), fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_isUploading)
                  _uploadProgress()
                else SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: _submit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.publish_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _files.isEmpty ? 'Publier' : 'Publier ce sujet',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ],
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

  // ── Upload progress ───────────────────────────────────────────────────────────

  Widget _uploadProgress() {
    final progress = _files.isEmpty ? 0.0 : _uploadedCount / _files.length;
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Envoi en cours… $_uploadedCount / ${_files.length}',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D23)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE9ECEF),
            color: AppColors.primary,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ── File row ──────────────────────────────────────────────────────────────────

  Widget _fileRow(PlatformFile f, {required VoidCallback onRemove}) {
    final isImg = _isImage(f.name);
    final color = isImg ? const Color(0xFF1C7ED6) : const Color(0xFFE03131);
    final icon = isImg ? Icons.image_rounded : Icons.picture_as_pdf_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha:0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name,
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D23)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_fileSize(f.size),
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF868E96))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF868E96)),
            ),
          ),
        ],
      ),
    );
  }

  // ── UI helpers ────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 8, offset: const Offset(0, 2))],
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
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
        isExpanded: true,
        underline: const SizedBox.shrink(),
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
