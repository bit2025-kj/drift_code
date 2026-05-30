import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/core/db/local_database.dart';

enum ConnectivityStatus { online, offline }

/// Service de synchronisation bidirectionnelle
class SyncService {
  SyncService._();
  static final instance = SyncService._();

  ConnectivityStatus _status = ConnectivityStatus.online;
  ConnectivityStatus get status => _status;
  bool get isOnline => _status == ConnectivityStatus.online;

  /// Démarrer la surveillance réseau
  Stream<ConnectivityStatus> watchConnectivity() {
    return Connectivity().onConnectivityChanged.map((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      _status = hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline;
      if (isOnline) _syncPendingOperations(); // auto-sync au retour en ligne
      return _status;
    });
  }

  Future<void> init() async {
    final result = await Connectivity().checkConnectivity();
    _status = result.any((r) => r != ConnectivityResult.none)
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
  }

  /// Synchroniser toutes les opérations en attente
  Future<SyncResult> syncAll() async {
    if (!isOnline) return const SyncResult(synced: 0, failed: 0, message: 'Pas de connexion');

    int synced = 0;
    int failed = 0;

    // 1. Synchroniser la file d'attente générale
    final queue = await localDb.getPendingSyncItems();
    for (final item in queue) {
      try {
        await _processSyncItem(item);
        await localDb.removeSyncItem(item.id);
        synced++;
      } catch (e) {
        failed++;
        await _incrementRetry(item);
      }
    }

    // 2. Synchroniser les sessions quiz hors ligne
    final sessions = await localDb.getPendingQuizSessions();
    for (final session in sessions) {
      try {
        final answers = jsonDecode(session.answersJson) as Map<String, dynamic>;
        await ApiClient.instance.dio.post(
          ApiEndpoints.submitSession(session.id),
          data: {'session_id': session.id, 'answers': answers},
        );
        await localDb.markSessionSynced(session.id);
        synced++;
      } catch (e) {
        failed++;
      }
    }

    // 3. Synchroniser les favoris
    final favorites = await localDb.getAllFavorites();
    for (final fav in favorites.where((f) => f.pendingSync)) {
      try {
        if (fav.pendingDelete) {
          await ApiClient.instance.dio.delete(ApiEndpoints.favoriteDocument(fav.documentId));
        } else {
          await ApiClient.instance.dio.post(ApiEndpoints.favoriteDocument(fav.documentId));
        }
        await localDb.markFavoriteSynced(fav.documentId);
        synced++;
      } catch (e) {
        failed++;
      }
    }

    await localDb.clearExpiredCache();

    return SyncResult(
      synced: synced,
      failed: failed,
      message: synced > 0 ? '$synced opération(s) synchronisée(s)' : 'Aucune donnée à synchroniser',
    );
  }

  void _syncPendingOperations() {
    syncAll();
  }

  Future<void> _processSyncItem(SyncItem item) async {
    final api = ApiClient.instance;
    switch (item.operation) {
      case 'favorite_add':
        await api.dio.post(ApiEndpoints.favoriteDocument(item.entityId));
      case 'favorite_remove':
        await api.dio.delete(ApiEndpoints.favoriteDocument(item.entityId));
      case 'forum_post':
        final payload = jsonDecode(item.payloadJson ?? '{}');
        await api.dio.post(ApiEndpoints.discussions, data: payload);
      default:
        throw Exception('Opération inconnue: ${item.operation}');
    }
  }

  Future<void> _incrementRetry(SyncItem item) async {
    await localDb.incrementRetry(item.id);
  }

  /// Ajouter une opération à la file quand hors ligne
  Future<void> enqueueOffline(String operation, String entityId, {Map<String, dynamic>? payload}) {
    return localDb.enqueue(
      operation,
      entityId,
      payloadJson: payload != null ? jsonEncode(payload) : null,
    );
  }

  /// Nombre total d'opérations en attente
  Future<int> get pendingCount async {
    final queue = await localDb.getPendingSyncItems();
    final sessions = await localDb.getPendingQuizSessions();
    final favs = (await localDb.getAllFavorites()).where((f) => f.pendingSync).length;
    return queue.length + sessions.length + favs;
  }
}

class SyncResult {
  final int synced;
  final int failed;
  final String message;
  const SyncResult({required this.synced, required this.failed, required this.message});
}

// ─── Providers ────────────────────────────────────────────────────────────────

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  return SyncService.instance.watchConnectivity();
});

final isOnlineProvider = Provider<bool>((ref) {
  final conn = ref.watch(connectivityProvider);
  return conn.maybeWhen(data: (s) => s == ConnectivityStatus.online, orElse: () => true);
});

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  return SyncService.instance.pendingCount;
});

final downloadsProvider = FutureProvider.autoDispose<List<CachedDocument>>((ref) {
  return localDb.getAllDownloads();
});
