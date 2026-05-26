import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '_db_connection.dart'
    if (dart.library.html) '_db_connection_web.dart'
    if (dart.library.io) '_db_connection_mobile.dart';

part 'local_database.g.dart';

// Tables Drift
@DataClassName('CachedDocumentRow')
class CachedDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get levelName => text().nullable()();
  TextColumn get classeName => text().nullable()();
  TextColumn get matiereName => text().nullable()();
  TextColumn get typeExamenName => text().nullable()();
  IntColumn get annee => integer().nullable()();
  BoolColumn get hasCorrige => boolean()();
  BoolColumn get isOfficial => boolean()();
  RealColumn get rating => real()();
  IntColumn get fileSizeKb => integer()();
  TextColumn get localFilePath => text().nullable()();
  TextColumn get localCorigePath => text().nullable()();
  DateTimeColumn get downloadedAt => dateTime()();
  TextColumn get fileUrl => text().nullable()();
  TextColumn get fileType => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalFavoriteRow')
class LocalFavorites extends Table {
  TextColumn get documentId => text()();
  BoolColumn get pendingSync => boolean()();
  BoolColumn get pendingDelete => boolean()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {documentId};
}

@DataClassName('OfflineQuizSessionRow')
class OfflineQuizSessions extends Table {
  TextColumn get id => text()();
  TextColumn get quizId => text()();
  TextColumn get quizTitle => text()();
  TextColumn get matiereName => text().nullable()();
  TextColumn get answersJson => text()();
  RealColumn get score => real()();
  IntColumn get correctAnswers => integer()();
  IntColumn get totalQuestions => integer()();
  IntColumn get durationSeconds => integer()();
  BoolColumn get synced => boolean()();
  DateTimeColumn get completedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncItemRow')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()();
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text().nullable()();
  IntColumn get retryCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('SearchCacheRow')
class SearchCache extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get dataJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

@DriftDatabase(tables: [
  CachedDocuments,
  LocalFavorites,
  OfflineQuizSessions,
  SyncQueue,
  SearchCache,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;
}

/// Base de données locale légère utilisant Drift (SQLite) pour la persistance locale.
/// Architecture identique à Drift — migré depuis SharedPreferences.
class LocalDatabase {
  LocalDatabase._();
  static final instance = LocalDatabase._();

  late AppDatabase _db;
  bool _initialized = false;
  bool _webFallback = false;

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _webFallback = true;
      _initialized = true;
      return;
    }
    _db = AppDatabase();
    _initialized = true;
  }

  // ── CachedDocuments ──────────────────────────────────────────────────────

  Future<List<CachedDocument>> getAllDownloads() async {
    await init();
    if (_webFallback) return [];
    final rows = await _db.select(_db.cachedDocuments).get();
    return rows.map((r) => CachedDocument(
      id: r.id,
      title: r.title,
      levelName: r.levelName,
      classeName: r.classeName,
      matiereName: r.matiereName,
      typeExamenName: r.typeExamenName,
      annee: r.annee,
      hasCorrige: r.hasCorrige,
      isOfficial: r.isOfficial,
      rating: r.rating,
      fileSizeKb: r.fileSizeKb,
      localFilePath: r.localFilePath,
      localCorigePath: r.localCorigePath,
      downloadedAt: r.downloadedAt,
      fileUrl: r.fileUrl,
      fileType: r.fileType,
    )).toList();
  }

  Future<CachedDocument?> getDownload(String id) async {
    await init();
    if (_webFallback) return null;
    final query = _db.select(_db.cachedDocuments)..where((t) => t.id.equals(id));
    final r = await query.getSingleOrNull();
    if (r == null) return null;
    return CachedDocument(
      id: r.id,
      title: r.title,
      levelName: r.levelName,
      classeName: r.classeName,
      matiereName: r.matiereName,
      typeExamenName: r.typeExamenName,
      annee: r.annee,
      hasCorrige: r.hasCorrige,
      isOfficial: r.isOfficial,
      rating: r.rating,
      fileSizeKb: r.fileSizeKb,
      localFilePath: r.localFilePath,
      localCorigePath: r.localCorigePath,
      downloadedAt: r.downloadedAt,
      fileUrl: r.fileUrl,
      fileType: r.fileType,
    );
  }

