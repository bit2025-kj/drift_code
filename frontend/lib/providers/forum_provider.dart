import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/forum_model.dart';

// ── Détail discussion ─────────────────────────────────────────────────────────

final discussionDetailProvider =
    FutureProvider.family<DiscussionDetailModel, String>((ref, id) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.discussion(id));
  return DiscussionDetailModel.fromJson(res.data);
});

// ── Catégories ────────────────────────────────────────────────────────────────

class ForumCategory {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;

  const ForumCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
  });

  factory ForumCategory.fromJson(Map<String, dynamic> j) => ForumCategory(
        id: j['id'],
        name: j['name'],
        slug: j['slug'],
        icon: j['icon'],
        color: j['color'],
      );
}

final forumCategoriesProvider = FutureProvider<List<ForumCategory>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.forumCategories);
  return (res.data as List).map((c) => ForumCategory.fromJson(c)).toList();
});

final forumStatsProvider = FutureProvider<ForumStats>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.forumStats);
  return ForumStats.fromJson(res.data);
});

// ── Discussions ───────────────────────────────────────────────────────────────

class DiscussionListState {
  final List<DiscussionModel> discussions;
  final bool isLoading;
  final String? error;
  final int? categoryId;
  final String sortBy;
  final bool hasMore;
  final int page;
  final Set<String> likedIds;

  const DiscussionListState({
    this.discussions = const [],
    this.isLoading = false,
    this.error,
    this.categoryId,
    this.sortBy = 'recent',
    this.hasMore = true,
    this.page = 1,
    this.likedIds = const {},
  });

  DiscussionListState copyWith({
    List<DiscussionModel>? discussions,
    bool? isLoading,
    String? error,
    int? categoryId,
    String? sortBy,
    bool? hasMore,
    int? page,
    Set<String>? likedIds,
    bool clearError = false,
  }) =>
      DiscussionListState(
        discussions: discussions ?? this.discussions,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        categoryId: categoryId ?? this.categoryId,
        sortBy: sortBy ?? this.sortBy,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        likedIds: likedIds ?? this.likedIds,
      );
}

class DiscussionNotifier extends StateNotifier<DiscussionListState> {
  DiscussionNotifier() : super(const DiscussionListState()) {
    fetch();
  }

  static const _perPage = 20;

  Future<void> fetch({int? categoryId, String? sortBy}) async {
    final cat = categoryId ?? state.categoryId;
    final sort = sortBy ?? state.sortBy;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      categoryId: cat,
      sortBy: sort,
      page: 1,
      hasMore: true,
    );
    try {
      final params = <String, dynamic>{'sort_by': sort, 'per_page': _perPage, 'page': 1};
      if (cat != null) params['category_id'] = cat;
      final res = await ApiClient.instance.dio.get(ApiEndpoints.discussions, queryParameters: params);
      final discussions = (res.data as List).map((d) => DiscussionModel.fromJson(d)).toList();
      state = state.copyWith(
        discussions: discussions,
        isLoading: false,
        page: 1,
        hasMore: discussions.length >= _perPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoading: true);
    try {
      final params = <String, dynamic>{
        'sort_by': state.sortBy,
        'per_page': _perPage,
        'page': nextPage,
      };
      if (state.categoryId != null) params['category_id'] = state.categoryId;
      final res = await ApiClient.instance.dio.get(ApiEndpoints.discussions, queryParameters: params);
      final more = (res.data as List).map((d) => DiscussionModel.fromJson(d)).toList();
      state = state.copyWith(
        discussions: [...state.discussions, ...more],
        isLoading: false,
        page: nextPage,
        hasMore: more.length >= _perPage,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleLike(String discussionId) async {
    final alreadyLiked = state.likedIds.contains(discussionId);
    final newLikedIds = Set<String>.from(state.likedIds);
    int delta;
    if (alreadyLiked) {
      newLikedIds.remove(discussionId);
      delta = -1;
    } else {
      newLikedIds.add(discussionId);
      delta = 1;
    }
    // Optimistic update
    state = state.copyWith(
      likedIds: newLikedIds,
      discussions: state.discussions.map((d) {
        if (d.id == discussionId) {
          return d.copyWith(likesCount: d.likesCount + delta);
        }
        return d;
      }).toList(),
    );
    try {
      await ApiClient.instance.dio.post(ApiEndpoints.likeDiscussion(discussionId));
    } catch (_) {
      // revert
      final revertIds = Set<String>.from(state.likedIds);
      if (alreadyLiked) {
        revertIds.add(discussionId);
      } else {
        revertIds.remove(discussionId);
      }
      state = state.copyWith(
        likedIds: revertIds,
        discussions: state.discussions.map((d) {
          if (d.id == discussionId) {
            return d.copyWith(likesCount: d.likesCount - delta);
          }
          return d;
        }).toList(),
      );
    }
  }

  // Keep old method name for compatibility
  Future<void> likeDiscussion(String discussionId) => toggleLike(discussionId);

  Future<bool> createPost({required String text, List<String> mediaUrls = const []}) async {
    try {
      await ApiClient.instance.dio.post(ApiEndpoints.discussions, data: {
        'title': text.length > 100 ? text.substring(0, 100) : text,
        'content': text,
        'media_urls': mediaUrls,
      });
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createDiscussion({
    required String title,
    required String content,
    int? categoryId,
    List<String> mediaUrls = const [],
  }) async {
    try {
      await ApiClient.instance.dio.post(ApiEndpoints.discussions, data: {
        'title': title,
        'content': content,
        if (categoryId != null) 'category_id': categoryId,
        'media_urls': mediaUrls,
      });
      await fetch();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> uploadMedia(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      final path = file.path;
      MultipartFile multipartFile;
      if (bytes != null) {
        multipartFile = MultipartFile.fromBytes(bytes, filename: file.name);
      } else if (path != null) {
        multipartFile = await MultipartFile.fromFile(path, filename: file.name);
      } else {
        return null;
      }
      final formData = FormData.fromMap({'file': multipartFile});
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.forumUploadMedia,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data['url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() => fetch();
}

final discussionProvider = StateNotifierProvider<DiscussionNotifier, DiscussionListState>(
  (_) => DiscussionNotifier(),
);
