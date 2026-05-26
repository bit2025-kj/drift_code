import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/core/db/local_database.dart';
import 'package:nafa_edu/services/sync_service.dart';

/// Bandeau affiché en haut de chaque écran quand l'appareil est hors ligne
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    if (isOnline) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFF343A40),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Mode hors ligne — Vous consultez des données en cache',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.wifi_off, color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicateur compact inline (pour les cards, boutons)
class OfflineIndicator extends StatelessWidget {
  final bool isAvailableOffline;
  const OfflineIndicator({super.key, required this.isAvailableOffline});

  @override
  Widget build(BuildContext context) {
    if (!isAvailableOffline) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.success.withValues(alpha:0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_bolt, size: 10, color: AppColors.success),
          SizedBox(width: 3),
          Text('Hors ligne', style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Widget de synchronisation avec bouton manuel
class SyncStatusWidget extends ConsumerWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return pendingCount.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOnline ? AppColors.success.withValues(alpha:0.3) : AppColors.warning.withValues(alpha:0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isOnline ? Icons.sync : Icons.sync_disabled,
                color: isOnline ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isOnline
                      ? '$count opération(s) à synchroniser'
                      : '$count opération(s) en attente de connexion',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isOnline)
                TextButton(
                  onPressed: () async {
                    final result = await SyncService.instance.syncAll();
                    if (context.mounted) {
                      ref.invalidate(pendingSyncCountProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.message),
                          backgroundColor: result.failed == 0 ? AppColors.success : AppColors.warning,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.success, padding: EdgeInsets.zero),
                  child: const Text('Synchroniser', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Bouton de téléchargement avec progression
class DownloadButton extends ConsumerWidget {
  final String documentId;
  final VoidCallback onDownload;

  const DownloadButton({super.key, required this.documentId, required this.onDownload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: localDb.isDownloaded(documentId),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;

        if (isDownloaded) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha:0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: AppColors.success),
                SizedBox(width: 4),
                Text('Téléchargé', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ElevatedButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download_outlined, size: 14),
          label: const Text('Télécharger'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}
