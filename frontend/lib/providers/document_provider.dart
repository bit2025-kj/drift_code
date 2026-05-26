import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nafa_edu/core/api/api_client.dart';
import 'package:nafa_edu/core/api/api_endpoints.dart';
import 'package:nafa_edu/models/document_model.dart';

class DocumentFilter {
  final int? levelId;
  final int? classeId;
  final int? matiereId;
  final int? typeExamenId;
  final int? annee;
  final bool? hasCorrige;
  final String? q;
  final String sortBy;
  final int page;

  const DocumentFilter({
    this.levelId,
    this.classeId,
    this.matiereId,
    this.typeExamenId,
    this.annee,
    this.hasCorrige,
    this.q,
    this.sortBy = 'recent',
    this.page = 1,
  });

  DocumentFilter copyWith({
    int? levelId,
    int? classeId,
    int? matiereId,
    int? typeExamenId,
    int? annee,
    bool? hasCorrige,
    String? q,
    String? sortBy,
    int? page,
  }) =>
      DocumentFilter(
        levelId: levelId ?? this.levelId,
        classeId: classeId ?? this.classeId,
        matiereId: matiereId ?? this.matiereId,
        typeExamenId: typeExamenId ?? this.typeExamenId,
        annee: annee ?? this.annee,
        hasCorrige: hasCorrige ?? this.hasCorrige,
        q: q ?? this.q,
        sortBy: sortBy ?? this.sortBy,
        page: page ?? this.page,
      );

  Map<String, dynamic> toQuery() => {
        if (levelId != null) 'level_id': levelId,
        if (classeId != null) 'classe_id': classeId,
        if (matiereId != null) 'matiere_id': matiereId,
        if (typeExamenId != null) 'type_examen_id': typeExamenId,
        if (annee != null) 'annee': annee,
        if (hasCorrige != null) 'has_corrige': hasCorrige,
        if (q != null && q!.isNotEmpty) 'q': q,
        'sort_by': sortBy,
        'page': page,
        'per_page': 20,
      };
}

class DocumentListState {
  final List<DocumentModel> documents;
  final int total;
  final bool isLoading;
  final String? error;
  final DocumentFilter filter;

  const DocumentListState({
    this.documents = const [],
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.filter = const DocumentFilter(),
  });

  DocumentListState copyWith({
    List<DocumentModel>? documents,
    int? total,
    bool? isLoading,
    String? error,
    DocumentFilter? filter,
  }) =>
      DocumentListState(
        documents: documents ?? this.documents,
        total: total ?? this.total,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        filter: filter ?? this.filter,
      );
}

class DocumentNotifier extends StateNotifier<DocumentListState> {
  DocumentNotifier() : super(const DocumentListState()) {
    fetch();
  }

  final _api = ApiClient.instance;

  Future<void> fetch({DocumentFilter? filter}) async {
    final f = filter ?? state.filter;
    state = state.copyWith(isLoading: true, error: null, filter: f);
    try {
      final res = await _api.dio.get(ApiEndpoints.documents, queryParameters: f.toQuery());
      final items = (res.data['items'] as List).map((d) => DocumentModel.fromJson(d)).toList();
      state = state.copyWith(documents: items, total: res.data['total'], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  Future<void> applyFilter(DocumentFilter filter) => fetch(filter: filter.copyWith(page: 1));
  Future<void> refresh() => fetch(filter: state.filter.copyWith(page: 1));
}

final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentListState>(
  (_) => DocumentNotifier(),
);

final trendingDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final res = await ApiClient.instance.dio.get(ApiEndpoints.trending);
  return (res.data as List).map((d) => DocumentModel.fromJson(d)).toList();
});

final newDocumentsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  final res = await ApiClient.instance.dio.get(
    ApiEndpoints.documents,
    queryParameters: {'sort_by': 'recent', 'per_page': 6},
  );
  return (res.data['items'] as List).map((d) => DocumentModel.fromJson(d)).toList();
});

final myRecentDownloadsProvider = FutureProvider<List<DocumentModel>>((ref) async {
  try {
    final res = await ApiClient.instance.dio.get(ApiEndpoints.myDownloads);
    final items = res.data as List;
    return items.take(3).map((d) {
      final doc = (d is Map && d.containsKey('document')) ? d['document'] : d;
      return DocumentModel.fromJson(doc as Map<String, dynamic>);
    }).toList();
  } catch (_) {
    return [];
  }
});
