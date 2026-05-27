import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nafa_edu/config/theme.dart';

bool isNetworkError(Object error) {
  if (error is DioException) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }
  if (error is SocketException) return true;
  return false;
}

/// Inline error for `.when(error:...)` callbacks where the error object is available.
/// Use [compact] = true for section-level errors inside a scrollable page.
class NetworkErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  const NetworkErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final offline = isNetworkError(error);
    if (compact) return _InlineError(offline: offline, onRetry: onRetry);
    return _PageError(offline: offline, onRetry: onRetry);
  }
}

/// Full-page or inline error for StateNotifier-based errors where [isOnlineProvider]
/// is used to determine offline status instead of the exception type.
class OfflineAwareErrorWidget extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onRetry;
  final bool compact;

  const OfflineAwareErrorWidget({
    super.key,
    required this.isOffline,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _InlineError(offline: isOffline, onRetry: onRetry);
    return _PageError(offline: isOffline, onRetry: onRetry);
  }
}

// ── Compact inline error ───────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  final bool offline;
  final VoidCallback? onRetry;
  const _InlineError({required this.offline, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            size: 16,
            color: AppColors.textHint,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              offline ? 'Pas de connexion' : 'Erreur de chargement',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          if (onRetry != null)
            GestureDetector(
              onTap: onRetry,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Réessayer',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Full-page centered error ───────────────────────────────────────────────────

class _PageError extends StatelessWidget {
  final bool offline;
  final VoidCallback? onRetry;
  const _PageError({required this.offline, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              offline ? 'Pas de connexion' : 'Erreur de chargement',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              offline
                  ? 'Vérifiez votre connexion et réessayez'
                  : 'Une erreur s\'est produite. Veuillez réessayer.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
