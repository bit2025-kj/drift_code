import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int totalTeachers;
  final int totalDocuments;
  final int totalProducts;
  final int pendingTeacherRequests;
  final int pendingReports;

  const AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalTeachers,
    required this.totalDocuments,
    required this.totalProducts,
    required this.pendingTeacherRequests,
    required this.pendingReports,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        totalUsers: j['total_users'] ?? 0,
        activeUsers: j['active_users'] ?? 0,
        totalTeachers: j['total_teachers'] ?? 0,
        totalDocuments: j['total_documents'] ?? 0,
        totalProducts: j['total_products'] ?? 0,
        pendingTeacherRequests: j['pending_teacher_requests'] ?? 0,
        pendingReports: j['pending_reports'] ?? 0,
      );
}

class AdminUserItem {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? ville;
  final bool isActive;
  final bool isTeacher;
  final bool isAdmin;
  final int points;
  final DateTime createdAt;

  const AdminUserItem({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.ville,
    required this.isActive,
    required this.isTeacher,
    required this.isAdmin,
    required this.points,
    required this.createdAt,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> j) => AdminUserItem(
        id: j['id'],
        fullName: j['full_name'],
        email: j['email'],
        phone: j['phone'],
        ville: j['ville'],
        isActive: j['is_active'] ?? true,
        isTeacher: j['is_teacher'] ?? false,
        isAdmin: j['is_admin'] ?? false,
        points: j['points'] ?? 0,
        createdAt: DateTime.parse(j['created_at']),
      );
}

class AdminUserDetail extends AdminUserItem {
  final int walletBalance;
  final int currentStreak;
  final int activeDays;
  final int downloadsCount;
  final int favoritesCount;
  final int quizSessionsCount;
  final int forumPostsCount;
  final int purchasesCount;

  const AdminUserDetail({
    required super.id,
    required super.fullName,
    required super.email,
    super.phone,
    super.ville,
    required super.isActive,
    required super.isTeacher,
    required super.isAdmin,
    required super.points,
    required super.createdAt,
    required this.walletBalance,
    required this.currentStreak,
    required this.activeDays,
    required this.downloadsCount,
    required this.favoritesCount,
    required this.quizSessionsCount,
    required this.forumPostsCount,
    required this.purchasesCount,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> j) {
    final activity = j['activity'] as Map<String, dynamic>? ?? {};
    return AdminUserDetail(
      id: j['id'],
      fullName: j['full_name'],
      email: j['email'],
      phone: j['phone'],
      ville: j['ville'],
      isActive: j['is_active'] ?? true,
      isTeacher: j['is_teacher'] ?? false,
      isAdmin: j['is_admin'] ?? false,
      points: j['points'] ?? 0,
      createdAt: DateTime.parse(j['created_at']),
      walletBalance: j['wallet_balance'] ?? 0,
      currentStreak: j['current_streak'] ?? 0,
      activeDays: j['active_days'] ?? 0,
      downloadsCount: activity['downloads_count'] ?? 0,
      favoritesCount: activity['favorites_count'] ?? 0,
      quizSessionsCount: activity['quiz_sessions_count'] ?? 0,
      forumPostsCount: activity['forum_posts_count'] ?? 0,
      purchasesCount: activity['purchases_count'] ?? 0,
    );
  }
}

class AdminReport {
  final String id;
  final String reporterId;
  final String? reporterName;
  final String contentType;
  final String contentId;
  final String? contentTitle;
  final String reason;
  final String? description;
  final String status;
  final String? adminNote;
  final DateTime createdAt;

  const AdminReport({
    required this.id,
    required this.reporterId,
    this.reporterName,
    required this.contentType,
    required this.contentId,
    this.contentTitle,
    required this.reason,
    this.description,
    required this.status,
    this.adminNote,
    required this.createdAt,
  });