  Future<void> upsertDownload(CachedDocument doc) async {
    await init();
    if (_webFallback) return;
    final row = CachedDocumentRow(
      id: doc.id,
      title: doc.title,
      levelName: doc.levelName,
      classeName: doc.classeName,
      matiereName: doc.matiereName,
      typeExamenName: doc.typeExamenName,
      annee: doc.annee,
      hasCorrige: doc.hasCorrige,
      isOfficial: doc.isOfficial,
      rating: doc.rating,
      fileSizeKb: doc.fileSizeKb,
      localFilePath: doc.localFilePath,
      localCorigePath: doc.localCorigePath,
      downloadedAt: doc.downloadedAt,
      fileUrl: doc.fileUrl,
      fileType: doc.fileType,
    );
    await _db.into(_db.cachedDocuments).insert(row, mode: InsertMode.insertOrReplace);
  }

  Future<void> deleteDownload(String id) async {
    await init();
    if (_webFallback) return;
    final query = _db.delete(_db.cachedDocuments)..where((t) => t.id.equals(id));
    await query.go();
  }

  Future<bool> isDownloaded(String documentId) async {
    final doc = await getDownload(documentId);
    return doc?.localFilePath != null;
  }

  // ── LocalFavorites ───────────────────────────────────────────────────────

  Future<List<LocalFavorite>> getAllFavorites() async {
    await init();
    if (_webFallback) return [];
    final rows = await _db.select(_db.localFavorites).get();
    return rows.map((r) => LocalFavorite(
      documentId: r.documentId,
      pendingSync: r.pendingSync,
      pendingDelete: r.pendingDelete,
      addedAt: r.addedAt,
    )).toList();
  }

  Future<bool> isFavorite(String documentId) async {
    await init();
    if (_webFallback) return false;
    final query = _db.select(_db.localFavorites)..where((t) => t.documentId.equals(documentId));
    final r = await query.getSingleOrNull();
    return r != null && !r.pendingDelete;
  }

  Future<void> addFavorite(String documentId) async {
    await init();
    if (_webFallback) return;
    final row = LocalFavoriteRow(
      documentId: documentId,
      pendingSync: true,
      pendingDelete: false,
      addedAt: DateTime.now(),
    );
    await _db.into(_db.localFavorites).insert(row, mode: InsertMode.insertOrReplace);
  }

  Future<void> removeFavorite(String documentId) async {
    await init();
    if (_webFallback) return;
    final query = _db.select(_db.localFavorites)..where((t) => t.documentId.equals(documentId));
    final r = await query.getSingleOrNull();
    if (r != null) {
      if (r.pendingSync && !r.pendingDelete) {
        final deleteQuery = _db.delete(_db.localFavorites)..where((t) => t.documentId.equals(documentId));
        await deleteQuery.go();
      } else {
        final updateQuery = _db.update(_db.localFavorites)..where((t) => t.documentId.equals(documentId));
        await updateQuery.write(const LocalFavoritesCompanion(
          pendingDelete: Value(true),
          pendingSync: Value(true),
        ));
      }
    }
  }

  Future<void> markFavoriteSynced(String documentId) async {
    await init();
    if (_webFallback) return;
    final query = _db.select(_db.localFavorites)..where((t) => t.documentId.equals(documentId));
    final r = await query.getSingleOrNull();
    if (r != null) {
      if (r.pendingDelete) {
        final deleteQuery = _db.delete(_db.localFavorites)..where((t) => t.documentId.equals(documentId));
        await deleteQuery.go();
      } else {
        final updateQuery = _db.update(_db.localFavorites)..where((t) => t.documentId.equals(documentId));
        await updateQuery.write(const LocalFavoritesCompanion(
          pendingSync: Value(false),
        ));
      }
    }
  }

