// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MissionsTable extends Missions with TableInfo<$MissionsTable, Mission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createTimeMeta = const VerificationMeta(
    'createTime',
  );
  @override
  late final GeneratedColumn<int> createTime = GeneratedColumn<int>(
    'create_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _waypointCountMeta = const VerificationMeta(
    'waypointCount',
  );
  @override
  late final GeneratedColumn<int> waypointCount = GeneratedColumn<int>(
    'waypoint_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _finishActionMeta = const VerificationMeta(
    'finishAction',
  );
  @override
  late final GeneratedColumn<String> finishAction = GeneratedColumn<String>(
    'finish_action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('goHome'),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<int> importedAt = GeneratedColumn<int>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('imported'),
  );
  static const VerificationMeta _parentMissionIdMeta = const VerificationMeta(
    'parentMissionId',
  );
  @override
  late final GeneratedColumn<String> parentMissionId = GeneratedColumn<String>(
    'parent_mission_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _segmentIndexMeta = const VerificationMeta(
    'segmentIndex',
  );
  @override
  late final GeneratedColumn<int> segmentIndex = GeneratedColumn<int>(
    'segment_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileName,
    author,
    createTime,
    waypointCount,
    finishAction,
    filePath,
    importedAt,
    sourceType,
    parentMissionId,
    segmentIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'missions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Mission> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('create_time')) {
      context.handle(
        _createTimeMeta,
        createTime.isAcceptableOrUnknown(data['create_time']!, _createTimeMeta),
      );
    }
    if (data.containsKey('waypoint_count')) {
      context.handle(
        _waypointCountMeta,
        waypointCount.isAcceptableOrUnknown(
          data['waypoint_count']!,
          _waypointCountMeta,
        ),
      );
    }
    if (data.containsKey('finish_action')) {
      context.handle(
        _finishActionMeta,
        finishAction.isAcceptableOrUnknown(
          data['finish_action']!,
          _finishActionMeta,
        ),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('parent_mission_id')) {
      context.handle(
        _parentMissionIdMeta,
        parentMissionId.isAcceptableOrUnknown(
          data['parent_mission_id']!,
          _parentMissionIdMeta,
        ),
      );
    }
    if (data.containsKey('segment_index')) {
      context.handle(
        _segmentIndexMeta,
        segmentIndex.isAcceptableOrUnknown(
          data['segment_index']!,
          _segmentIndexMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Mission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Mission(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      createTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}create_time'],
      ),
      waypointCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}waypoint_count'],
      )!,
      finishAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finish_action'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imported_at'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      parentMissionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_mission_id'],
      ),
      segmentIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment_index'],
      ),
    );
  }

  @override
  $MissionsTable createAlias(String alias) {
    return $MissionsTable(attachedDatabase, alias);
  }
}

