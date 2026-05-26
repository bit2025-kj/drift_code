import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/marketplace_model.dart';

// ── Featured ──────────────────────────────────────────────────────────────────

final featuredProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.featuredProducts);
  return (res.data as List).map((p) => ProductModel.fromJson(p)).toList();
});

// ── My sales (teacher) ───────────────────────────────────────────────────────

final myTeacherSalesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.myMarketplacePurchases);
  return List<Map<String, dynamic>>.from(res.data['items'] ?? []);
});

// ── My products (teacher) ─────────────────────────────────────────────────────

final myProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.myProducts);
  return (res.data as List).map((p) => ProductModel.fromJson(p)).toList();
});

// ── Teacher request status ────────────────────────────────────────────────────

final myTeacherRequestProvider =
    FutureProvider.autoDispose<TeacherRequestModel?>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get(ApiEndpoints.myTeacherRequest);
    return TeacherRequestModel.fromJson(res.data);
  } catch (_) {
    return null;
  }
});

// ── Filter ────────────────────────────────────────────────────────────────────

class ProductFilter {
  final String? productType;
  final int? matiereId;
  final int? classeId;
  final int? levelId;
  final int? maxPrice;
  final String? q;
  final String sortBy;
  final int page;

  const ProductFilter({
    this.productType,
    this.matiereId,
    this.classeId,
    this.levelId,
    this.maxPrice,
    this.q,
    this.sortBy = 'popular',
    this.page = 1,
  });

  Map<String, dynamic> toQuery() => {
        if (productType != null) 'product_type': productType,
        if (matiereId != null) 'matiere_id': matiereId,
        if (classeId != null) 'classe_id': classeId,
        if (levelId != null) 'level_id': levelId,
        if (maxPrice != null) 'max_price': maxPrice,
        if (q != null && q!.isNotEmpty) 'q': q,
        'sort_by': sortBy,
        'page': page,
        'per_page': 20,
      };
}

// ── State ─────────────────────────────────────────────────────────────────────

class ProductListState {
  final List<ProductModel> products;
  final int total;
  final bool isLoading;
  final String? error;
  final ProductFilter filter;
  final bool hasMore;

  const ProductListState({
    this.products = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.filter = const ProductFilter(),
    this.hasMore = true,
  });

  ProductListState copyWith({
    List<ProductModel>? products,
    int? total,
    bool? isLoading,
    String? error,
    ProductFilter? filter,
    bool? hasMore,
    bool clearError = false,
  }) =>
      ProductListState(
        products: products ?? this.products,
        total: total ?? this.total,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        filter: filter ?? this.filter,
        hasMore: hasMore ?? this.hasMore,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MarketplaceNotifier extends StateNotifier<ProductListState> {
  MarketplaceNotifier() : super(const ProductListState()) {
    fetch();
  }

  static const _perPage = 20;

  Future<void> fetch({ProductFilter? filter}) async {
    final f = filter ?? state.filter;
    state = state.copyWith(isLoading: true, clearError: true, filter: f, hasMore: true);
    try {
      final res = await ApiClient.instance.dio.get(
        ApiEndpoints.products,
        queryParameters: f.toQuery(),
      );
      final items = (res.data['items'] as List)
          .map((p) => ProductModel.fromJson(p))
          .toList();
      state = state.copyWith(
        products: items,
        total: res.data['total'] ?? items.length,
        isLoading: false,
        hasMore: items.length >= _perPage,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final nextFilter = ProductFilter(
      productType: state.filter.productType,
      matiereId: state.filter.matiereId,
      classeId: state.filter.classeId,
      levelId: state.filter.levelId,
      maxPrice: state.filter.maxPrice,
      q: state.filter.q,
      sortBy: state.filter.sortBy,
      page: state.filter.page + 1,
    );
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiClient.instance.dio.get(
        ApiEndpoints.products,
        queryParameters: nextFilter.toQuery(),
      );
      final more = (res.data['items'] as List)
          .map((p) => ProductModel.fromJson(p))
          .toList();
      state = state.copyWith(
        products: [...state.products, ...more],
        isLoading: false,
        filter: nextFilter,
        hasMore: more.length >= _perPage,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> applyFilter(ProductFilter filter) => fetch(filter: filter);
  Future<void> refresh() => fetch(filter: state.filter);

  Future<Map<String, dynamic>?> purchase(String productId) async {
    try {
      final res = await ApiClient.instance.dio
          .post(ApiEndpoints.purchaseProduct(productId));
      return res.data as Map<String, dynamic>;
    } catch (e) {
      try {
        final detail = (e as dynamic).response?.data['detail'];
        return {'error': detail ?? 'Erreur lors de l\'achat'};
      } catch (_) {
        return {'error': 'Erreur lors de l\'achat'};
      }
    }
  }

  // Upload a single media file, return {url, type, name}
  Future<Map<String, dynamic>?> uploadMedia(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      final path = file.path;
      MultipartFile mf;
      if (bytes != null) {
        mf = MultipartFile.fromBytes(bytes, filename: file.name);
      } else if (path != null) {
        mf = await MultipartFile.fromFile(path, filename: file.name);
      } else {
        return null;
      }
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.marketplaceUploadMedia,
        data: FormData.fromMap({'file': mf}),
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Create a product (teacher only)
  Future<ProductModel?> createProduct({
    required String title,
    required String description,
    required int price,
    required String productType,
    int? matiereId,
    int? classeId,
    int? levelId,
    int discountPercent = 0,
    List<Map<String, dynamic>> mediaUrls = const [],
    List<Map<String, dynamic>> packItems = const [],
  }) async {
    try {
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.myProducts,
        data: {
          'title': title,
          'description': description,
          'price': price,
          'product_type': productType,
          if (matiereId != null) 'matiere_id': matiereId,
          if (classeId != null) 'classe_id': classeId,
          if (levelId != null) 'level_id': levelId,
          'discount_percent': discountPercent,
          'media_urls': mediaUrls,
          'pack_items': packItems,
        },
      );
      return ProductModel.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  // Delete own product
  Future<bool> deleteMyProduct(String productId) async {
    try {
      await ApiClient.instance.dio.delete(ApiEndpoints.myProduct(productId));
      return true;
    } catch (_) {
      return false;
    }
  }

  // Submit teacher request
  Future<TeacherRequestModel?> submitTeacherRequest({
    required String bio,
    required String specialites,
    String? etablissement,
    int anneesExperience = 0,
    required String justification,
  }) async {
    try {
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.teacherRequest,
        data: {
          'bio': bio,
          'specialites': specialites,
          if (etablissement != null) 'etablissement': etablissement,
          'annees_experience': anneesExperience,
          'justification': justification,
        },
      );
      return TeacherRequestModel.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  // Upload justification document for teacher request
  Future<String?> uploadTeacherDocument(String requestId, PlatformFile file) async {
    try {
      final bytes = file.bytes;
      final path = file.path;
      MultipartFile mf;
      if (bytes != null) {
        mf = MultipartFile.fromBytes(bytes, filename: file.name);
      } else if (path != null) {
        mf = await MultipartFile.fromFile(path, filename: file.name);
      } else {
        return null;
      }
      final res = await ApiClient.instance.dio.post(
        ApiEndpoints.teacherRequestDocument(requestId),
        data: FormData.fromMap({'file': mf}),
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data['document_url'] as String?;
    } catch (_) {
      return null;
    }
  }
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceNotifier, ProductListState>(
  (_) => MarketplaceNotifier(),
);
