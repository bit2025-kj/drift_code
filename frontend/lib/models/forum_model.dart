class ForumAuthor {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final int points;

  const ForumAuthor({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.points,
  });

  factory ForumAuthor.fromJson(Map<String, dynamic> j) => ForumAuthor(
        id: j['id'],
        fullName: j['full_name'],
        avatarUrl: j['avatar_url'],
        points: j['points'] ?? 0,
      );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }
}

class DiscussionModel {
  final String id;
  final String title;
  final String content;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final bool isPinned;
  final bool isResolved;
  final DateTime createdAt;
  final ForumAuthor author;
  final String? categoryName;
  final String? matiereName;
  final List<String> mediaUrls;

  const DiscussionModel({
    required this.id,
    required this.title,
    required this.content,
    required this.viewsCount,
    required this.likesCount,
    required this.commentsCount,
    required this.isPinned,
    required this.isResolved,
    required this.createdAt,
    required this.author,
    this.categoryName,
    this.matiereName,
    this.mediaUrls = const [],
  });

  factory DiscussionModel.fromJson(Map<String, dynamic> j) => DiscussionModel(
        id: j['id'],
        title: j['title'],
        content: j['content'],
        viewsCount: j['views_count'] ?? 0,
        likesCount: j['likes_count'] ?? 0,
        commentsCount: j['comments_count'] ?? 0,
        isPinned: j['is_pinned'] ?? false,
        isResolved: j['is_resolved'] ?? false,
        createdAt: DateTime.parse(j['created_at']),
        author: ForumAuthor.fromJson(j['author']),
        categoryName: j['category_name'],
        matiereName: j['matiere_name'],
        mediaUrls: List<String>.from(j['media_urls'] ?? []),
      );

  DiscussionModel copyWith({int? likesCount}) => DiscussionModel(
        id: id,
        title: title,
        content: content,
        viewsCount: viewsCount,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount,
        isPinned: isPinned,
        isResolved: isResolved,
        createdAt: createdAt,
        author: author,
        categoryName: categoryName,
        matiereName: matiereName,
        mediaUrls: mediaUrls,
      );
}

class CommentModel {
  final String id;
  final String content;
  final int likesCount;
  final bool isSolution;
  final DateTime createdAt;
  final ForumAuthor author;
  final List<String> mediaUrls;
  final String? parentId;
  final List<CommentModel> replies;

  const CommentModel({
    required this.id,
    required this.content,
    required this.likesCount,
    required this.isSolution,
    required this.createdAt,
    required this.author,
    this.mediaUrls = const [],
    this.parentId,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> j) => CommentModel(
        id: j['id'],
        content: j['content'],
        likesCount: j['likes_count'] ?? 0,
        isSolution: j['is_solution'] ?? false,
        createdAt: DateTime.parse(j['created_at']),
        author: ForumAuthor.fromJson(j['author']),
        mediaUrls: List<String>.from(j['media_urls'] ?? []),
        parentId: j['parent_id'],
        replies: (j['replies'] as List? ?? [])
            .map((r) => CommentModel.fromJson(r))
            .toList(),
      );
}

class DiscussionDetailModel extends DiscussionModel {
  final List<CommentModel> comments;

  const DiscussionDetailModel({
    required super.id,
    required super.title,
    required super.content,
    required super.viewsCount,
    required super.likesCount,
    required super.commentsCount,
    required super.isPinned,
    required super.isResolved,
    required super.createdAt,
    required super.author,
    super.categoryName,
    super.matiereName,
    super.mediaUrls,
    required this.comments,
  });

  factory DiscussionDetailModel.fromJson(Map<String, dynamic> j) =>
      DiscussionDetailModel(
        id: j['id'],
        title: j['title'],
        content: j['content'],
        viewsCount: j['views_count'] ?? 0,
        likesCount: j['likes_count'] ?? 0,
        commentsCount: j['comments_count'] ?? 0,
        isPinned: j['is_pinned'] ?? false,
        isResolved: j['is_resolved'] ?? false,
        createdAt: DateTime.parse(j['created_at']),
        author: ForumAuthor.fromJson(j['author']),
        categoryName: j['category_name'],
        matiereName: j['matiere_name'],
        mediaUrls: List<String>.from(j['media_urls'] ?? []),
        comments: (j['comments'] as List? ?? [])
            .map((c) => CommentModel.fromJson(c))
            .toList(),
      );
}

class ForumStats {
  final int totalMembers;
  final int totalDiscussions;
  final int onlineCount;

  const ForumStats({
    required this.totalMembers,
    required this.totalDiscussions,
    required this.onlineCount,
  });

  factory ForumStats.fromJson(Map<String, dynamic> j) => ForumStats(
        totalMembers: j['total_members'] ?? 0,
        totalDiscussions: j['total_discussions'] ?? 0,
        onlineCount: j['online_count'] ?? 0,
      );
}