class Mission extends DataClass implements Insertable<Mission> {
  final String id;
  final String fileName;
  final String? author;
  final int? createTime;
  final int waypointCount;
  final String finishAction;
  final String filePath;
  final int importedAt;
  final String sourceType;
  final String? parentMissionId;
  final int? segmentIndex;
  const Mission({
    required this.id,
    required this.fileName,
    this.author,
    this.createTime,
    required this.waypointCount,
    required this.finishAction,
    required this.filePath,
    required this.importedAt,
    required this.sourceType,
    this.parentMissionId,
    this.segmentIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['file_name'] = Variable<String>(fileName);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || createTime != null) {
      map['create_time'] = Variable<int>(createTime);
    }
    map['waypoint_count'] = Variable<int>(waypointCount);
    map['finish_action'] = Variable<String>(finishAction);
    map['file_path'] = Variable<String>(filePath);
    map['imported_at'] = Variable<int>(importedAt);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || parentMissionId != null) {
      map['parent_mission_id'] = Variable<String>(parentMissionId);
    }
    if (!nullToAbsent || segmentIndex != null) {
      map['segment_index'] = Variable<int>(segmentIndex);
    }
    return map;
  }

  MissionsCompanion toCompanion(bool nullToAbsent) {
    return MissionsCompanion(
      id: Value(id),
      fileName: Value(fileName),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      createTime: createTime == null && nullToAbsent
          ? const Value.absent()
          : Value(createTime),
      waypointCount: Value(waypointCount),
      finishAction: Value(finishAction),
      filePath: Value(filePath),
      importedAt: Value(importedAt),
      sourceType: Value(sourceType),
      parentMissionId: parentMissionId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentMissionId),
      segmentIndex: segmentIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(segmentIndex),
    );
  }

  factory Mission.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Mission(
      id: serializer.fromJson<String>(json['id']),
      fileName: serializer.fromJson<String>(json['fileName']),
      author: serializer.fromJson<String?>(json['author']),
      createTime: serializer.fromJson<int?>(json['createTime']),
      waypointCount: serializer.fromJson<int>(json['waypointCount']),
      finishAction: serializer.fromJson<String>(json['finishAction']),
      filePath: serializer.fromJson<String>(json['filePath']),
      importedAt: serializer.fromJson<int>(json['importedAt']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      parentMissionId: serializer.fromJson<String?>(json['parentMissionId']),
      segmentIndex: serializer.fromJson<int?>(json['segmentIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fileName': serializer.toJson<String>(fileName),
      'author': serializer.toJson<String?>(author),
      'createTime': serializer.toJson<int?>(createTime),
      'waypointCount': serializer.toJson<int>(waypointCount),
      'finishAction': serializer.toJson<String>(finishAction),
      'filePath': serializer.toJson<String>(filePath),
      'importedAt': serializer.toJson<int>(importedAt),
      'sourceType': serializer.toJson<String>(sourceType),
      'parentMissionId': serializer.toJson<String?>(parentMissionId),
      'segmentIndex': serializer.toJson<int?>(segmentIndex),
    };
  }

  Mission copyWith({
    String? id,
    String? fileName,
    Value<String?> author = const Value.absent(),
    Value<int?> createTime = const Value.absent(),
    int? waypointCount,
    String? finishAction,
    String? filePath,
    int? importedAt,
    String? sourceType,
    Value<String?> parentMissionId = const Value.absent(),
    Value<int?> segmentIndex = const Value.absent(),
  }) => Mission(
    id: id ?? this.id,
    fileName: fileName ?? this.fileName,
    author: author.present ? author.value : this.author,
    createTime: createTime.present ? createTime.value : this.createTime,
    waypointCount: waypointCount ?? this.waypointCount,
    finishAction: finishAction ?? this.finishAction,
    filePath: filePath ?? this.filePath,
    importedAt: importedAt ?? this.importedAt,
    sourceType: sourceType ?? this.sourceType,
    parentMissionId: parentMissionId.present
        ? parentMissionId.value
        : this.parentMissionId,
    segmentIndex: segmentIndex.present ? segmentIndex.value : this.segmentIndex,
  );
  Mission copyWithCompanion(MissionsCompanion data) {
    return Mission(
      id: data.id.present ? data.id.value : this.id,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      author: data.author.present ? data.author.value : this.author,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
      waypointCount: data.waypointCount.present
          ? data.waypointCount.value
          : this.waypointCount,
      finishAction: data.finishAction.present
          ? data.finishAction.value
          : this.finishAction,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      parentMissionId: data.parentMissionId.present
          ? data.parentMissionId.value
          : this.parentMissionId,
      segmentIndex: data.segmentIndex.present
          ? data.segmentIndex.value
          : this.segmentIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Mission(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('author: $author, ')
          ..write('createTime: $createTime, ')
          ..write('waypointCount: $waypointCount, ')
          ..write('finishAction: $finishAction, ')
          ..write('filePath: $filePath, ')
          ..write('importedAt: $importedAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('parentMissionId: $parentMissionId, ')
          ..write('segmentIndex: $segmentIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fileName,
    author,
    createTime,
    waypointCount,
    finishAction,
    filePath,
    importedAt,
    sourceType,
    parentMissionId,
    segmentIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Mission &&
          other.id == this.id &&
          other.fileName == this.fileName &&
          other.author == this.author &&
          other.createTime == this.createTime &&
          other.waypointCount == this.waypointCount &&
          other.finishAction == this.finishAction &&
          other.filePath == this.filePath &&
          other.importedAt == this.importedAt &&
          other.sourceType == this.sourceType &&
          other.parentMissionId == this.parentMissionId &&
          other.segmentIndex == this.segmentIndex);
}

class MissionsCompanion extends UpdateCompanion<Mission> {
  final Value<String> id;
  final Value<String> fileName;
  final Value<String?> author;
  final Value<int?> createTime;
  final Value<int> waypointCount;
  final Value<String> finishAction;
  final Value<String> filePath;
  final Value<int> importedAt;
  final Value<String> sourceType;
  final Value<String?> parentMissionId;
  final Value<int?> segmentIndex;
  final Value<int> rowid;
  const MissionsCompanion({
    this.id = const Value.absent(),
    this.fileName = const Value.absent(),
    this.author = const Value.absent(),
    this.createTime = const Value.absent(),
    this.waypointCount = const Value.absent(),
    this.finishAction = const Value.absent(),
    this.filePath = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.parentMissionId = const Value.absent(),
    this.segmentIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MissionsCompanion.insert({
    required String id,
    required String fileName,
    this.author = const Value.absent(),
    this.createTime = const Value.absent(),
    this.waypointCount = const Value.absent(),
    this.finishAction = const Value.absent(),
    required String filePath,
    required int importedAt,
    this.sourceType = const Value.absent(),
    this.parentMissionId = const Value.absent(),
    this.segmentIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       fileName = Value(fileName),
       filePath = Value(filePath),
       importedAt = Value(importedAt);
  static Insertable<Mission> custom({
    Expression<String>? id,
    Expression<String>? fileName,
    Expression<String>? author,
    Expression<int>? createTime,
    Expression<int>? waypointCount,
    Expression<String>? finishAction,
    Expression<String>? filePath,
    Expression<int>? importedAt,
    Expression<String>? sourceType,
    Expression<String>? parentMissionId,
    Expression<int>? segmentIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileName != null) 'file_name': fileName,
      if (author != null) 'author': author,
      if (createTime != null) 'create_time': createTime,
      if (waypointCount != null) 'waypoint_count': waypointCount,
      if (finishAction != null) 'finish_action': finishAction,
      if (filePath != null) 'file_path': filePath,
      if (importedAt != null) 'imported_at': importedAt,
      if (sourceType != null) 'source_type': sourceType,
      if (parentMissionId != null) 'parent_mission_id': parentMissionId,
      if (segmentIndex != null) 'segment_index': segmentIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MissionsCompanion copyWith({
    Value<String>? id,
    Value<String>? fileName,
    Value<String?>? author,
    Value<int?>? createTime,
    Value<int>? waypointCount,
    Value<String>? finishAction,
    Value<String>? filePath,
    Value<int>? importedAt,
    Value<String>? sourceType,
    Value<String?>? parentMissionId,
    Value<int?>? segmentIndex,
    Value<int>? rowid,
  }) {
    return MissionsCompanion(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      author: author ?? this.author,
      createTime: createTime ?? this.createTime,
      waypointCount: waypointCount ?? this.waypointCount,
      finishAction: finishAction ?? this.finishAction,
      filePath: filePath ?? this.filePath,
      importedAt: importedAt ?? this.importedAt,
      sourceType: sourceType ?? this.sourceType,
      parentMissionId: parentMissionId ?? this.parentMissionId,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<int>(createTime.value);
    }
    if (waypointCount.present) {
      map['waypoint_count'] = Variable<int>(waypointCount.value);
    }
    if (finishAction.present) {
      map['finish_action'] = Variable<String>(finishAction.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<int>(importedAt.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (parentMissionId.present) {
      map['parent_mission_id'] = Variable<String>(parentMissionId.value);
    }
    if (segmentIndex.present) {
      map['segment_index'] = Variable<int>(segmentIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MissionsCompanion(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('author: $author, ')
          ..write('createTime: $createTime, ')
          ..write('waypointCount: $waypointCount, ')
          ..write('finishAction: $finishAction, ')
          ..write('filePath: $filePath, ')
          ..write('importedAt: $importedAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('parentMissionId: $parentMissionId, ')
          ..write('segmentIndex: $segmentIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MissionsTable missions = $MissionsTable(this);
  late final MissionDao missionDao = MissionDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [missions];
}

typedef $$MissionsTableCreateCompanionBuilder =
    MissionsCompanion Function({
      required String id,
      required String fileName,
      Value<String?> author,
      Value<int?> createTime,
      Value<int> waypointCount,
      Value<String> finishAction,
      required String filePath,
      required int importedAt,
      Value<String> sourceType,
      Value<String?> parentMissionId,
      Value<int?> segmentIndex,
      Value<int> rowid,
    });
typedef $$MissionsTableUpdateCompanionBuilder =
    MissionsCompanion Function({
      Value<String> id,
      Value<String> fileName,
      Value<String?> author,
      Value<int?> createTime,
      Value<int> waypointCount,
      Value<String> finishAction,
      Value<String> filePath,
      Value<int> importedAt,
      Value<String> sourceType,
      Value<String?> parentMissionId,
      Value<int?> segmentIndex,
      Value<int> rowid,
    });

class $$MissionsTableFilterComposer
    extends Composer<_$AppDatabase, $MissionsTable> {
  $$MissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get waypointCount => $composableBuilder(
    column: $table.waypointCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finishAction => $composableBuilder(
    column: $table.finishAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentMissionId => $composableBuilder(
    column: $table.parentMissionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segmentIndex => $composableBuilder(
    column: $table.segmentIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $MissionsTable> {
  $$MissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get waypointCount => $composableBuilder(
    column: $table.waypointCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finishAction => $composableBuilder(
    column: $table.finishAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentMissionId => $composableBuilder(
    column: $table.parentMissionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segmentIndex => $composableBuilder(
    column: $table.segmentIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MissionsTable> {
  $$MissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => column,
  );

  GeneratedColumn<int> get waypointCount => $composableBuilder(
    column: $table.waypointCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finishAction => $composableBuilder(
    column: $table.finishAction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentMissionId => $composableBuilder(
    column: $table.parentMissionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get segmentIndex => $composableBuilder(
    column: $table.segmentIndex,
    builder: (column) => column,
  );
}

class $$MissionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MissionsTable,
          Mission,
          $$MissionsTableFilterComposer,
          $$MissionsTableOrderingComposer,
          $$MissionsTableAnnotationComposer,
          $$MissionsTableCreateCompanionBuilder,
          $$MissionsTableUpdateCompanionBuilder,
          (Mission, BaseReferences<_$AppDatabase, $MissionsTable, Mission>),
          Mission,
          PrefetchHooks Function()
        > {
  $$MissionsTableTableManager(_$AppDatabase db, $MissionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MissionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MissionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<int?> createTime = const Value.absent(),
                Value<int> waypointCount = const Value.absent(),
                Value<String> finishAction = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> importedAt = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> parentMissionId = const Value.absent(),
                Value<int?> segmentIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MissionsCompanion(
                id: id,
                fileName: fileName,
                author: author,
                createTime: createTime,
                waypointCount: waypointCount,
                finishAction: finishAction,
                filePath: filePath,
                importedAt: importedAt,
                sourceType: sourceType,
                parentMissionId: parentMissionId,
                segmentIndex: segmentIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String fileName,
                Value<String?> author = const Value.absent(),
                Value<int?> createTime = const Value.absent(),
                Value<int> waypointCount = const Value.absent(),
                Value<String> finishAction = const Value.absent(),
                required String filePath,
                required int importedAt,
                Value<String> sourceType = const Value.absent(),
                Value<String?> parentMissionId = const Value.absent(),
                Value<int?> segmentIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MissionsCompanion.insert(
                id: id,
                fileName: fileName,
                author: author,
                createTime: createTime,
                waypointCount: waypointCount,
                finishAction: finishAction,
                filePath: filePath,
                importedAt: importedAt,
                sourceType: sourceType,
                parentMissionId: parentMissionId,
                segmentIndex: segmentIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MissionsTable,
      Mission,
      $$MissionsTableFilterComposer,
      $$MissionsTableOrderingComposer,
      $$MissionsTableAnnotationComposer,
      $$MissionsTableCreateCompanionBuilder,
      $$MissionsTableUpdateCompanionBuilder,
      (Mission, BaseReferences<_$AppDatabase, $MissionsTable, Mission>),
      Mission,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MissionsTableTableManager get missions =>
      $$MissionsTableTableManager(_db, _db.missions);
}
