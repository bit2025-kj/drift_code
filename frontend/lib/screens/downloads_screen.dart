import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/db/local_database.dart';
import 'package:nafa_edu/models/document_model.dart';
import 'package:nafa_edu/screens/banque/document_reader_screen.dart';
import 'package:nafa_edu/services/download_manager.dart';
import 'package:nafa_edu/services/sync_service.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes téléchargements'),
        actions: [
          FutureBuilder<double>(
            future: DownloadManager.instance.getTotalSizeMb(),
            builder: (_, snap) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${(snap.data ?? 0).toStringAsFixed(1)} Mo',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
      body: downloadsAsync.when(
        data: (downloads) {
          if (downloads.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_outlined, size: 72, color: AppColors.textHint),
                  SizedBox(height: 16),
                  Text('Aucun téléchargement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  SizedBox(height: 6),
                  Text('Téléchargez des sujets pour y accéder hors ligne', style: TextStyle(color: AppColors.textHint, fontSize: 13), textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: downloads.length,
            itemBuilder: (_, i) => _DownloadCard(doc: downloads[i], ref: ref),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final CachedDocument doc;
  final WidgetRef ref;

  const _DownloadCard({required this.doc, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFFFFEEE6), borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.picture_as_pdf, color: Color(0xFFFA5252), size: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (doc.classeName != null) Text('${doc.classeName} • ', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    if (doc.annee != null) Text('${doc.annee}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_bolt, size: 10, color: AppColors.success),
                          SizedBox(width: 3),
                          Text('Disponible hors ligne', style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    if (doc.hasCorrige) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text('+ Corrigé', style: TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (doc.localFilePath != null)
                IconButton(
                  icon: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                  tooltip: 'Lire',
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
                          rating: doc.rating,
                          ratingsCount: 0,
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
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                tooltip: 'Supprimer',
                onPressed: () => _confirmDelete(context, doc),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CachedDocument doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le téléchargement ?'),
        content: Text('Le fichier "${doc.title}" sera supprimé de votre appareil.'),
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
      ref.invalidate(downloadsProvider);
    }
  }
}
