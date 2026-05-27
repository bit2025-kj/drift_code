import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/config/theme.dart';
import 'package:nafa_edu/models/notification_model.dart';
import 'package:nafa_edu/providers/notification_provider.dart';
import 'package:nafa_edu/screens/forum/discussion_detail_screen.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetch();
    });
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _onTap(NotificationModel n) {
    ref.read(notificationProvider.notifier).markRead(n.id);
    final data = n.data;
    if (data == null) return;

    if (n.type == 'forum_comment' || n.type == 'forum_like') {
      final discussionId = data['discussion_id'] as String?;
      final title = data['discussion_title'] as String? ?? '';
      if (discussionId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiscussionDetailScreen(
              discussionId: discussionId,
              title: title,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary)),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllRead(),
              child: const Text('Tout lire',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : state.notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      ref.read(notificationProvider.notifier).fetch(),
                  child: ListView.builder(
                    itemCount: state.notifications.length,
                    itemBuilder: (context, i) =>
                        _NotifTile(
                          notif: state.notifications[i],
                          relativeTime: _relativeTime,
                          onTap: _onTap,
                        ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('Aucune notification',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            const Text('Vous serez notifié des nouveaux commentaires\net interactions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
}

// ── Notification Tile ─────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final String Function(DateTime) relativeTime;
  final void Function(NotificationModel) onTap;

  const _NotifTile({
    required this.notif,
    required this.relativeTime,
    required this.onTap,
  });

  static const _typeConfig = {
    'forum_comment': (Icons.chat_bubble_rounded, Color(0xFF4DABF7)),
    'forum_like': (Icons.favorite_rounded, Color(0xFFFA5252)),
    'document_like': (Icons.favorite_rounded, Color(0xFFFA5252)),
    'badge_earned': (Icons.military_tech_rounded, Color(0xFFFFD43B)),
    'marketplace_purchase': (Icons.shopping_bag_rounded, Color(0xFF51CF66)),
    'quiz_completed': (Icons.quiz_rounded, Color(0xFFA855F7)),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfig[notif.type] ??
        (Icons.notifications_rounded, AppColors.primary);
    final icon = cfg.$1;
    final color = cfg.$2;

    return InkWell(
      onTap: () => onTap(notif),
      child: Container(
        color: notif.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif.title,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(notif.body,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(relativeTime(notif.createdAt),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
