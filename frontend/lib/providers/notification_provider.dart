import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/notification_model.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
  }) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiClient.instance.dio.get(ApiEndpoints.notifications);
      final list = (res.data as List)
          .map((j) => NotificationModel.fromJson(j as Map<String, dynamic>))
          .toList();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markRead(int id) async {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );
    try {
      await ApiClient.instance.dio.post(ApiEndpoints.notificationRead(id));
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    state = state.copyWith(
      notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
    try {
      await ApiClient.instance.dio.post(ApiEndpoints.notificationsReadAll);
    } catch (_) {}
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(),
);

/// Exposes just the unread count — used by AppBars and nav badges.
final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(notificationProvider).unreadCount,
);
