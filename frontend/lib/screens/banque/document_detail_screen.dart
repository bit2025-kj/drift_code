import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/document_model.dart';
import 'package:nafa_edu/screens/banque/document_reader_screen.dart';
import 'package:nafa_edu/services/download_manager.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final DocumentModel document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState
    extends ConsumerState<DocumentDetailScreen> {
  bool _isFavorite = false;
  bool _isDownloading = false;
  bool _isLoadingFav = false;
  double _userRating = 0;

  DocumentModel get doc => widget.document;

  Future<void> _toggleFavorite() async {
    setState(() => _isLoadingFav = true);
    try {
      await ApiClient.instance.dio
          .post(ApiEndpoints.favoriteDocument(doc.id));
      setState(() => _isFavorite = !_isFavorite);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingFav = false);
  }

  Future<void> _download({bool isCorrige = false}) async {
    setState(() => _isDownloading = true);
    try {
      final path = await DownloadManager.instance.downloadDocument(
        doc,
        isCorrige: isCorrige,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null ? 'Téléchargement réussi !' : 'Erreur lors du téléchargement'),
            backgroundColor: path != null ? AppColors.success : null,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du téléchargement')),
        );
      }
    }
    if (mounted) setState(() => _isDownloading = false);
  }

  Future<void> _rate(double rating) async {
    try {
      await ApiClient.instance.dio.post(
        ApiEndpoints.rateDocument(doc.id),
        data: {'rating': rating},
      );
      setState(() => _userRating = rating);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note de ${rating.toInt()}/5 enregistrée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(doc.title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15)),
        actions: [
          _isLoadingFav
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child:
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                    color: _isFavorite ? AppColors.primary : null,
                  ),
                  onPressed: _toggleFavorite,
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDocHeader(),
          const SizedBox(height: 16),
          _buildInfoGrid(),
          const SizedBox(height: 16),
          _buildDownloadSection(),
          const SizedBox(height: 16),
          _buildRatingSection(),
        ],
      ),
    );
  }

  Widget _buildDocHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B5BDB), Color(0xFF4DABF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                doc.isImage ? Icons.image_rounded : Icons.picture_as_pdf,
                color: Colors.white, size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    if (doc.levelName != null) _WhiteChip(doc.levelName!),
                    if (doc.classeName != null) _WhiteChip(doc.classeName!),
                    if (doc.annee != null) _WhiteChip('${doc.annee}'),
                    if (doc.isOfficial) _WhiteChip('OFFICIEL'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
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
          const Text('Informations',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _InfoRow(Icons.school_outlined, 'Matière', doc.matiereName ?? '—'),
          _InfoRow(Icons.quiz_outlined, 'Type', doc.typeExamenName ?? '—'),
          _InfoRow(Icons.calendar_today_outlined, 'Année',
              doc.annee?.toString() ?? '—'),
          _InfoRow(Icons.storage_outlined, 'Taille', doc.fileSizeLabel),
          _InfoRow(Icons.download_outlined, 'Téléchargements',
              '${doc.downloadsCount}'),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              const Text('Note',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              const Icon(Icons.star_rounded,
                  size: 14, color: Color(0xFFFFD43B)),
              Text(
                ' ${doc.rating.toStringAsFixed(1)} (${doc.ratingsCount})',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection() {
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
          const Text('Actions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentReaderScreen(document: doc),
                ),
              ),
              icon: Icon(doc.isImage ? Icons.fullscreen_rounded : Icons.menu_book_rounded),
              label: Text(doc.isImage ? 'Voir l\'image' : 'Lire le document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isDownloading ? null : () => _download(),
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_outlined),
              label: const Text('Télécharger le sujet'),
            ),
          ),
          if (doc.hasCorrige) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isDownloading
                    ? null
                    : () => _download(isCorrige: true),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Télécharger le corrigé'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
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
          const Text('Donner une note',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1.0;
              return GestureDetector(
                onTap: () => _rate(star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    _userRating >= star
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 36,
                    color: _userRating >= star
                        ? const Color(0xFFFFD43B)
                        : AppColors.textHint,
                  ),
                ),
              );
            }),
          ),
          if (_userRating > 0) ...[
            const SizedBox(height: 8),
            Center(
              child: Text('Votre note : ${_userRating.toInt()}/5',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }
}

class _WhiteChip extends StatelessWidget {
  final String label;
  const _WhiteChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
