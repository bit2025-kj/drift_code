class DocumentModel {
  final String id;
  final String title;
  final String? description;
  final int levelId;
  final int? classeId;
  final int? matiereId;
  final int? typeExamenId;
  final int? annee;
  final String? session;
  final bool isOfficial;
  final bool hasCorrige;
  final int downloadsCount;
  final int viewsCount;
  final double rating;
  final int ratingsCount;
  final int fileSizeKb;
  final DateTime createdAt;
  final String? fileUrl;
  final String? fileType;
  final String? thumbnailUrl;
  final String? levelName;
  final String? classeName;
  final String? matiereName;
  final String? typeExamenName;

  const DocumentModel({
    required this.id,
    required this.title,
    this.description,
    required this.levelId,
    this.classeId,
    this.matiereId,
    this.typeExamenId,
    this.annee,
    this.session,
    required this.isOfficial,
    required this.hasCorrige,
    required this.downloadsCount,
    required this.viewsCount,
    required this.rating,
    required this.ratingsCount,
    required this.fileSizeKb,
    required this.createdAt,
    this.fileUrl,
    this.fileType,
    this.thumbnailUrl,
    this.levelName,
    this.classeName,
    this.matiereName,
    this.typeExamenName,
  });

  bool get isImage => fileType == 'image';

  factory DocumentModel.fromJson(Map<String, dynamic> j) => DocumentModel(
        id: j['id'],
        title: j['title'],
        description: j['description'],
        levelId: j['level_id'],
        classeId: j['classe_id'],
        matiereId: j['matiere_id'],
        typeExamenId: j['type_examen_id'],
        annee: j['annee'],
        session: j['session'],
        isOfficial: j['is_official'] ?? false,
        hasCorrige: j['has_corrige'] ?? false,
        downloadsCount: j['downloads_count'] ?? 0,
        viewsCount: j['views_count'] ?? 0,
        rating: (j['rating'] ?? 0).toDouble(),
        ratingsCount: j['ratings_count'] ?? 0,
        fileSizeKb: j['file_size_kb'] ?? 0,
        createdAt: DateTime.parse(j['created_at']),
        fileUrl: j['file_url'],
        fileType: j['file_type'],
        thumbnailUrl: j['thumbnail_url'],
        levelName: j['level_name'],
        classeName: j['classe_name'],
        matiereName: j['matiere_name'],
        typeExamenName: j['type_examen_name'],
      );

  String get badgeLabel {
    if (typeExamenName == null) return levelName ?? '';
    if (typeExamenName!.contains('BAC')) return 'BAC';
    if (typeExamenName!.contains('BEPC')) return 'BEPC';
    if (typeExamenName!.contains('CEP')) return 'CEP';
    if (typeExamenName!.contains('ENAREF')) return 'CONCOURS';
    if (typeExamenName!.contains('ENAM')) return 'CONCOURS';
    return isOfficial ? 'OFFICIEL' : 'COMMUNAUTÉ';
  }

  String get fileSizeLabel {
    if (fileSizeKb < 1024) return '${fileSizeKb}KB';
    return '${(fileSizeKb / 1024).toStringAsFixed(1)}MB';
  }
}