  factory AdminReport.fromJson(Map<String, dynamic> j) => AdminReport(
        id: j['id'],
        reporterId: j['reporter_id'],
        reporterName: j['reporter_name'],
        contentType: j['content_type'],
        contentId: j['content_id'],
        contentTitle: j['content_title'],
        reason: j['reason'],
        description: j['description'],
        status: j['status'],
        adminNote: j['admin_note'],
        createdAt: DateTime.parse(j['created_at']),
      );
}

class TeacherRequestAdmin {
  final String id;
  final String status;
  final String bio;
  final String specialites;
  final String? etablissement;
  final int anneesExperience;
  final String justification;
  final String? documentUrl;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String userId;
  final String? userName;
  final String? userEmail;

  const TeacherRequestAdmin({
    required this.id,
    required this.status,
    required this.bio,
    required this.specialites,
    this.etablissement,
    required this.anneesExperience,
    required this.justification,
    this.documentUrl,
    this.adminNote,
    required this.createdAt,
    this.reviewedAt,
    required this.userId,
    this.userName,
    this.userEmail,
  });

  factory TeacherRequestAdmin.fromJson(Map<String, dynamic> j) => TeacherRequestAdmin(
        id: j['id'],
        status: j['status'],
        bio: j['bio'],
        specialites: j['specialites'],
        etablissement: j['etablissement'],
        anneesExperience: j['annees_experience'] ?? 0,
        justification: j['justification'] ?? '',
        documentUrl: j['document_url'],
        adminNote: j['admin_note'],
        createdAt: DateTime.parse(j['created_at']),
        reviewedAt: j['reviewed_at'] != null ? DateTime.parse(j['reviewed_at']) : null,
        userId: j['user_id'],
        userName: j['user_name'],
        userEmail: j['user_email'],
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.adminStats);
  return AdminStats.fromJson(res.data);
});

// ── Users state ───────────────────────────────────────────────────────────────

class AdminUsersState {
  final List<AdminUserItem> users;
  final bool isLoading;
  final String? error;
  final String? query;
  final bool? filterActive;
  final bool? filterTeacher;

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.query,
    this.filterActive,
    this.filterTeacher,
  });

  AdminUsersState copyWith({
    List<AdminUserItem>? users,
    bool? isLoading,
    String? error,
    String? query,
    bool? filterActive,
    bool? filterTeacher,
  }) =>
      AdminUsersState(
        users: users ?? this.users,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        query: query ?? this.query,
        filterActive: filterActive ?? this.filterActive,
        filterTeacher: filterTeacher ?? this.filterTeacher,
      );
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  AdminUsersNotifier() : super(const AdminUsersState()) {
    load();
  }

  final _api = ApiClient.instance;

  Future<void> load({String? q, bool? isActive, bool? isTeacher}) async {
    state = state.copyWith(isLoading: true, query: q, filterActive: isActive, filterTeacher: isTeacher);
    try {
      final params = <String, dynamic>{'per_page': 50};
      if (q != null && q.isNotEmpty) params['q'] = q;
      if (isActive != null) params['is_active'] = isActive;
      if (isTeacher != null) params['is_teacher'] = isTeacher;
      final res = await _api.dio.get(ApiEndpoints.adminUsers, queryParameters: params);
      final users = (res.data as List).map((u) => AdminUserItem.fromJson(u)).toList();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> setUserStatus(String userId, bool isActive) async {
    try {
      await _api.dio.patch(ApiEndpoints.adminUserStatus(userId), data: {'is_active': isActive});
      state = state.copyWith(
        users: state.users.map((u) {
          if (u.id == userId) {
            return AdminUserItem(
              id: u.id, fullName: u.fullName, email: u.email, phone: u.phone,
              ville: u.ville, isActive: isActive, isTeacher: u.isTeacher,
              isAdmin: u.isAdmin, points: u.points, createdAt: u.createdAt,
            );
          }
          return u;
        }).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final adminUsersProvider = StateNotifierProvider.autoDispose<AdminUsersNotifier, AdminUsersState>(
  (_) => AdminUsersNotifier(),
);

final adminUserDetailProvider = FutureProvider.autoDispose.family<AdminUserDetail, String>((ref, userId) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.adminUser(userId));
  return AdminUserDetail.fromJson(res.data);
});

// ── Reports state ─────────────────────────────────────────────────────────────

class AdminReportsState {
  final List<AdminReport> reports;
  final bool isLoading;
  final String? error;
  final String statusFilter;

  const AdminReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter = 'pending',
  });

  AdminReportsState copyWith({
    List<AdminReport>? reports,
    bool? isLoading,
    String? error,
    String? statusFilter,
  }) =>
      AdminReportsState(
        reports: reports ?? this.reports,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        statusFilter: statusFilter ?? this.statusFilter,
      );
}

class AdminReportsNotifier extends StateNotifier<AdminReportsState> {
  AdminReportsNotifier() : super(const AdminReportsState()) {
    load();
  }

  final _api = ApiClient.instance;

  Future<void> load({String status = 'pending'}) async {
    state = state.copyWith(isLoading: true, statusFilter: status);
    try {
      final res = await _api.dio.get(ApiEndpoints.adminReports, queryParameters: {'status': status, 'per_page': 50});
      final reports = (res.data as List).map((r) => AdminReport.fromJson(r)).toList();
      state = state.copyWith(reports: reports, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> resolveReport(String reportId, String status, {String? adminNote, bool deleteContent = false}) async {
    try {
      await _api.dio.patch(ApiEndpoints.adminReport(reportId), data: {
        'status': status,
        if (adminNote != null) 'admin_note': adminNote,
        'delete_content': deleteContent,
      });
      state = state.copyWith(reports: state.reports.where((r) => r.id != reportId).toList());
      return null;
    } catch (e) {
      final msg = _extractError(e);
      state = state.copyWith(error: msg);
      return msg;
    }
  }

  static String _extractError(Object e) {
    try {
      final dioErr = e as dynamic;
      final detail = dioErr.response?.data?['detail'];
      if (detail != null) return detail.toString();
      final status = dioErr.response?.statusCode;
      if (status != null) return 'Erreur $status';
    } catch (_) {}
    return e.toString();
  }
}

final adminReportsProvider = StateNotifierProvider.autoDispose<AdminReportsNotifier, AdminReportsState>(
  (_) => AdminReportsNotifier(),
);

// ── Teacher requests state ────────────────────────────────────────────────────

class AdminTeacherRequestsState {
  final List<TeacherRequestAdmin> requests;
  final bool isLoading;
  final String? error;
  final String statusFilter;

  const AdminTeacherRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter = 'pending',
  });

  AdminTeacherRequestsState copyWith({
    List<TeacherRequestAdmin>? requests,
    bool? isLoading,
    String? error,
    String? statusFilter,
  }) =>
      AdminTeacherRequestsState(
        requests: requests ?? this.requests,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        statusFilter: statusFilter ?? this.statusFilter,
      );
}

class AdminTeacherRequestsNotifier extends StateNotifier<AdminTeacherRequestsState> {
  AdminTeacherRequestsNotifier() : super(const AdminTeacherRequestsState()) {
    load();
  }

  final _api = ApiClient.instance;

  Future<void> load({String status = 'pending'}) async {
    state = state.copyWith(isLoading: true, statusFilter: status);
    try {
      final res = await _api.dio.get(ApiEndpoints.adminTeacherRequestsV2, queryParameters: {'status': status});
      final requests = (res.data as List).map((r) => TeacherRequestAdmin.fromJson(r)).toList();
      state = state.copyWith(requests: requests, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> reviewRequest(String requestId, String status, {String? adminNote}) async {
    try {
      await _api.dio.patch(ApiEndpoints.adminReviewTeacherRequest(requestId), data: {
        'status': status,
        if (adminNote != null) 'admin_note': adminNote,
      });
      state = state.copyWith(requests: state.requests.where((r) => r.id != requestId).toList());
      return null;
    } catch (e) {
      final msg = AdminReportsNotifier._extractError(e);
      state = state.copyWith(error: msg);
      return msg;
    }
  }
}

final adminTeacherRequestsProvider =
    StateNotifierProvider.autoDispose<AdminTeacherRequestsNotifier, AdminTeacherRequestsState>(
  (_) => AdminTeacherRequestsNotifier(),
);
