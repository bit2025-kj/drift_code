class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int? levelId;
  final int? classeId;
  final String? ville;
  final bool isTeacher;
  final int points;
  final int activeDays;
  final int currentStreak;
  final int? rank;
  final int walletBalance;
  final String? levelName;
  final String? classeName;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.levelId,
    this.classeId,
    this.ville,
    required this.isTeacher,
    required this.points,
    required this.activeDays,
    required this.currentStreak,
    this.rank,
    required this.walletBalance,
    this.levelName,
    this.classeName,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        fullName: j['full_name'],
        email: j['email'],
        phone: j['phone'],
        avatarUrl: j['avatar_url'],
        levelId: j['level_id'],
        classeId: j['classe_id'],
        ville: j['ville'],
        isTeacher: j['is_teacher'] ?? false,
        points: j['points'] ?? 0,
        activeDays: j['active_days'] ?? 0,
        currentStreak: j['current_streak'] ?? 0,
        rank: j['rank'],
        walletBalance: j['wallet_balance'] ?? 0,
        levelName: j['level_name'],
        classeName: j['classe_name'],
        createdAt: DateTime.parse(j['created_at']),
      );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }
}

class UserStats {
  final int totalDownloads;
  final int totalFavorites;
  final int totalQuizSessions;
  final double avgQuizScore;
  final int totalForumPosts;
  final int totalPurchases;
  final int badgesCount;
  final double revisionHours;
  final List<Map<String, dynamic>> subjectProgress;

  const UserStats({
    required this.totalDownloads,
    required this.totalFavorites,
    required this.totalQuizSessions,
    required this.avgQuizScore,
    required this.totalForumPosts,
    required this.totalPurchases,
    required this.badgesCount,
    required this.revisionHours,
    required this.subjectProgress,
  });

  factory UserStats.fromJson(Map<String, dynamic> j) => UserStats(
        totalDownloads: j['total_downloads'] ?? 0,
        totalFavorites: j['total_favorites'] ?? 0,
        totalQuizSessions: j['total_quiz_sessions'] ?? 0,
        avgQuizScore: (j['avg_quiz_score'] ?? 0).toDouble(),
        totalForumPosts: j['total_forum_posts'] ?? 0,
        totalPurchases: j['total_purchases'] ?? 0,
        badgesCount: j['badges_count'] ?? 0,
        revisionHours: (j['revision_hours'] ?? 0).toDouble(),
        subjectProgress: List<Map<String, dynamic>>.from(j['subject_progress'] ?? []),
      );
}
