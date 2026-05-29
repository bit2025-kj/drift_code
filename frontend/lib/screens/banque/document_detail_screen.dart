import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/constants.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/document_model.dart';
import 'package:nafa_edu/screens/banque/document_reader_screen.dart';
import 'package:nafa_edu/services/download_manager.dart';
import 'package:nafa_edu/widgets/report_dialog.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final DocumentModel document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  ConsumerState<DocumentDetailScreen> createState() =>
      _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  bool _isFavorite = false;
  bool _isDownloading = false;
  bool _isLoadingFav = false;
  bool _isLiked = false;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.document.likesCount;
  }

  DocumentModel get doc => widget.document;

  Future<void> _toggleFavorite() async {
    setState(() => _isLoadingFav = true);
    try {
      await ApiClient.instance.dio.post(ApiEndpoints.favoriteDocument(doc.id));
      setState(() => _isFavorite = !_isFavorite);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingFav = false);
  }

  Future<void> _toggleLike() async {
    // optimistic update
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    try {
      final res = await ApiClient.instance.dio
          .post(ApiEndpoints.likeDocument(doc.id));
      if (mounted) {
        setState(() {
          _isLiked = res.data['liked'] as bool;
          _likesCount = res.data['likes_count'] as int;
        });
      }
    } catch (_) {
      // rollback
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
      }
    }
  }

  Future<void> _download({bool isCorrige = false}) async {
    setState(() => _isDownloading = true);
    final path = await DownloadManager.instance.downloadDocument(
      doc,
      isCorrige: isCorrige,
    );
    if (mounted) {
      final error = DownloadManager.instance.progressOf(doc.id).value.error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(path != null
            ? 'Téléchargement réussi !'
            : (error ?? 'Erreur de téléchargement')),
        backgroundColor: path != null ? AppColors.success : AppColors.error,
        duration: Duration(seconds: path != null ? 2 : 5),
      ));
      setState(() => _isDownloading = false);
    }
  }

  void _openReader(DocumentModel readerDoc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentReaderScreen(document: readerDoc)),
    );
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
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                    color: _isFavorite ? AppColors.primary : null,
                  ),
                  onPressed: _toggleFavorite,
                ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'report') showReportDialog(context, contentType: 'document', contentId: doc.id);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Row(children: [Icon(Icons.flag_outlined, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Signaler')])),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDocHeader(),
          const SizedBox(height: 16),
          if (doc.uploaderName != null) ...[
            _buildUploaderCard(),
            const SizedBox(height: 16),
          ],
          _buildInfoGrid(),
          const SizedBox(height: 16),
          _buildDocumentsSection(),
          const SizedBox(height: 16),
          _buildLikeSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(
                doc.isImage ? Icons.image_rounded : Icons.picture_as_pdf,
                color: Colors.white,
                size: 32,
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
                    if (doc.hasCorrige)
                      const _WhiteChip('CORRIGÉ DISPONIBLE'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Uploader profile ─────────────────────────────────────────────────────────

  Widget _buildUploaderCard() {
    final name = doc.uploaderName!;
    final avatarUrl = doc.uploaderAvatar;
    final initials = name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildAvatarCircle(initials, avatarUrl, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Publié par',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Icon(Icons.person_outline,
              size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle(String initials, String? avatarUrl,
      {required double radius}) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      final url = avatarUrl.startsWith('http')
          ? avatarUrl
          : '${AppConstants.baseUrl}$avatarUrl';
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialsCircle(initials, radius),
          errorWidget: (_, __, ___) => _initialsCircle(initials, radius),
        ),
      );
    }
    return _initialsCircle(initials, radius);
  }

  Widget _initialsCircle(String initials, double radius) => Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF3B5BDB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(initials,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * 0.65,
                  fontWeight: FontWeight.w700)),
        ),
      );

  // ── Info grid ────────────────────────────────────────────────────────────────

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
          if (doc.matiereName != null)
            _InfoRow(Icons.school_outlined, 'Matière', doc.matiereName!),
          if (doc.typeExamenName != null)
            _InfoRow(Icons.quiz_outlined, 'Type', doc.typeExamenName!),
          if (doc.annee != null)
            _InfoRow(Icons.calendar_today_outlined, 'Année',
                doc.annee!.toString()),
          _InfoRow(Icons.storage_outlined, 'Taille', doc.fileSizeLabel),
          _InfoRow(Icons.download_outlined, 'Téléchargements',
              '${doc.downloadsCount}'),
        ],
      ),
    );
  }

  // ── Documents section ────────────────────────────────────────────────────────

  Widget _buildDocumentsSection() {
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
          const Text('Documents',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          // ── Main subject document ──────────────────────────────────────────
          if (doc.fileUrl != null)
            _DocumentTile(
              icon: doc.isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
              iconColor: AppColors.primary,
              label: 'Sujet',
              sublabel: doc.isImage ? 'Image' : 'PDF',
              onRead: () => _openReader(doc),
              onDownload: _isDownloading ? null : () => _download(),
              isDownloading: _isDownloading,
            ),

          // ── Correction document ────────────────────────────────────────────
          if (doc.hasCorrige) ...[
            const SizedBox(height: 10),
            _DocumentTile(
              icon: doc.isCorrigeImage
                  ? Icons.image_rounded
                  : Icons.picture_as_pdf_rounded,
              iconColor: const Color(0xFF2F9E44),
              label: 'Corrigé',
              sublabel: doc.isCorrigeImage ? 'Image' : 'PDF',
              onRead: doc.corrigeUrl != null
                  ? () => _openReader(
                        doc.copyWith(
                          fileUrl: doc.corrigeUrl,
                          fileType: doc.corrigeFileType,
                        ),
                      )
                  : null,
              onDownload: _isDownloading ? null : () => _download(isCorrige: true),
              isDownloading: _isDownloading,
              badge: 'CORRIGÉ',
            ),
          ],
        ],
      ),
    );
  }

  // ── Like section ─────────────────────────────────────────────────────────────

  Widget _buildLikeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Ce sujet vous a aidé ?',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _toggleLike,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isLiked
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                border: Border.all(
                  color:
                      _isLiked ? AppColors.primary : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isLiked ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_likesCount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _isLiked
                          ? AppColors.primary
                          : AppColors.textSecondary,
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
}

// ── Document Tile ─────────────────────────────────────────────────────────────

class _DocumentTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  final VoidCallback? onRead;
  final VoidCallback? onDownload;
  final bool isDownloading;
  final String? badge;

  const _DocumentTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.onRead,
    required this.onDownload,
    required this.isDownloading,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(badge!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    Text(sublabel,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRead,
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text('Lire', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: isDownloading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Télécharger',
                      style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: iconColor.withValues(alpha: 0.5)),
                    foregroundColor: iconColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _WhiteChip extends StatelessWidget {
  final String label;
  const _WhiteChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
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
