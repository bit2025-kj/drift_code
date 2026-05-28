import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart'
    if (dart.library.html) 'package:nafa_edu/services/_path_provider_stub.dart';
import 'package:path/path.dart' as p;
import 'package:nafa_edu/config/constants.dart';
import 'package:nafa_edu/core/db/local_database.dart';
import 'package:nafa_edu/models/document_model.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:url_launcher/url_launcher.dart';

// dart:io (File, Directory) — mobile only
import 'package:nafa_edu/services/_io_helper.dart'
    if (dart.library.html) 'package:nafa_edu/services/_io_helper_web.dart';

enum DownloadStatus { idle, downloading, completed, failed }

class DownloadProgress {
  final String documentId;
  final DownloadStatus status;
  final double progress; // 0.0 → 1.0
  final String? localPath;
  final String? error;

  const DownloadProgress({
    required this.documentId,
    required this.status,
    this.progress = 0,
    this.localPath,
    this.error,
  });
}

class DownloadManager {
  DownloadManager._();
  static final instance = DownloadManager._();

  final _downloads = <String, _ProgressNotifier>{};

  _ProgressNotifier progressOf(String documentId) {
    return _downloads.putIfAbsent(
      documentId,
      () => _ProgressNotifier(
          DownloadProgress(documentId: documentId, status: DownloadStatus.idle)),
    );
  }

  Future<String?> downloadDocument(DocumentModel doc, {bool isCorrige = false}) async {
    final notifier = progressOf(doc.id);
    notifier.value = DownloadProgress(documentId: doc.id, status: DownloadStatus.downloading, progress: 0);

    try {
      final api = ApiClient.instance;

      // 1. Enregistrer le téléchargement côté serveur et obtenir l'URL
      final response = await api.dio.post(
        ApiEndpoints.downloadDocument(doc.id),
        queryParameters: {'is_corrige': isCorrige},
      );
      final relativeUrl = response.data['file_url'] as String?;
      if (relativeUrl == null) throw Exception('URL de téléchargement invalide');

      final fullUrl = relativeUrl.startsWith('http')
          ? relativeUrl
          : '${AppConstants.baseUrl}$relativeUrl';

      if (kIsWeb) {
        // ── Web : déclencher le téléchargement via le navigateur ───────────────
        final uri = Uri.parse(fullUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        await _persistToDb(doc, isCorrige, null, null);

        notifier.value = DownloadProgress(
          documentId: doc.id,
          status: DownloadStatus.completed,
          progress: 1.0,
          localPath: fullUrl,
        );
        return fullUrl;
      }

      // ── Mobile : télécharger vers le stockage local ─────────────────────────
      final ext = p.extension(relativeUrl).isNotEmpty ? p.extension(relativeUrl) : '.pdf';
      final dir = await _getDownloadDir();
      final suffix = isCorrige ? '_corrige' : '';
      final savePath = p.join(dir, '${doc.id}$suffix$ext');

      await api.dio.download(
        fullUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            notifier.value = DownloadProgress(
              documentId: doc.id,
              status: DownloadStatus.downloading,
              progress: received / total,
            );
          }
        },
      );

      await _persistToDb(doc, isCorrige, savePath, null);

      notifier.value = DownloadProgress(
        documentId: doc.id,
        status: DownloadStatus.completed,
        progress: 1.0,
        localPath: savePath,
      );

      return savePath;
    } catch (e) {
      notifier.value = DownloadProgress(
        documentId: doc.id,
        status: DownloadStatus.failed,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<void> _persistToDb(DocumentModel doc, bool isCorrige, String? savePath, String? existing) async {
    final prev = await localDb.getDownload(doc.id);
    await localDb.upsertDownload(CachedDocument(
      id: doc.id,
      title: doc.title,
      levelName: doc.levelName,
      classeName: doc.classeName,
      matiereName: doc.matiereName,
      typeExamenName: doc.typeExamenName,
      annee: doc.annee,
      hasCorrige: doc.hasCorrige,
      isOfficial: doc.isOfficial,
      rating: doc.likesCount.toDouble(),
      fileSizeKb: doc.fileSizeKb,
      fileUrl: doc.fileUrl,
      fileType: doc.fileType,
      localFilePath: isCorrige ? prev?.localFilePath : savePath,
      localCorigePath: isCorrige ? savePath : prev?.localCorigePath,
      downloadedAt: prev?.downloadedAt ?? DateTime.now(),
    ));
  }

  Future<bool> isDownloaded(String documentId) => localDb.isDownloaded(documentId);

  Future<void> deleteDownload(String documentId) async {
    if (!kIsWeb) await deleteLocalFiles(documentId);
    await localDb.deleteDownload(documentId);
    _downloads[documentId]?.value = DownloadProgress(
      documentId: documentId,
      status: DownloadStatus.idle,
    );
  }

  Future<List<CachedDocument>> getAllDownloads() => localDb.getAllDownloads();

  Future<String> _getDownloadDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = await createDownloadDir(base.path);
    return dir;
  }

  Future<double> getTotalSizeMb() async {
    if (kIsWeb) return 0;
    try {
      return await computeTotalSizeMb(await _getDownloadDir());
    } catch (_) {
      return 0;
    }
  }
}

// Simple ValueNotifier wrapper so _ProgressNotifier is the canonical type
typedef _ProgressNotifier = ValueNotifier<DownloadProgress>;