  // ── OfflineQuizSessions ──────────────────────────────────────────────────

  Future<void> saveOfflineSession(OfflineQuizSession session) async {
    await init();
    if (_webFallback) return;
    final row = OfflineQuizSessionRow(
      id: session.id,
      quizId: session.quizId,
      quizTitle: session.quizTitle,
      matiereName: session.matiereName,
      answersJson: session.answersJson,
      score: session.score,
      correctAnswers: session.correctAnswers,
      totalQuestions: session.totalQuestions,
      durationSeconds: session.durationSeconds,
      synced: session.synced,
      completedAt: session.completedAt,
    );
    await _db.into(_db.offlineQuizSessions).insert(row, mode: InsertMode.insertOrReplace);
  }

  Future<List<OfflineQuizSession>> getPendingQuizSessions() async {
    await init();
    if (_webFallback) return [];
    final query = _db.select(_db.offlineQuizSessions)..where((t) => t.synced.not());
    final rows = await query.get();
    return rows.map((r) => OfflineQuizSession(
      id: r.id,
      quizId: r.quizId,
      quizTitle: r.quizTitle,
      matiereName: r.matiereName,
      answersJson: r.answersJson,
      score: r.score,
      correctAnswers: r.correctAnswers,
      totalQuestions: r.totalQuestions,
      durationSeconds: r.durationSeconds,
      synced: r.synced,
      completedAt: r.completedAt,
    )).toList();
  }

  Future<void> markSessionSynced(String id) async {
    await init();
    if (_webFallback) return;
    final updateQuery = _db.update(_db.offlineQuizSessions)..where((t) => t.id.equals(id));
    await updateQuery.write(const OfflineQuizSessionsCompanion(
      synced: Value(true),
    ));
  }

  // ── SyncQueue ─────────────────────────────────────────────────────────────

