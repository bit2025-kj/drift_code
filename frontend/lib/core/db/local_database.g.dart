// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $CachedDocumentsTable extends CachedDocuments
    with TableInfo<$CachedDocumentsTable, CachedDocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _levelNameMeta =
      const VerificationMeta('levelName');
  @override
  late final GeneratedColumn<String> levelName = GeneratedColumn<String>(
      'level_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _classeNameMeta =
      const VerificationMeta('classeName');
  @override
  late final GeneratedColumn<String> classeName = GeneratedColumn<String>(
      'classe_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _matiereNameMeta =
      const VerificationMeta('matiereName');
  @override
  late final GeneratedColumn<String> matiereName = GeneratedColumn<String>(
      'matiere_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeExamenNameMeta =
      const VerificationMeta('typeExamenName');
  @override
  late final GeneratedColumn<String> typeExamenName = GeneratedColumn<String>(
      'type_examen_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _anneeMeta = const VerificationMeta('annee');
  @override
  late final GeneratedColumn<int> annee = GeneratedColumn<int>(
      'annee', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _hasCorrigeMeta =
      const VerificationMeta('hasCorrige');
  @override
  late final GeneratedColumn<bool> hasCorrige = GeneratedColumn<bool>(
      'has_corrige', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_corrige" IN (0, 1))'));
  static const VerificationMeta _isOfficialMeta =
      const VerificationMeta('isOfficial');
  @override
  late final GeneratedColumn<bool> isOfficial = GeneratedColumn<bool>(
      'is_official', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_official" IN (0, 1))'));
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeKbMeta =
      const VerificationMeta('fileSizeKb');
  @override
  late final GeneratedColumn<int> fileSizeKb = GeneratedColumn<int>(
      'file_size_kb', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _localFilePathMeta =
      const VerificationMeta('localFilePath');
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
      'local_file_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localCorigePathMeta =
      const VerificationMeta('localCorigePath');
  @override
  late final GeneratedColumn<String> localCorigePath = GeneratedColumn<String>(
      'local_corige_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _downloadedAtMeta =
      const VerificationMeta('downloadedAt');
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
      'downloaded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _fileUrlMeta =
      const VerificationMeta('fileUrl');
  @override
  late final GeneratedColumn<String> fileUrl = GeneratedColumn<String>(
      'file_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileTypeMeta =
      const VerificationMeta('fileType');
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
      'file_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        levelName,
        classeName,
        matiereName,
        typeExamenName,
        annee,
        hasCorrige,
        isOfficial,
        rating,
        fileSizeKb,
        localFilePath,
        localCorigePath,
        downloadedAt,
        fileUrl,
        fileType
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_documents';
  @override
  VerificationContext validateIntegrity(Insertable<CachedDocumentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('level_name')) {
      context.handle(_levelNameMeta,
          levelName.isAcceptableOrUnknown(data['level_name']!, _levelNameMeta));
    }
    if (data.containsKey('classe_name')) {
      context.handle(
          _classeNameMeta,
          classeName.isAcceptableOrUnknown(
              data['classe_name']!, _classeNameMeta));
    }
    if (data.containsKey('matiere_name')) {
      context.handle(
          _matiereNameMeta,
          matiereName.isAcceptableOrUnknown(
              data['matiere_name']!, _matiereNameMeta));
    }
    if (data.containsKey('type_examen_name')) {
      context.handle(
          _typeExamenNameMeta,
          typeExamenName.isAcceptableOrUnknown(
              data['type_examen_name']!, _typeExamenNameMeta));
    }
    if (data.containsKey('annee')) {
      context.handle(
          _anneeMeta, annee.isAcceptableOrUnknown(data['annee']!, _anneeMeta));
    }
    if (data.containsKey('has_corrige')) {
      context.handle(
          _hasCorrigeMeta,
          hasCorrige.isAcceptableOrUnknown(
              data['has_corrige']!, _hasCorrigeMeta));
    } else if (isInserting) {
      context.missing(_hasCorrigeMeta);
    }
    if (data.containsKey('is_official')) {
      context.handle(
          _isOfficialMeta,
          isOfficial.isAcceptableOrUnknown(
              data['is_official']!, _isOfficialMeta));
    } else if (isInserting) {
      context.missing(_isOfficialMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('file_size_kb')) {
      context.handle(
          _fileSizeKbMeta,
          fileSizeKb.isAcceptableOrUnknown(
              data['file_size_kb']!, _fileSizeKbMeta));
    } else if (isInserting) {
      context.missing(_fileSizeKbMeta);
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
          _localFilePathMeta,
          localFilePath.isAcceptableOrUnknown(
              data['local_file_path']!, _localFilePathMeta));
    }
    if (data.containsKey('local_corige_path')) {
      context.handle(
          _localCorigePathMeta,
          localCorigePath.isAcceptableOrUnknown(
              data['local_corige_path']!, _localCorigePathMeta));
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
          _downloadedAtMeta,
          downloadedAt.isAcceptableOrUnknown(
              data['downloaded_at']!, _downloadedAtMeta));
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    if (data.containsKey('file_url')) {
      context.handle(_fileUrlMeta,
          fileUrl.isAcceptableOrUnknown(data['file_url']!, _fileUrlMeta));
    }
    if (data.containsKey('file_type')) {
      context.handle(_fileTypeMeta,
          fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedDocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDocumentRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      levelName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level_name']),
      classeName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}classe_name']),
      matiereName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}matiere_name']),
      typeExamenName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}type_examen_name']),
      annee: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}annee']),
      hasCorrige: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_corrige'])!,
      isOfficial: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_official'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating'])!,
      fileSizeKb: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_kb'])!,
      localFilePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_file_path']),
      localCorigePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_corige_path']),
      downloadedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}downloaded_at'])!,
      fileUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_url']),
      fileType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_type']),
    );
  }

  @override
  $CachedDocumentsTable createAlias(String alias) {
    return $CachedDocumentsTable(attachedDatabase, alias);
  }
}

class CachedDocumentRow extends DataClass
    implements Insertable<CachedDocumentRow> {
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
  const CachedDocumentRow(
      {required this.id,
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
      this.fileType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || levelName != null) {
      map['level_name'] = Variable<String>(levelName);
    }
    if (!nullToAbsent || classeName != null) {
      map['classe_name'] = Variable<String>(classeName);
    }
    if (!nullToAbsent || matiereName != null) {
      map['matiere_name'] = Variable<String>(matiereName);
    }
    if (!nullToAbsent || typeExamenName != null) {
      map['type_examen_name'] = Variable<String>(typeExamenName);
    }
    if (!nullToAbsent || annee != null) {
      map['annee'] = Variable<int>(annee);
    }
    map['has_corrige'] = Variable<bool>(hasCorrige);
    map['is_official'] = Variable<bool>(isOfficial);
    map['rating'] = Variable<double>(rating);
    map['file_size_kb'] = Variable<int>(fileSizeKb);
    if (!nullToAbsent || localFilePath != null) {
      map['local_file_path'] = Variable<String>(localFilePath);
    }
    if (!nullToAbsent || localCorigePath != null) {
      map['local_corige_path'] = Variable<String>(localCorigePath);
    }
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    if (!nullToAbsent || fileUrl != null) {
      map['file_url'] = Variable<String>(fileUrl);
    }
    if (!nullToAbsent || fileType != null) {
      map['file_type'] = Variable<String>(fileType);
    }
    return map;
  }

  CachedDocumentsCompanion toCompanion(bool nullToAbsent) {
    return CachedDocumentsCompanion(
      id: Value(id),
      title: Value(title),
      levelName: levelName == null && nullToAbsent
          ? const Value.absent()
          : Value(levelName),
      classeName: classeName == null && nullToAbsent
          ? const Value.absent()
          : Value(classeName),
      matiereName: matiereName == null && nullToAbsent
          ? const Value.absent()
          : Value(matiereName),
      typeExamenName: typeExamenName == null && nullToAbsent
          ? const Value.absent()
          : Value(typeExamenName),
      annee:
          annee == null && nullToAbsent ? const Value.absent() : Value(annee),
      hasCorrige: Value(hasCorrige),
      isOfficial: Value(isOfficial),
      rating: Value(rating),
      fileSizeKb: Value(fileSizeKb),
      localFilePath: localFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localFilePath),
      localCorigePath: localCorigePath == null && nullToAbsent
          ? const Value.absent()
          : Value(localCorigePath),
      downloadedAt: Value(downloadedAt),
      fileUrl: fileUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fileUrl),
      fileType: fileType == null && nullToAbsent
          ? const Value.absent()
          : Value(fileType),
    );
  }

  factory CachedDocumentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDocumentRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      levelName: serializer.fromJson<String?>(json['levelName']),
      classeName: serializer.fromJson<String?>(json['classeName']),
      matiereName: serializer.fromJson<String?>(json['matiereName']),
      typeExamenName: serializer.fromJson<String?>(json['typeExamenName']),
      annee: serializer.fromJson<int?>(json['annee']),
      hasCorrige: serializer.fromJson<bool>(json['hasCorrige']),
      isOfficial: serializer.fromJson<bool>(json['isOfficial']),
      rating: serializer.fromJson<double>(json['rating']),
      fileSizeKb: serializer.fromJson<int>(json['fileSizeKb']),
      localFilePath: serializer.fromJson<String?>(json['localFilePath']),
      localCorigePath: serializer.fromJson<String?>(json['localCorigePath']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
      fileUrl: serializer.fromJson<String?>(json['fileUrl']),
      fileType: serializer.fromJson<String?>(json['fileType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'levelName': serializer.toJson<String?>(levelName),
      'classeName': serializer.toJson<String?>(classeName),
      'matiereName': serializer.toJson<String?>(matiereName),
      'typeExamenName': serializer.toJson<String?>(typeExamenName),
      'annee': serializer.toJson<int?>(annee),
      'hasCorrige': serializer.toJson<bool>(hasCorrige),
      'isOfficial': serializer.toJson<bool>(isOfficial),
      'rating': serializer.toJson<double>(rating),
      'fileSizeKb': serializer.toJson<int>(fileSizeKb),
      'localFilePath': serializer.toJson<String?>(localFilePath),
      'localCorigePath': serializer.toJson<String?>(localCorigePath),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
      'fileUrl': serializer.toJson<String?>(fileUrl),
      'fileType': serializer.toJson<String?>(fileType),
    };
  }

  CachedDocumentRow copyWith(
          {String? id,
          String? title,
          Value<String?> levelName = const Value.absent(),
          Value<String?> classeName = const Value.absent(),
          Value<String?> matiereName = const Value.absent(),
          Value<String?> typeExamenName = const Value.absent(),
          Value<int?> annee = const Value.absent(),
          bool? hasCorrige,
          bool? isOfficial,
          double? rating,
          int? fileSizeKb,
          Value<String?> localFilePath = const Value.absent(),
          Value<String?> localCorigePath = const Value.absent(),
          DateTime? downloadedAt,
          Value<String?> fileUrl = const Value.absent(),
          Value<String?> fileType = const Value.absent()}) =>
      CachedDocumentRow(
        id: id ?? this.id,
        title: title ?? this.title,
        levelName: levelName.present ? levelName.value : this.levelName,
        classeName: classeName.present ? classeName.value : this.classeName,
        matiereName: matiereName.present ? matiereName.value : this.matiereName,
        typeExamenName:
            typeExamenName.present ? typeExamenName.value : this.typeExamenName,
        annee: annee.present ? annee.value : this.annee,
        hasCorrige: hasCorrige ?? this.hasCorrige,
        isOfficial: isOfficial ?? this.isOfficial,
        rating: rating ?? this.rating,
        fileSizeKb: fileSizeKb ?? this.fileSizeKb,
        localFilePath:
            localFilePath.present ? localFilePath.value : this.localFilePath,
        localCorigePath: localCorigePath.present
            ? localCorigePath.value
            : this.localCorigePath,
        downloadedAt: downloadedAt ?? this.downloadedAt,
        fileUrl: fileUrl.present ? fileUrl.value : this.fileUrl,
        fileType: fileType.present ? fileType.value : this.fileType,
      );
  CachedDocumentRow copyWithCompanion(CachedDocumentsCompanion data) {
    return CachedDocumentRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      levelName: data.levelName.present ? data.levelName.value : this.levelName,
      classeName:
          data.classeName.present ? data.classeName.value : this.classeName,
      matiereName:
          data.matiereName.present ? data.matiereName.value : this.matiereName,
      typeExamenName: data.typeExamenName.present
          ? data.typeExamenName.value
          : this.typeExamenName,
      annee: data.annee.present ? data.annee.value : this.annee,
      hasCorrige:
          data.hasCorrige.present ? data.hasCorrige.value : this.hasCorrige,
      isOfficial:
          data.isOfficial.present ? data.isOfficial.value : this.isOfficial,
      rating: data.rating.present ? data.rating.value : this.rating,
      fileSizeKb:
          data.fileSizeKb.present ? data.fileSizeKb.value : this.fileSizeKb,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      localCorigePath: data.localCorigePath.present
          ? data.localCorigePath.value
          : this.localCorigePath,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
      fileUrl: data.fileUrl.present ? data.fileUrl.value : this.fileUrl,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocumentRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('levelName: $levelName, ')
          ..write('classeName: $classeName, ')
          ..write('matiereName: $matiereName, ')
          ..write('typeExamenName: $typeExamenName, ')
          ..write('annee: $annee, ')
          ..write('hasCorrige: $hasCorrige, ')
          ..write('isOfficial: $isOfficial, ')
          ..write('rating: $rating, ')
          ..write('fileSizeKb: $fileSizeKb, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('localCorigePath: $localCorigePath, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('fileType: $fileType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      levelName,
      classeName,
      matiereName,
      typeExamenName,
      annee,
      hasCorrige,
      isOfficial,
      rating,
      fileSizeKb,
      localFilePath,
      localCorigePath,
      downloadedAt,
      fileUrl,
      fileType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDocumentRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.levelName == this.levelName &&
          other.classeName == this.classeName &&
          other.matiereName == this.matiereName &&
          other.typeExamenName == this.typeExamenName &&
          other.annee == this.annee &&
          other.hasCorrige == this.hasCorrige &&
          other.isOfficial == this.isOfficial &&
          other.rating == this.rating &&
          other.fileSizeKb == this.fileSizeKb &&
          other.localFilePath == this.localFilePath &&
          other.localCorigePath == this.localCorigePath &&
          other.downloadedAt == this.downloadedAt &&
          other.fileUrl == this.fileUrl &&
          other.fileType == this.fileType);
}

class CachedDocumentsCompanion extends UpdateCompanion<CachedDocumentRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> levelName;
  final Value<String?> classeName;
  final Value<String?> matiereName;
  final Value<String?> typeExamenName;
  final Value<int?> annee;
  final Value<bool> hasCorrige;
  final Value<bool> isOfficial;
  final Value<double> rating;
  final Value<int> fileSizeKb;
  final Value<String?> localFilePath;
  final Value<String?> localCorigePath;
  final Value<DateTime> downloadedAt;
  final Value<String?> fileUrl;
  final Value<String?> fileType;
  final Value<int> rowid;
  const CachedDocumentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.levelName = const Value.absent(),
    this.classeName = const Value.absent(),
    this.matiereName = const Value.absent(),
    this.typeExamenName = const Value.absent(),
    this.annee = const Value.absent(),
    this.hasCorrige = const Value.absent(),
    this.isOfficial = const Value.absent(),
    this.rating = const Value.absent(),
    this.fileSizeKb = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.localCorigePath = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.fileType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDocumentsCompanion.insert({
    required String id,
    required String title,
    this.levelName = const Value.absent(),
    this.classeName = const Value.absent(),
    this.matiereName = const Value.absent(),
    this.typeExamenName = const Value.absent(),
    this.annee = const Value.absent(),
    required bool hasCorrige,
    required bool isOfficial,
    required double rating,
    required int fileSizeKb,
    this.localFilePath = const Value.absent(),
    this.localCorigePath = const Value.absent(),
    required DateTime downloadedAt,
    this.fileUrl = const Value.absent(),
    this.fileType = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        hasCorrige = Value(hasCorrige),
        isOfficial = Value(isOfficial),
        rating = Value(rating),
        fileSizeKb = Value(fileSizeKb),
        downloadedAt = Value(downloadedAt);
  static Insertable<CachedDocumentRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? levelName,
    Expression<String>? classeName,
    Expression<String>? matiereName,
    Expression<String>? typeExamenName,
    Expression<int>? annee,
    Expression<bool>? hasCorrige,
    Expression<bool>? isOfficial,
    Expression<double>? rating,
    Expression<int>? fileSizeKb,
    Expression<String>? localFilePath,
    Expression<String>? localCorigePath,
    Expression<DateTime>? downloadedAt,
    Expression<String>? fileUrl,
    Expression<String>? fileType,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (levelName != null) 'level_name': levelName,
      if (classeName != null) 'classe_name': classeName,
      if (matiereName != null) 'matiere_name': matiereName,
      if (typeExamenName != null) 'type_examen_name': typeExamenName,
      if (annee != null) 'annee': annee,
      if (hasCorrige != null) 'has_corrige': hasCorrige,
      if (isOfficial != null) 'is_official': isOfficial,
      if (rating != null) 'rating': rating,
      if (fileSizeKb != null) 'file_size_kb': fileSizeKb,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (localCorigePath != null) 'local_corige_path': localCorigePath,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileType != null) 'file_type': fileType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDocumentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? levelName,
      Value<String?>? classeName,
      Value<String?>? matiereName,
      Value<String?>? typeExamenName,
      Value<int?>? annee,
      Value<bool>? hasCorrige,
      Value<bool>? isOfficial,
      Value<double>? rating,
      Value<int>? fileSizeKb,
      Value<String?>? localFilePath,
      Value<String?>? localCorigePath,
      Value<DateTime>? downloadedAt,
      Value<String?>? fileUrl,
      Value<String?>? fileType,
      Value<int>? rowid}) {
    return CachedDocumentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      levelName: levelName ?? this.levelName,
      classeName: classeName ?? this.classeName,
      matiereName: matiereName ?? this.matiereName,
      typeExamenName: typeExamenName ?? this.typeExamenName,
      annee: annee ?? this.annee,
      hasCorrige: hasCorrige ?? this.hasCorrige,
      isOfficial: isOfficial ?? this.isOfficial,
      rating: rating ?? this.rating,
      fileSizeKb: fileSizeKb ?? this.fileSizeKb,
      localFilePath: localFilePath ?? this.localFilePath,
      localCorigePath: localCorigePath ?? this.localCorigePath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (levelName.present) {
      map['level_name'] = Variable<String>(levelName.value);
    }
    if (classeName.present) {
      map['classe_name'] = Variable<String>(classeName.value);
    }
    if (matiereName.present) {
      map['matiere_name'] = Variable<String>(matiereName.value);
    }
    if (typeExamenName.present) {
      map['type_examen_name'] = Variable<String>(typeExamenName.value);
    }
    if (annee.present) {
      map['annee'] = Variable<int>(annee.value);
    }
    if (hasCorrige.present) {
      map['has_corrige'] = Variable<bool>(hasCorrige.value);
    }
    if (isOfficial.present) {
      map['is_official'] = Variable<bool>(isOfficial.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (fileSizeKb.present) {
      map['file_size_kb'] = Variable<int>(fileSizeKb.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (localCorigePath.present) {
      map['local_corige_path'] = Variable<String>(localCorigePath.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (fileUrl.present) {
      map['file_url'] = Variable<String>(fileUrl.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('levelName: $levelName, ')
          ..write('classeName: $classeName, ')
          ..write('matiereName: $matiereName, ')
          ..write('typeExamenName: $typeExamenName, ')
          ..write('annee: $annee, ')
          ..write('hasCorrige: $hasCorrige, ')
          ..write('isOfficial: $isOfficial, ')
          ..write('rating: $rating, ')
          ..write('fileSizeKb: $fileSizeKb, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('localCorigePath: $localCorigePath, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('fileType: $fileType, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalFavoritesTable extends LocalFavorites
    with TableInfo<$LocalFavoritesTable, LocalFavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta =
      const VerificationMeta('documentId');
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
      'document_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pendingSyncMeta =
      const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
      'pending_sync', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_sync" IN (0, 1))'));
  static const VerificationMeta _pendingDeleteMeta =
      const VerificationMeta('pendingDelete');
  @override
  late final GeneratedColumn<bool> pendingDelete = GeneratedColumn<bool>(
      'pending_delete', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("pending_delete" IN (0, 1))'));
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
      'added_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [documentId, pendingSync, pendingDelete, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_favorites';
  @override
  VerificationContext validateIntegrity(Insertable<LocalFavoriteRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
          _documentIdMeta,
          documentId.isAcceptableOrUnknown(
              data['document_id']!, _documentIdMeta));
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
          _pendingSyncMeta,
          pendingSync.isAcceptableOrUnknown(
              data['pending_sync']!, _pendingSyncMeta));
    } else if (isInserting) {
      context.missing(_pendingSyncMeta);
    }
    if (data.containsKey('pending_delete')) {
      context.handle(
          _pendingDeleteMeta,
          pendingDelete.isAcceptableOrUnknown(
              data['pending_delete']!, _pendingDeleteMeta));
    } else if (isInserting) {
      context.missing(_pendingDeleteMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  LocalFavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFavoriteRow(
      documentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}document_id'])!,
      pendingSync: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_sync'])!,
      pendingDelete: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pending_delete'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  $LocalFavoritesTable createAlias(String alias) {
    return $LocalFavoritesTable(attachedDatabase, alias);
  }
}

class LocalFavoriteRow extends DataClass
    implements Insertable<LocalFavoriteRow> {
  final String documentId;
  final bool pendingSync;
  final bool pendingDelete;
  final DateTime addedAt;
  const LocalFavoriteRow(
      {required this.documentId,
      required this.pendingSync,
      required this.pendingDelete,
      required this.addedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['pending_sync'] = Variable<bool>(pendingSync);
    map['pending_delete'] = Variable<bool>(pendingDelete);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  LocalFavoritesCompanion toCompanion(bool nullToAbsent) {
    return LocalFavoritesCompanion(
      documentId: Value(documentId),
      pendingSync: Value(pendingSync),
      pendingDelete: Value(pendingDelete),
      addedAt: Value(addedAt),
    );
  }

  factory LocalFavoriteRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFavoriteRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
      pendingDelete: serializer.fromJson<bool>(json['pendingDelete']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'pendingSync': serializer.toJson<bool>(pendingSync),
      'pendingDelete': serializer.toJson<bool>(pendingDelete),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  LocalFavoriteRow copyWith(
          {String? documentId,
          bool? pendingSync,
          bool? pendingDelete,
          DateTime? addedAt}) =>
      LocalFavoriteRow(
        documentId: documentId ?? this.documentId,
        pendingSync: pendingSync ?? this.pendingSync,
        pendingDelete: pendingDelete ?? this.pendingDelete,
        addedAt: addedAt ?? this.addedAt,
      );
  LocalFavoriteRow copyWithCompanion(LocalFavoritesCompanion data) {
    return LocalFavoriteRow(
      documentId:
          data.documentId.present ? data.documentId.value : this.documentId,
      pendingSync:
          data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
      pendingDelete: data.pendingDelete.present
          ? data.pendingDelete.value
          : this.pendingDelete,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFavoriteRow(')
          ..write('documentId: $documentId, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('pendingDelete: $pendingDelete, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(documentId, pendingSync, pendingDelete, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFavoriteRow &&
          other.documentId == this.documentId &&
          other.pendingSync == this.pendingSync &&
          other.pendingDelete == this.pendingDelete &&
          other.addedAt == this.addedAt);
}

class LocalFavoritesCompanion extends UpdateCompanion<LocalFavoriteRow> {
  final Value<String> documentId;
  final Value<bool> pendingSync;
  final Value<bool> pendingDelete;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const LocalFavoritesCompanion({
    this.documentId = const Value.absent(),
    this.pendingSync = const Value.absent(),
    this.pendingDelete = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalFavoritesCompanion.insert({
    required String documentId,
    required bool pendingSync,
    required bool pendingDelete,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  })  : documentId = Value(documentId),
        pendingSync = Value(pendingSync),
        pendingDelete = Value(pendingDelete),
        addedAt = Value(addedAt);
  static Insertable<LocalFavoriteRow> custom({
    Expression<String>? documentId,
    Expression<bool>? pendingSync,
    Expression<bool>? pendingDelete,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (pendingSync != null) 'pending_sync': pendingSync,
      if (pendingDelete != null) 'pending_delete': pendingDelete,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalFavoritesCompanion copyWith(
      {Value<String>? documentId,
      Value<bool>? pendingSync,
      Value<bool>? pendingDelete,
      Value<DateTime>? addedAt,
      Value<int>? rowid}) {
    return LocalFavoritesCompanion(
      documentId: documentId ?? this.documentId,
      pendingSync: pendingSync ?? this.pendingSync,
      pendingDelete: pendingDelete ?? this.pendingDelete,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    if (pendingDelete.present) {
      map['pending_delete'] = Variable<bool>(pendingDelete.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFavoritesCompanion(')
          ..write('documentId: $documentId, ')
          ..write('pendingSync: $pendingSync, ')
          ..write('pendingDelete: $pendingDelete, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineQuizSessionsTable extends OfflineQuizSessions
    with TableInfo<$OfflineQuizSessionsTable, OfflineQuizSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineQuizSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quizIdMeta = const VerificationMeta('quizId');
  @override
  late final GeneratedColumn<String> quizId = GeneratedColumn<String>(
      'quiz_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quizTitleMeta =
      const VerificationMeta('quizTitle');
  @override
  late final GeneratedColumn<String> quizTitle = GeneratedColumn<String>(
      'quiz_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _matiereNameMeta =
      const VerificationMeta('matiereName');
  @override
  late final GeneratedColumn<String> matiereName = GeneratedColumn<String>(
      'matiere_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _answersJsonMeta =
      const VerificationMeta('answersJson');
  @override
  late final GeneratedColumn<String> answersJson = GeneratedColumn<String>(
      'answers_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
      'score', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _correctAnswersMeta =
      const VerificationMeta('correctAnswers');
  @override
  late final GeneratedColumn<int> correctAnswers = GeneratedColumn<int>(
      'correct_answers', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalQuestionsMeta =
      const VerificationMeta('totalQuestions');
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
      'total_questions', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
      'synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("synced" IN (0, 1))'));
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        quizId,
        quizTitle,
        matiereName,
        answersJson,
        score,
        correctAnswers,
        totalQuestions,
        durationSeconds,
        synced,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_quiz_sessions';
  @override
  VerificationContext validateIntegrity(
      Insertable<OfflineQuizSessionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('quiz_id')) {
      context.handle(_quizIdMeta,
          quizId.isAcceptableOrUnknown(data['quiz_id']!, _quizIdMeta));
    } else if (isInserting) {
      context.missing(_quizIdMeta);
    }
    if (data.containsKey('quiz_title')) {
      context.handle(_quizTitleMeta,
          quizTitle.isAcceptableOrUnknown(data['quiz_title']!, _quizTitleMeta));
    } else if (isInserting) {
      context.missing(_quizTitleMeta);
    }
    if (data.containsKey('matiere_name')) {
      context.handle(
          _matiereNameMeta,
          matiereName.isAcceptableOrUnknown(
              data['matiere_name']!, _matiereNameMeta));
    }
    if (data.containsKey('answers_json')) {
      context.handle(
          _answersJsonMeta,
          answersJson.isAcceptableOrUnknown(
              data['answers_json']!, _answersJsonMeta));
    } else if (isInserting) {
      context.missing(_answersJsonMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
          _scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('correct_answers')) {
      context.handle(
          _correctAnswersMeta,
          correctAnswers.isAcceptableOrUnknown(
              data['correct_answers']!, _correctAnswersMeta));
    } else if (isInserting) {
      context.missing(_correctAnswersMeta);
    }
    if (data.containsKey('total_questions')) {
      context.handle(
          _totalQuestionsMeta,
          totalQuestions.isAcceptableOrUnknown(
              data['total_questions']!, _totalQuestionsMeta));
    } else if (isInserting) {
      context.missing(_totalQuestionsMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(_syncedMeta,
          synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta));
    } else if (isInserting) {
      context.missing(_syncedMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineQuizSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineQuizSessionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      quizId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quiz_id'])!,
      quizTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quiz_title'])!,
      matiereName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}matiere_name']),
      answersJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answers_json'])!,
      score: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}score'])!,
      correctAnswers: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_answers'])!,
      totalQuestions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_questions'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      synced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}synced'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at'])!,
    );
  }

  @override
  $OfflineQuizSessionsTable createAlias(String alias) {
    return $OfflineQuizSessionsTable(attachedDatabase, alias);
  }
}

class OfflineQuizSessionRow extends DataClass
    implements Insertable<OfflineQuizSessionRow> {
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
  const OfflineQuizSessionRow(
      {required this.id,
      required this.quizId,
      required this.quizTitle,
      this.matiereName,
      required this.answersJson,
      required this.score,
      required this.correctAnswers,
      required this.totalQuestions,
      required this.durationSeconds,
      required this.synced,
      required this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['quiz_id'] = Variable<String>(quizId);
    map['quiz_title'] = Variable<String>(quizTitle);
    if (!nullToAbsent || matiereName != null) {
      map['matiere_name'] = Variable<String>(matiereName);
    }
    map['answers_json'] = Variable<String>(answersJson);
    map['score'] = Variable<double>(score);
    map['correct_answers'] = Variable<int>(correctAnswers);
    map['total_questions'] = Variable<int>(totalQuestions);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['synced'] = Variable<bool>(synced);
    map['completed_at'] = Variable<DateTime>(completedAt);
    return map;
  }

  OfflineQuizSessionsCompanion toCompanion(bool nullToAbsent) {
    return OfflineQuizSessionsCompanion(
      id: Value(id),
      quizId: Value(quizId),
      quizTitle: Value(quizTitle),
      matiereName: matiereName == null && nullToAbsent
          ? const Value.absent()
          : Value(matiereName),
      answersJson: Value(answersJson),
      score: Value(score),
      correctAnswers: Value(correctAnswers),
      totalQuestions: Value(totalQuestions),
      durationSeconds: Value(durationSeconds),
      synced: Value(synced),
      completedAt: Value(completedAt),
    );
  }

  factory OfflineQuizSessionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineQuizSessionRow(
      id: serializer.fromJson<String>(json['id']),
      quizId: serializer.fromJson<String>(json['quizId']),
      quizTitle: serializer.fromJson<String>(json['quizTitle']),
      matiereName: serializer.fromJson<String?>(json['matiereName']),
      answersJson: serializer.fromJson<String>(json['answersJson']),
      score: serializer.fromJson<double>(json['score']),
      correctAnswers: serializer.fromJson<int>(json['correctAnswers']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      synced: serializer.fromJson<bool>(json['synced']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'quizId': serializer.toJson<String>(quizId),
      'quizTitle': serializer.toJson<String>(quizTitle),
      'matiereName': serializer.toJson<String?>(matiereName),
      'answersJson': serializer.toJson<String>(answersJson),
      'score': serializer.toJson<double>(score),
      'correctAnswers': serializer.toJson<int>(correctAnswers),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'synced': serializer.toJson<bool>(synced),
      'completedAt': serializer.toJson<DateTime>(completedAt),
    };
  }

  OfflineQuizSessionRow copyWith(
          {String? id,
          String? quizId,
          String? quizTitle,
          Value<String?> matiereName = const Value.absent(),
          String? answersJson,
          double? score,
          int? correctAnswers,
          int? totalQuestions,
          int? durationSeconds,
          bool? synced,
          DateTime? completedAt}) =>
      OfflineQuizSessionRow(
        id: id ?? this.id,
        quizId: quizId ?? this.quizId,
        quizTitle: quizTitle ?? this.quizTitle,
        matiereName: matiereName.present ? matiereName.value : this.matiereName,
        answersJson: answersJson ?? this.answersJson,
        score: score ?? this.score,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        totalQuestions: totalQuestions ?? this.totalQuestions,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        synced: synced ?? this.synced,
        completedAt: completedAt ?? this.completedAt,
      );
  OfflineQuizSessionRow copyWithCompanion(OfflineQuizSessionsCompanion data) {
    return OfflineQuizSessionRow(
      id: data.id.present ? data.id.value : this.id,
      quizId: data.quizId.present ? data.quizId.value : this.quizId,
      quizTitle: data.quizTitle.present ? data.quizTitle.value : this.quizTitle,
      matiereName:
          data.matiereName.present ? data.matiereName.value : this.matiereName,
      answersJson:
          data.answersJson.present ? data.answersJson.value : this.answersJson,
      score: data.score.present ? data.score.value : this.score,
      correctAnswers: data.correctAnswers.present
          ? data.correctAnswers.value
          : this.correctAnswers,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      synced: data.synced.present ? data.synced.value : this.synced,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineQuizSessionRow(')
          ..write('id: $id, ')
          ..write('quizId: $quizId, ')
          ..write('quizTitle: $quizTitle, ')
          ..write('matiereName: $matiereName, ')
          ..write('answersJson: $answersJson, ')
          ..write('score: $score, ')
          ..write('correctAnswers: $correctAnswers, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('synced: $synced, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      quizId,
      quizTitle,
      matiereName,
      answersJson,
      score,
      correctAnswers,
      totalQuestions,
      durationSeconds,
      synced,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineQuizSessionRow &&
          other.id == this.id &&
          other.quizId == this.quizId &&
          other.quizTitle == this.quizTitle &&
          other.matiereName == this.matiereName &&
          other.answersJson == this.answersJson &&
          other.score == this.score &&
          other.correctAnswers == this.correctAnswers &&
          other.totalQuestions == this.totalQuestions &&
          other.durationSeconds == this.durationSeconds &&
          other.synced == this.synced &&
          other.completedAt == this.completedAt);
}

class OfflineQuizSessionsCompanion
    extends UpdateCompanion<OfflineQuizSessionRow> {
  final Value<String> id;
  final Value<String> quizId;
  final Value<String> quizTitle;
  final Value<String?> matiereName;
  final Value<String> answersJson;
  final Value<double> score;
  final Value<int> correctAnswers;
  final Value<int> totalQuestions;
  final Value<int> durationSeconds;
  final Value<bool> synced;
  final Value<DateTime> completedAt;
  final Value<int> rowid;
  const OfflineQuizSessionsCompanion({
    this.id = const Value.absent(),
    this.quizId = const Value.absent(),
    this.quizTitle = const Value.absent(),
    this.matiereName = const Value.absent(),
    this.answersJson = const Value.absent(),
    this.score = const Value.absent(),
    this.correctAnswers = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.synced = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineQuizSessionsCompanion.insert({
    required String id,
    required String quizId,
    required String quizTitle,
    this.matiereName = const Value.absent(),
    required String answersJson,
    required double score,
    required int correctAnswers,
    required int totalQuestions,
    required int durationSeconds,
    required bool synced,
    required DateTime completedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        quizId = Value(quizId),
        quizTitle = Value(quizTitle),
        answersJson = Value(answersJson),
        score = Value(score),
        correctAnswers = Value(correctAnswers),
        totalQuestions = Value(totalQuestions),
        durationSeconds = Value(durationSeconds),
        synced = Value(synced),
        completedAt = Value(completedAt);
  static Insertable<OfflineQuizSessionRow> custom({
    Expression<String>? id,
    Expression<String>? quizId,
    Expression<String>? quizTitle,
    Expression<String>? matiereName,
    Expression<String>? answersJson,
    Expression<double>? score,
    Expression<int>? correctAnswers,
    Expression<int>? totalQuestions,
    Expression<int>? durationSeconds,
    Expression<bool>? synced,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (quizId != null) 'quiz_id': quizId,
      if (quizTitle != null) 'quiz_title': quizTitle,
      if (matiereName != null) 'matiere_name': matiereName,
      if (answersJson != null) 'answers_json': answersJson,
      if (score != null) 'score': score,
      if (correctAnswers != null) 'correct_answers': correctAnswers,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (synced != null) 'synced': synced,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineQuizSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? quizId,
      Value<String>? quizTitle,
      Value<String?>? matiereName,
      Value<String>? answersJson,
      Value<double>? score,
      Value<int>? correctAnswers,
      Value<int>? totalQuestions,
      Value<int>? durationSeconds,
      Value<bool>? synced,
      Value<DateTime>? completedAt,
      Value<int>? rowid}) {
    return OfflineQuizSessionsCompanion(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      quizTitle: quizTitle ?? this.quizTitle,
      matiereName: matiereName ?? this.matiereName,
      answersJson: answersJson ?? this.answersJson,
      score: score ?? this.score,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      synced: synced ?? this.synced,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (quizId.present) {
      map['quiz_id'] = Variable<String>(quizId.value);
    }
    if (quizTitle.present) {
      map['quiz_title'] = Variable<String>(quizTitle.value);
    }
    if (matiereName.present) {
      map['matiere_name'] = Variable<String>(matiereName.value);
    }
    if (answersJson.present) {
      map['answers_json'] = Variable<String>(answersJson.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (correctAnswers.present) {
      map['correct_answers'] = Variable<int>(correctAnswers.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineQuizSessionsCompanion(')
          ..write('id: $id, ')
          ..write('quizId: $quizId, ')
          ..write('quizTitle: $quizTitle, ')
          ..write('matiereName: $matiereName, ')
          ..write('answersJson: $answersJson, ')
          ..write('score: $score, ')
          ..write('correctAnswers: $correctAnswers, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('synced: $synced, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, operation, entityId, payloadJson, retryCount, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    } else if (isInserting) {
      context.missing(_retryCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json']),
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncItemRow extends DataClass implements Insertable<SyncItemRow> {
  final int id;
  final String operation;
  final String entityId;
  final String? payloadJson;
  final int retryCount;
  final DateTime createdAt;
  const SyncItemRow(
      {required this.id,
      required this.operation,
      required this.entityId,
      this.payloadJson,
      required this.retryCount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation'] = Variable<String>(operation);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      operation: Value(operation),
      entityId: Value(entityId),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory SyncItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncItemRow(
      id: serializer.fromJson<int>(json['id']),
      operation: serializer.fromJson<String>(json['operation']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operation': serializer.toJson<String>(operation),
      'entityId': serializer.toJson<String>(entityId),
      'payloadJson': serializer.toJson<String?>(payloadJson),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncItemRow copyWith(
          {int? id,
          String? operation,
          String? entityId,
          Value<String?> payloadJson = const Value.absent(),
          int? retryCount,
          DateTime? createdAt}) =>
      SyncItemRow(
        id: id ?? this.id,
        operation: operation ?? this.operation,
        entityId: entityId ?? this.entityId,
        payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
        retryCount: retryCount ?? this.retryCount,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncItemRow copyWithCompanion(SyncQueueCompanion data) {
    return SyncItemRow(
      id: data.id.present ? data.id.value : this.id,
      operation: data.operation.present ? data.operation.value : this.operation,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncItemRow(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, operation, entityId, payloadJson, retryCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncItemRow &&
          other.id == this.id &&
          other.operation == this.operation &&
          other.entityId == this.entityId &&
          other.payloadJson == this.payloadJson &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncItemRow> {
  final Value<int> id;
  final Value<String> operation;
  final Value<String> entityId;
  final Value<String?> payloadJson;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.operation = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String operation,
    required String entityId,
    this.payloadJson = const Value.absent(),
    required int retryCount,
    required DateTime createdAt,
  })  : operation = Value(operation),
        entityId = Value(entityId),
        retryCount = Value(retryCount),
        createdAt = Value(createdAt);
  static Insertable<SyncItemRow> custom({
    Expression<int>? id,
    Expression<String>? operation,
    Expression<String>? entityId,
    Expression<String>? payloadJson,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operation != null) 'operation': operation,
      if (entityId != null) 'entity_id': entityId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? operation,
      Value<String>? entityId,
      Value<String?>? payloadJson,
      Value<int>? retryCount,
      Value<DateTime>? createdAt}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      entityId: entityId ?? this.entityId,
      payloadJson: payloadJson ?? this.payloadJson,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('operation: $operation, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SearchCacheTable extends SearchCache
    with TableInfo<$SearchCacheTable, SearchCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta =
      const VerificationMeta('cacheKey');
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
      'cache_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataJsonMeta =
      const VerificationMeta('dataJson');
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
      'data_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [cacheKey, dataJson, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_cache';
  @override
  VerificationContext validateIntegrity(Insertable<SearchCacheRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta));
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(_dataJsonMeta,
          dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta));
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  SearchCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchCacheRow(
      cacheKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_key'])!,
      dataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_json'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $SearchCacheTable createAlias(String alias) {
    return $SearchCacheTable(attachedDatabase, alias);
  }
}

class SearchCacheRow extends DataClass implements Insertable<SearchCacheRow> {
  final String cacheKey;
  final String dataJson;
  final DateTime cachedAt;
  const SearchCacheRow(
      {required this.cacheKey, required this.dataJson, required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['data_json'] = Variable<String>(dataJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  SearchCacheCompanion toCompanion(bool nullToAbsent) {
    return SearchCacheCompanion(
      cacheKey: Value(cacheKey),
      dataJson: Value(dataJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory SearchCacheRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchCacheRow(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'dataJson': serializer.toJson<String>(dataJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  SearchCacheRow copyWith(
          {String? cacheKey, String? dataJson, DateTime? cachedAt}) =>
      SearchCacheRow(
        cacheKey: cacheKey ?? this.cacheKey,
        dataJson: dataJson ?? this.dataJson,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  SearchCacheRow copyWithCompanion(SearchCacheCompanion data) {
    return SearchCacheRow(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchCacheRow(')
          ..write('cacheKey: $cacheKey, ')
          ..write('dataJson: $dataJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, dataJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchCacheRow &&
          other.cacheKey == this.cacheKey &&
          other.dataJson == this.dataJson &&
          other.cachedAt == this.cachedAt);
}

class SearchCacheCompanion extends UpdateCompanion<SearchCacheRow> {
  final Value<String> cacheKey;
  final Value<String> dataJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const SearchCacheCompanion({
    this.cacheKey = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchCacheCompanion.insert({
    required String cacheKey,
    required String dataJson,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : cacheKey = Value(cacheKey),
        dataJson = Value(dataJson),
        cachedAt = Value(cachedAt);
  static Insertable<SearchCacheRow> custom({
    Expression<String>? cacheKey,
    Expression<String>? dataJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (dataJson != null) 'data_json': dataJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchCacheCompanion copyWith(
      {Value<String>? cacheKey,
      Value<String>? dataJson,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return SearchCacheCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      dataJson: dataJson ?? this.dataJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchCacheCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('dataJson: $dataJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedDocumentsTable cachedDocuments =
      $CachedDocumentsTable(this);
  late final $LocalFavoritesTable localFavorites = $LocalFavoritesTable(this);
  late final $OfflineQuizSessionsTable offlineQuizSessions =
      $OfflineQuizSessionsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SearchCacheTable searchCache = $SearchCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cachedDocuments,
        localFavorites,
        offlineQuizSessions,
        syncQueue,
        searchCache
      ];
}

typedef $$CachedDocumentsTableCreateCompanionBuilder = CachedDocumentsCompanion
    Function({
  required String id,
  required String title,
  Value<String?> levelName,
  Value<String?> classeName,
  Value<String?> matiereName,
  Value<String?> typeExamenName,
  Value<int?> annee,
  required bool hasCorrige,
  required bool isOfficial,
  required double rating,
  required int fileSizeKb,
  Value<String?> localFilePath,
  Value<String?> localCorigePath,
  required DateTime downloadedAt,
  Value<String?> fileUrl,
  Value<String?> fileType,
  Value<int> rowid,
});
typedef $$CachedDocumentsTableUpdateCompanionBuilder = CachedDocumentsCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String?> levelName,
  Value<String?> classeName,
  Value<String?> matiereName,
  Value<String?> typeExamenName,
  Value<int?> annee,
  Value<bool> hasCorrige,
  Value<bool> isOfficial,
  Value<double> rating,
  Value<int> fileSizeKb,
  Value<String?> localFilePath,
  Value<String?> localCorigePath,
  Value<DateTime> downloadedAt,
  Value<String?> fileUrl,
  Value<String?> fileType,
  Value<int> rowid,
});

class $$CachedDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get levelName => $composableBuilder(
      column: $table.levelName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get classeName => $composableBuilder(
      column: $table.classeName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matiereName => $composableBuilder(
      column: $table.matiereName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get typeExamenName => $composableBuilder(
      column: $table.typeExamenName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get annee => $composableBuilder(
      column: $table.annee, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasCorrige => $composableBuilder(
      column: $table.hasCorrige, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isOfficial => $composableBuilder(
      column: $table.isOfficial, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSizeKb => $composableBuilder(
      column: $table.fileSizeKb, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localFilePath => $composableBuilder(
      column: $table.localFilePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localCorigePath => $composableBuilder(
      column: $table.localCorigePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileUrl => $composableBuilder(
      column: $table.fileUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileType => $composableBuilder(
      column: $table.fileType, builder: (column) => ColumnFilters(column));
}

class $$CachedDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get levelName => $composableBuilder(
      column: $table.levelName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get classeName => $composableBuilder(
      column: $table.classeName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matiereName => $composableBuilder(
      column: $table.matiereName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get typeExamenName => $composableBuilder(
      column: $table.typeExamenName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get annee => $composableBuilder(
      column: $table.annee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasCorrige => $composableBuilder(
      column: $table.hasCorrige, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isOfficial => $composableBuilder(
      column: $table.isOfficial, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeKb => $composableBuilder(
      column: $table.fileSizeKb, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localFilePath => $composableBuilder(
      column: $table.localFilePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localCorigePath => $composableBuilder(
      column: $table.localCorigePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileUrl => $composableBuilder(
      column: $table.fileUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileType => $composableBuilder(
      column: $table.fileType, builder: (column) => ColumnOrderings(column));
}

class $$CachedDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get levelName =>
      $composableBuilder(column: $table.levelName, builder: (column) => column);

  GeneratedColumn<String> get classeName => $composableBuilder(
      column: $table.classeName, builder: (column) => column);

  GeneratedColumn<String> get matiereName => $composableBuilder(
      column: $table.matiereName, builder: (column) => column);

  GeneratedColumn<String> get typeExamenName => $composableBuilder(
      column: $table.typeExamenName, builder: (column) => column);

  GeneratedColumn<int> get annee =>
      $composableBuilder(column: $table.annee, builder: (column) => column);

  GeneratedColumn<bool> get hasCorrige => $composableBuilder(
      column: $table.hasCorrige, builder: (column) => column);

  GeneratedColumn<bool> get isOfficial => $composableBuilder(
      column: $table.isOfficial, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get fileSizeKb => $composableBuilder(
      column: $table.fileSizeKb, builder: (column) => column);

  GeneratedColumn<String> get localFilePath => $composableBuilder(
      column: $table.localFilePath, builder: (column) => column);

  GeneratedColumn<String> get localCorigePath => $composableBuilder(
      column: $table.localCorigePath, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
      column: $table.downloadedAt, builder: (column) => column);

  GeneratedColumn<String> get fileUrl =>
      $composableBuilder(column: $table.fileUrl, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);
}

class $$CachedDocumentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedDocumentsTable,
    CachedDocumentRow,
    $$CachedDocumentsTableFilterComposer,
    $$CachedDocumentsTableOrderingComposer,
    $$CachedDocumentsTableAnnotationComposer,
    $$CachedDocumentsTableCreateCompanionBuilder,
    $$CachedDocumentsTableUpdateCompanionBuilder,
    (
      CachedDocumentRow,
      BaseReferences<_$AppDatabase, $CachedDocumentsTable, CachedDocumentRow>
    ),
    CachedDocumentRow,
    PrefetchHooks Function()> {
  $$CachedDocumentsTableTableManager(
      _$AppDatabase db, $CachedDocumentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> levelName = const Value.absent(),
            Value<String?> classeName = const Value.absent(),
            Value<String?> matiereName = const Value.absent(),
            Value<String?> typeExamenName = const Value.absent(),
            Value<int?> annee = const Value.absent(),
            Value<bool> hasCorrige = const Value.absent(),
            Value<bool> isOfficial = const Value.absent(),
            Value<double> rating = const Value.absent(),
            Value<int> fileSizeKb = const Value.absent(),
            Value<String?> localFilePath = const Value.absent(),
            Value<String?> localCorigePath = const Value.absent(),
            Value<DateTime> downloadedAt = const Value.absent(),
            Value<String?> fileUrl = const Value.absent(),
            Value<String?> fileType = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedDocumentsCompanion(
            id: id,
            title: title,
            levelName: levelName,
            classeName: classeName,
            matiereName: matiereName,
            typeExamenName: typeExamenName,
            annee: annee,
            hasCorrige: hasCorrige,
            isOfficial: isOfficial,
            rating: rating,
            fileSizeKb: fileSizeKb,
            localFilePath: localFilePath,
            localCorigePath: localCorigePath,
            downloadedAt: downloadedAt,
            fileUrl: fileUrl,
            fileType: fileType,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> levelName = const Value.absent(),
            Value<String?> classeName = const Value.absent(),
            Value<String?> matiereName = const Value.absent(),
            Value<String?> typeExamenName = const Value.absent(),
            Value<int?> annee = const Value.absent(),
            required bool hasCorrige,
            required bool isOfficial,
            required double rating,
            required int fileSizeKb,
            Value<String?> localFilePath = const Value.absent(),
            Value<String?> localCorigePath = const Value.absent(),
            required DateTime downloadedAt,
            Value<String?> fileUrl = const Value.absent(),
            Value<String?> fileType = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedDocumentsCompanion.insert(
            id: id,
            title: title,
            levelName: levelName,
            classeName: classeName,
            matiereName: matiereName,
            typeExamenName: typeExamenName,
            annee: annee,
            hasCorrige: hasCorrige,
            isOfficial: isOfficial,
            rating: rating,
            fileSizeKb: fileSizeKb,
            localFilePath: localFilePath,
            localCorigePath: localCorigePath,
            downloadedAt: downloadedAt,
            fileUrl: fileUrl,
            fileType: fileType,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedDocumentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedDocumentsTable,
    CachedDocumentRow,
    $$CachedDocumentsTableFilterComposer,
    $$CachedDocumentsTableOrderingComposer,
    $$CachedDocumentsTableAnnotationComposer,
    $$CachedDocumentsTableCreateCompanionBuilder,
    $$CachedDocumentsTableUpdateCompanionBuilder,
    (
      CachedDocumentRow,
      BaseReferences<_$AppDatabase, $CachedDocumentsTable, CachedDocumentRow>
    ),
    CachedDocumentRow,
    PrefetchHooks Function()>;
typedef $$LocalFavoritesTableCreateCompanionBuilder = LocalFavoritesCompanion
    Function({
  required String documentId,
  required bool pendingSync,
  required bool pendingDelete,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$LocalFavoritesTableUpdateCompanionBuilder = LocalFavoritesCompanion
    Function({
  Value<String> documentId,
  Value<bool> pendingSync,
  Value<bool> pendingDelete,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

class $$LocalFavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFavoritesTable> {
  $$LocalFavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pendingDelete => $composableBuilder(
      column: $table.pendingDelete, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalFavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFavoritesTable> {
  $$LocalFavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pendingDelete => $composableBuilder(
      column: $table.pendingDelete,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalFavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFavoritesTable> {
  $$LocalFavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync => $composableBuilder(
      column: $table.pendingSync, builder: (column) => column);

  GeneratedColumn<bool> get pendingDelete => $composableBuilder(
      column: $table.pendingDelete, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$LocalFavoritesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalFavoritesTable,
    LocalFavoriteRow,
    $$LocalFavoritesTableFilterComposer,
    $$LocalFavoritesTableOrderingComposer,
    $$LocalFavoritesTableAnnotationComposer,
    $$LocalFavoritesTableCreateCompanionBuilder,
    $$LocalFavoritesTableUpdateCompanionBuilder,
    (
      LocalFavoriteRow,
      BaseReferences<_$AppDatabase, $LocalFavoritesTable, LocalFavoriteRow>
    ),
    LocalFavoriteRow,
    PrefetchHooks Function()> {
  $$LocalFavoritesTableTableManager(
      _$AppDatabase db, $LocalFavoritesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalFavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalFavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> documentId = const Value.absent(),
            Value<bool> pendingSync = const Value.absent(),
            Value<bool> pendingDelete = const Value.absent(),
            Value<DateTime> addedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalFavoritesCompanion(
            documentId: documentId,
            pendingSync: pendingSync,
            pendingDelete: pendingDelete,
            addedAt: addedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String documentId,
            required bool pendingSync,
            required bool pendingDelete,
            required DateTime addedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalFavoritesCompanion.insert(
            documentId: documentId,
            pendingSync: pendingSync,
            pendingDelete: pendingDelete,
            addedAt: addedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalFavoritesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalFavoritesTable,
    LocalFavoriteRow,
    $$LocalFavoritesTableFilterComposer,
    $$LocalFavoritesTableOrderingComposer,
    $$LocalFavoritesTableAnnotationComposer,
    $$LocalFavoritesTableCreateCompanionBuilder,
    $$LocalFavoritesTableUpdateCompanionBuilder,
    (
      LocalFavoriteRow,
      BaseReferences<_$AppDatabase, $LocalFavoritesTable, LocalFavoriteRow>
    ),
    LocalFavoriteRow,
    PrefetchHooks Function()>;
typedef $$OfflineQuizSessionsTableCreateCompanionBuilder
    = OfflineQuizSessionsCompanion Function({
  required String id,
  required String quizId,
  required String quizTitle,
  Value<String?> matiereName,
  required String answersJson,
  required double score,
  required int correctAnswers,
  required int totalQuestions,
  required int durationSeconds,
  required bool synced,
  required DateTime completedAt,
  Value<int> rowid,
});
typedef $$OfflineQuizSessionsTableUpdateCompanionBuilder
    = OfflineQuizSessionsCompanion Function({
  Value<String> id,
  Value<String> quizId,
  Value<String> quizTitle,
  Value<String?> matiereName,
  Value<String> answersJson,
  Value<double> score,
  Value<int> correctAnswers,
  Value<int> totalQuestions,
  Value<int> durationSeconds,
  Value<bool> synced,
  Value<DateTime> completedAt,
  Value<int> rowid,
});

class $$OfflineQuizSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineQuizSessionsTable> {
  $$OfflineQuizSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quizId => $composableBuilder(
      column: $table.quizId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quizTitle => $composableBuilder(
      column: $table.quizTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matiereName => $composableBuilder(
      column: $table.matiereName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answersJson => $composableBuilder(
      column: $table.answersJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctAnswers => $composableBuilder(
      column: $table.correctAnswers,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalQuestions => $composableBuilder(
      column: $table.totalQuestions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$OfflineQuizSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineQuizSessionsTable> {
  $$OfflineQuizSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quizId => $composableBuilder(
      column: $table.quizId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quizTitle => $composableBuilder(
      column: $table.quizTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matiereName => $composableBuilder(
      column: $table.matiereName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answersJson => $composableBuilder(
      column: $table.answersJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get score => $composableBuilder(
      column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctAnswers => $composableBuilder(
      column: $table.correctAnswers,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
      column: $table.totalQuestions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get synced => $composableBuilder(
      column: $table.synced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$OfflineQuizSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineQuizSessionsTable> {
  $$OfflineQuizSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get quizId =>
      $composableBuilder(column: $table.quizId, builder: (column) => column);

  GeneratedColumn<String> get quizTitle =>
      $composableBuilder(column: $table.quizTitle, builder: (column) => column);

  GeneratedColumn<String> get matiereName => $composableBuilder(
      column: $table.matiereName, builder: (column) => column);

  GeneratedColumn<String> get answersJson => $composableBuilder(
      column: $table.answersJson, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get correctAnswers => $composableBuilder(
      column: $table.correctAnswers, builder: (column) => column);

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
      column: $table.totalQuestions, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$OfflineQuizSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OfflineQuizSessionsTable,
    OfflineQuizSessionRow,
    $$OfflineQuizSessionsTableFilterComposer,
    $$OfflineQuizSessionsTableOrderingComposer,
    $$OfflineQuizSessionsTableAnnotationComposer,
    $$OfflineQuizSessionsTableCreateCompanionBuilder,
    $$OfflineQuizSessionsTableUpdateCompanionBuilder,
    (
      OfflineQuizSessionRow,
      BaseReferences<_$AppDatabase, $OfflineQuizSessionsTable,
          OfflineQuizSessionRow>
    ),
    OfflineQuizSessionRow,
    PrefetchHooks Function()> {
  $$OfflineQuizSessionsTableTableManager(
      _$AppDatabase db, $OfflineQuizSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineQuizSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineQuizSessionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineQuizSessionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> quizId = const Value.absent(),
            Value<String> quizTitle = const Value.absent(),
            Value<String?> matiereName = const Value.absent(),
            Value<String> answersJson = const Value.absent(),
            Value<double> score = const Value.absent(),
            Value<int> correctAnswers = const Value.absent(),
            Value<int> totalQuestions = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<bool> synced = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              OfflineQuizSessionsCompanion(
            id: id,
            quizId: quizId,
            quizTitle: quizTitle,
            matiereName: matiereName,
            answersJson: answersJson,
            score: score,
            correctAnswers: correctAnswers,
            totalQuestions: totalQuestions,
            durationSeconds: durationSeconds,
            synced: synced,
            completedAt: completedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String quizId,
            required String quizTitle,
            Value<String?> matiereName = const Value.absent(),
            required String answersJson,
            required double score,
            required int correctAnswers,
            required int totalQuestions,
            required int durationSeconds,
            required bool synced,
            required DateTime completedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              OfflineQuizSessionsCompanion.insert(
            id: id,
            quizId: quizId,
            quizTitle: quizTitle,
            matiereName: matiereName,
            answersJson: answersJson,
            score: score,
            correctAnswers: correctAnswers,
            totalQuestions: totalQuestions,
            durationSeconds: durationSeconds,
            synced: synced,
            completedAt: completedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$OfflineQuizSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $OfflineQuizSessionsTable,
    OfflineQuizSessionRow,
    $$OfflineQuizSessionsTableFilterComposer,
    $$OfflineQuizSessionsTableOrderingComposer,
    $$OfflineQuizSessionsTableAnnotationComposer,
    $$OfflineQuizSessionsTableCreateCompanionBuilder,
    $$OfflineQuizSessionsTableUpdateCompanionBuilder,
    (
      OfflineQuizSessionRow,
      BaseReferences<_$AppDatabase, $OfflineQuizSessionsTable,
          OfflineQuizSessionRow>
    ),
    OfflineQuizSessionRow,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String operation,
  required String entityId,
  Value<String?> payloadJson,
  required int retryCount,
  required DateTime createdAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> operation,
  Value<String> entityId,
  Value<String?> payloadJson,
  Value<int> retryCount,
  Value<DateTime> createdAt,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncItemRow,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (SyncItemRow, BaseReferences<_$AppDatabase, $SyncQueueTable, SyncItemRow>),
    SyncItemRow,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String?> payloadJson = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            operation: operation,
            entityId: entityId,
            payloadJson: payloadJson,
            retryCount: retryCount,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String operation,
            required String entityId,
            Value<String?> payloadJson = const Value.absent(),
            required int retryCount,
            required DateTime createdAt,
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            operation: operation,
            entityId: entityId,
            payloadJson: payloadJson,
            retryCount: retryCount,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncItemRow,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (SyncItemRow, BaseReferences<_$AppDatabase, $SyncQueueTable, SyncItemRow>),
    SyncItemRow,
    PrefetchHooks Function()>;
typedef $$SearchCacheTableCreateCompanionBuilder = SearchCacheCompanion
    Function({
  required String cacheKey,
  required String dataJson,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$SearchCacheTableUpdateCompanionBuilder = SearchCacheCompanion
    Function({
  Value<String> cacheKey,
  Value<String> dataJson,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$SearchCacheTableFilterComposer
    extends Composer<_$AppDatabase, $SearchCacheTable> {
  $$SearchCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataJson => $composableBuilder(
      column: $table.dataJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$SearchCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchCacheTable> {
  $$SearchCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataJson => $composableBuilder(
      column: $table.dataJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$SearchCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchCacheTable> {
  $$SearchCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$SearchCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SearchCacheTable,
    SearchCacheRow,
    $$SearchCacheTableFilterComposer,
    $$SearchCacheTableOrderingComposer,
    $$SearchCacheTableAnnotationComposer,
    $$SearchCacheTableCreateCompanionBuilder,
    $$SearchCacheTableUpdateCompanionBuilder,
    (
      SearchCacheRow,
      BaseReferences<_$AppDatabase, $SearchCacheTable, SearchCacheRow>
    ),
    SearchCacheRow,
    PrefetchHooks Function()> {
  $$SearchCacheTableTableManager(_$AppDatabase db, $SearchCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> cacheKey = const Value.absent(),
            Value<String> dataJson = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SearchCacheCompanion(
            cacheKey: cacheKey,
            dataJson: dataJson,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cacheKey,
            required String dataJson,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SearchCacheCompanion.insert(
            cacheKey: cacheKey,
            dataJson: dataJson,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SearchCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SearchCacheTable,
    SearchCacheRow,
    $$SearchCacheTableFilterComposer,
    $$SearchCacheTableOrderingComposer,
    $$SearchCacheTableAnnotationComposer,
    $$SearchCacheTableCreateCompanionBuilder,
    $$SearchCacheTableUpdateCompanionBuilder,
    (
      SearchCacheRow,
      BaseReferences<_$AppDatabase, $SearchCacheTable, SearchCacheRow>
    ),
    SearchCacheRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedDocumentsTableTableManager get cachedDocuments =>
      $$CachedDocumentsTableTableManager(_db, _db.cachedDocuments);
  $$LocalFavoritesTableTableManager get localFavorites =>
      $$LocalFavoritesTableTableManager(_db, _db.localFavorites);
  $$OfflineQuizSessionsTableTableManager get offlineQuizSessions =>
      $$OfflineQuizSessionsTableTableManager(_db, _db.offlineQuizSessions);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SearchCacheTableTableManager get searchCache =>
      $$SearchCacheTableTableManager(_db, _db.searchCache);
}
