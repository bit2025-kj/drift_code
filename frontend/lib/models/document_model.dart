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
  final int likesCount;
  final int fileSizeKb;
  final DateTime createdAt;
  final String? fileUrl;
  final String? fileType;
  final String? thumbnailUrl;
  final String? corrigeUrl;
  final String? corrigeFileType;
  final String? uploaderName;
  final String? uploaderAvatar;
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
    this.likesCount = 0,
    required this.fileSizeKb,
    required this.createdAt,
    this.fileUrl,
    this.fileType,
    this.thumbnailUrl,
    this.corrigeUrl,
    this.corrigeFileType,
    this.uploaderName,
    this.uploaderAvatar,
    this.levelName,
    this.classeName,
    this.matiereName,
    this.typeExamenName,
  });

  bool get isImage => fileType == 'image';
  bool get isCorrigeImage => corrigeFileType == 'image';

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
        likesCount: j['likes_count'] ?? 0,
        fileSizeKb: j['file_size_kb'] ?? 0,
        createdAt: DateTime.parse(j['created_at']),
        fileUrl: j['file_url'],
        fileType: j['file_type'],
        thumbnailUrl: j['thumbnail_url'],
        corrigeUrl: j['corrige_url'],
        corrigeFileType: j['corrige_file_type'],
        uploaderName: j['uploader_name'],
        uploaderAvatar: j['uploader_avatar'],
        levelName: j['level_name'],
        classeName: j['classe_name'],
        matiereName: j['matiere_name'],
        typeExamenName: j['type_examen_name'],
      );

  DocumentModel copyWith({
    String? fileUrl,
    String? fileType,
    int? likesCount,
  }) =>
      DocumentModel(
        id: id,
        title: title,
        description: description,
        levelId: levelId,
        classeId: classeId,
        matiereId: matiereId,
        typeExamenId: typeExamenId,
        annee: annee,
        session: session,
        isOfficial: isOfficial,
        hasCorrige: hasCorrige,
        downloadsCount: downloadsCount,
        viewsCount: viewsCount,
        likesCount: likesCount ?? this.likesCount,
        fileSizeKb: fileSizeKb,
        createdAt: createdAt,
        fileUrl: fileUrl ?? this.fileUrl,
        fileType: fileType ?? this.fileType,
        thumbnailUrl: thumbnailUrl,
        corrigeUrl: corrigeUrl,
        corrigeFileType: corrigeFileType,
        uploaderName: uploaderName,
        uploaderAvatar: uploaderAvatar,
        levelName: levelName,
        classeName: classeName,
        matiereName: matiereName,
        typeExamenName: typeExamenName,
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