  Future<void> enqueue(String operation, String entityId, {String? payloadJson}) async {
    await init();
    if (_webFallback) return;
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion(
      operation: Value(operation),
      entityId: Value(entityId),
      payloadJson: Value(payloadJson),
      retryCount: const Value(0),
      createdAt: Value(DateTime.now()),
    ));
  }

  Future<List<SyncItem>> getPendingSyncItems() async {
    await init();
    if (_webFallback) return [];
    final rows = await _db.select(_db.syncQueue).get();
    return rows.map((r) => SyncItem(
      id: r.id,
      operation: r.operation,
      entityId: r.entityId,
      payloadJson: r.payloadJson,
      retryCount: r.retryCount,
      createdAt: r.createdAt,
    )).toList();
  }

  Future<void> removeSyncItem(int id) async {
    await init();
    if (_webFallback) return;
    final query = _db.delete(_db.syncQueue)..where((t) => t.id.equals(id));
    await query.go();
  }

  Future<void> incrementRetry(int id) async {
    await init();
    if (_webFallback) return;
    final query = _db.select(_db.syncQueue)..where((t) => t.id.equals(id));
    final r = await query.getSingleOrNull();
    if (r != null) {
      if (r.retryCount >= 5) {
        final deleteQuery = _db.delete(_db.syncQueue)..where((t) => t.id.equals(id));
        await deleteQuery.go();
      } else {
        final updateQuery = _db.update(_db.syncQueue)..where((t) => t.id.equals(id));
        await updateQuery.write(SyncQueueCompanion(
          retryCount: Value(r.retryCount + 1),
        ));
      }
    }
  }

  // ── CachedSearchResults ───────────────────────────────────────────────────

  Future<String?> getCachedSearch(String cacheKey) async {
    await init();
    if (_webFallback) return null;
    final query = _db.select(_db.searchCache)..where((t) => t.cacheKey.equals(cacheKey));
    final r = await query.getSingleOrNull();
    if (r == null) return null;
    if (DateTime.now().difference(r.cachedAt).inMinutes > 15) {
      final deleteQuery = _db.delete(_db.searchCache)..where((t) => t.cacheKey.equals(cacheKey));
      await deleteQuery.go();
      return null;
    }
    return r.dataJson;
  }

  Future<void> cacheSearch(String cacheKey, String dataJson) async {
    await init();
    if (_webFallback) return;
    final row = SearchCacheRow(
      cacheKey: cacheKey,
      dataJson: dataJson,
      cachedAt: DateTime.now(),
    );
    await _db.into(_db.searchCache).insert(row, mode: InsertMode.insertOrReplace);
  }

  Future<void> clearExpiredCache() async {
    await init();
    if (_webFallback) return;
    final expirationTime = DateTime.now().subtract(const Duration(minutes: 15));
    final query = _db.delete(_db.searchCache)..where((t) => t.cachedAt.isSmallerThanValue(expirationTime));
    await query.go();
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class CachedDocument {
  final String id;
  final String title;
  final String? levelName;
  final String? classeName;
  final String? matiereName;
  final String? typeExamenName;
  final int? annee;
  final bool hasCorrige;
  final bool isOfficial;
  final double rating;
  final int fileSizeKb;
  final String? localFilePath;
  final String? localCorigePath;
  final DateTime downloadedAt;
  final String? fileUrl;
  final String? fileType;

  const CachedDocument({
    required this.id,
    required this.title,
    this.levelName,
    this.classeName,
    this.matiereName,
    this.typeExamenName,
    this.annee,
    required this.hasCorrige,
    required this.isOfficial,
    required this.rating,
    required this.fileSizeKb,
    this.localFilePath,
    this.localCorigePath,
    required this.downloadedAt,
    this.fileUrl,
    this.fileType,
  });

  bool get isImage => fileType == 'image';

  factory CachedDocument.fromJson(Map<String, dynamic> j) => CachedDocument(
        id: j['id'],
        title: j['title'],
        levelName: j['level_name'],
        classeName: j['classe_name'],
        matiereName: j['matiere_name'],
        typeExamenName: j['type_examen_name'],
        annee: j['annee'],
        hasCorrige: j['has_corrige'] ?? false,
        isOfficial: j['is_official'] ?? false,
        rating: (j['rating'] ?? 0).toDouble(),
        fileSizeKb: j['file_size_kb'] ?? 0,
        localFilePath: j['local_file_path'],
        localCorigePath: j['local_corige_path'],
        downloadedAt: DateTime.parse(j['downloaded_at']),
        fileUrl: j['file_url'],
        fileType: j['file_type'],
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'level_name': levelName,
        'classe_name': classeName, 'matiere_name': matiereName,
        'type_examen_name': typeExamenName, 'annee': annee,
        'has_corrige': hasCorrige, 'is_official': isOfficial,
        'rating': rating, 'file_size_kb': fileSizeKb,
        'local_file_path': localFilePath, 'local_corige_path': localCorigePath,
        'downloaded_at': downloadedAt.toIso8601String(),
        'file_url': fileUrl, 'file_type': fileType,
      };

  CachedDocument copyWith({String? localFilePath, String? localCorigePath}) => CachedDocument(
        id: id, title: title, levelName: levelName, classeName: classeName,
        matiereName: matiereName, typeExamenName: typeExamenName, annee: annee,
        hasCorrige: hasCorrige, isOfficial: isOfficial, rating: rating,
        fileSizeKb: fileSizeKb, downloadedAt: downloadedAt,
        fileUrl: fileUrl, fileType: fileType,
        localFilePath: localFilePath ?? this.localFilePath,
        localCorigePath: localCorigePath ?? this.localCorigePath,
      );
}

class LocalFavorite {
  final String documentId;
  final bool pendingSync;
  final bool pendingDelete;
  final DateTime addedAt;

  const LocalFavorite({
    required this.documentId,
    required this.pendingSync,
    required this.pendingDelete,
    required this.addedAt,
  });

  factory LocalFavorite.fromJson(Map<String, dynamic> j) => LocalFavorite(
        documentId: j['document_id'],
        pendingSync: j['pending_sync'] ?? false,
        pendingDelete: j['pending_delete'] ?? false,
        addedAt: DateTime.parse(j['added_at']),
      );

  Map<String, dynamic> toJson() => {
        'document_id': documentId, 'pending_sync': pendingSync,
        'pending_delete': pendingDelete, 'added_at': addedAt.toIso8601String(),
      };

  LocalFavorite copyWith({bool? pendingSync, bool? pendingDelete}) => LocalFavorite(
        documentId: documentId, addedAt: addedAt,
        pendingSync: pendingSync ?? this.pendingSync,
        pendingDelete: pendingDelete ?? this.pendingDelete,
      );
}

class OfflineQuizSession {
  final String id;
  final String quizId;
  final String quizTitle;
  final String? matiereName;
  final String answersJson;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final int durationSeconds;
  final bool synced;
  final DateTime completedAt;

  const OfflineQuizSession({
    required this.id, required this.quizId, required this.quizTitle,
    this.matiereName, required this.answersJson, required this.score,
    required this.correctAnswers, required this.totalQuestions,
    required this.durationSeconds, required this.synced, required this.completedAt,
  });

  factory OfflineQuizSession.fromJson(Map<String, dynamic> j) => OfflineQuizSession(
        id: j['id'], quizId: j['quiz_id'], quizTitle: j['quiz_title'],
        matiereName: j['matiere_name'], answersJson: j['answers_json'],
        score: (j['score'] ?? 0).toDouble(), correctAnswers: j['correct_answers'] ?? 0,
        totalQuestions: j['total_questions'] ?? 0, durationSeconds: j['duration_seconds'] ?? 0,
        synced: j['synced'] ?? false, completedAt: DateTime.parse(j['completed_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'quiz_id': quizId, 'quiz_title': quizTitle,
        'matiere_name': matiereName, 'answers_json': answersJson,
        'score': score, 'correct_answers': correctAnswers,
        'total_questions': totalQuestions, 'duration_seconds': durationSeconds,
        'synced': synced, 'completed_at': completedAt.toIso8601String(),
      };

  OfflineQuizSession copyWith({bool? synced}) => OfflineQuizSession(
        id: id, quizId: quizId, quizTitle: quizTitle, matiereName: matiereName,
        answersJson: answersJson, score: score, correctAnswers: correctAnswers,
        totalQuestions: totalQuestions, durationSeconds: durationSeconds,
        completedAt: completedAt, synced: synced ?? this.synced,
      );
}

class SyncItem {
  final int id;
  final String operation;
  final String entityId;
  final String? payloadJson;
  final int retryCount;
  final DateTime createdAt;

  const SyncItem({
    required this.id, required this.operation, required this.entityId,
    this.payloadJson, required this.retryCount, required this.createdAt,
  });

  factory SyncItem.fromJson(Map<String, dynamic> j) => SyncItem(
        id: j['id'], operation: j['operation'], entityId: j['entity_id'],
        payloadJson: j['payload_json'], retryCount: j['retry_count'] ?? 0,
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'operation': operation, 'entity_id': entityId,
        'payload_json': payloadJson, 'retry_count': retryCount,
        'created_at': createdAt.toIso8601String(),
      };

  SyncItem copyWith({int? retryCount}) => SyncItem(
        id: id, operation: operation, entityId: entityId,
        payloadJson: payloadJson, createdAt: createdAt,
        retryCount: retryCount ?? this.retryCount,
      );
}

// Singleton global
final localDb = LocalDatabase.instance;
