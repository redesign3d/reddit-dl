// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SavedItemsTable extends SavedItems
    with TableInfo<$SavedItemsTable, SavedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _permalinkMeta = const VerificationMeta(
    'permalink',
  );
  @override
  late final GeneratedColumn<String> permalink = GeneratedColumn<String>(
    'permalink',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subredditMeta = const VerificationMeta(
    'subreddit',
  );
  @override
  late final GeneratedColumn<String> subreddit = GeneratedColumn<String>(
    'subreddit',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdUtcMeta = const VerificationMeta(
    'createdUtc',
  );
  @override
  late final GeneratedColumn<int> createdUtc = GeneratedColumn<int>(
    'created_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMarkdownMeta = const VerificationMeta(
    'bodyMarkdown',
  );
  @override
  late final GeneratedColumn<String> bodyMarkdown = GeneratedColumn<String>(
    'body_markdown',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _over18Meta = const VerificationMeta('over18');
  @override
  late final GeneratedColumn<bool> over18 = GeneratedColumn<bool>(
    'over18',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("over18" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastResolvedAtMeta = const VerificationMeta(
    'lastResolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastResolvedAt =
      GeneratedColumn<DateTime>(
        'last_resolved_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _resolutionStatusMeta = const VerificationMeta(
    'resolutionStatus',
  );
  @override
  late final GeneratedColumn<String> resolutionStatus = GeneratedColumn<String>(
    'resolution_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawJsonCacheMeta = const VerificationMeta(
    'rawJsonCache',
  );
  @override
  late final GeneratedColumn<String> rawJsonCache = GeneratedColumn<String>(
    'raw_json_cache',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    permalink,
    kind,
    subreddit,
    author,
    createdUtc,
    title,
    bodyMarkdown,
    over18,
    source,
    importedAt,
    syncedAt,
    lastResolvedAt,
    resolutionStatus,
    rawJsonCache,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('permalink')) {
      context.handle(
        _permalinkMeta,
        permalink.isAcceptableOrUnknown(data['permalink']!, _permalinkMeta),
      );
    } else if (isInserting) {
      context.missing(_permalinkMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('subreddit')) {
      context.handle(
        _subredditMeta,
        subreddit.isAcceptableOrUnknown(data['subreddit']!, _subredditMeta),
      );
    } else if (isInserting) {
      context.missing(_subredditMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('created_utc')) {
      context.handle(
        _createdUtcMeta,
        createdUtc.isAcceptableOrUnknown(data['created_utc']!, _createdUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_createdUtcMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body_markdown')) {
      context.handle(
        _bodyMarkdownMeta,
        bodyMarkdown.isAcceptableOrUnknown(
          data['body_markdown']!,
          _bodyMarkdownMeta,
        ),
      );
    }
    if (data.containsKey('over18')) {
      context.handle(
        _over18Meta,
        over18.isAcceptableOrUnknown(data['over18']!, _over18Meta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('last_resolved_at')) {
      context.handle(
        _lastResolvedAtMeta,
        lastResolvedAt.isAcceptableOrUnknown(
          data['last_resolved_at']!,
          _lastResolvedAtMeta,
        ),
      );
    }
    if (data.containsKey('resolution_status')) {
      context.handle(
        _resolutionStatusMeta,
        resolutionStatus.isAcceptableOrUnknown(
          data['resolution_status']!,
          _resolutionStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resolutionStatusMeta);
    }
    if (data.containsKey('raw_json_cache')) {
      context.handle(
        _rawJsonCacheMeta,
        rawJsonCache.isAcceptableOrUnknown(
          data['raw_json_cache']!,
          _rawJsonCacheMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      permalink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permalink'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      subreddit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subreddit'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      createdUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_utc'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      bodyMarkdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_markdown'],
      ),
      over18: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}over18'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      lastResolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_resolved_at'],
      ),
      resolutionStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution_status'],
      )!,
      rawJsonCache: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_json_cache'],
      ),
    );
  }

  @override
  $SavedItemsTable createAlias(String alias) {
    return $SavedItemsTable(attachedDatabase, alias);
  }
}

class SavedItem extends DataClass implements Insertable<SavedItem> {
  final int id;
  final String permalink;
  final String kind;
  final String subreddit;
  final String author;
  final int createdUtc;
  final String title;
  final String? bodyMarkdown;
  final bool over18;
  final String source;
  final DateTime? importedAt;
  final DateTime? syncedAt;
  final DateTime? lastResolvedAt;
  final String resolutionStatus;
  final String? rawJsonCache;
  const SavedItem({
    required this.id,
    required this.permalink,
    required this.kind,
    required this.subreddit,
    required this.author,
    required this.createdUtc,
    required this.title,
    this.bodyMarkdown,
    required this.over18,
    required this.source,
    this.importedAt,
    this.syncedAt,
    this.lastResolvedAt,
    required this.resolutionStatus,
    this.rawJsonCache,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['permalink'] = Variable<String>(permalink);
    map['kind'] = Variable<String>(kind);
    map['subreddit'] = Variable<String>(subreddit);
    map['author'] = Variable<String>(author);
    map['created_utc'] = Variable<int>(createdUtc);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || bodyMarkdown != null) {
      map['body_markdown'] = Variable<String>(bodyMarkdown);
    }
    map['over18'] = Variable<bool>(over18);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || importedAt != null) {
      map['imported_at'] = Variable<DateTime>(importedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || lastResolvedAt != null) {
      map['last_resolved_at'] = Variable<DateTime>(lastResolvedAt);
    }
    map['resolution_status'] = Variable<String>(resolutionStatus);
    if (!nullToAbsent || rawJsonCache != null) {
      map['raw_json_cache'] = Variable<String>(rawJsonCache);
    }
    return map;
  }

  SavedItemsCompanion toCompanion(bool nullToAbsent) {
    return SavedItemsCompanion(
      id: Value(id),
      permalink: Value(permalink),
      kind: Value(kind),
      subreddit: Value(subreddit),
      author: Value(author),
      createdUtc: Value(createdUtc),
      title: Value(title),
      bodyMarkdown: bodyMarkdown == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyMarkdown),
      over18: Value(over18),
      source: Value(source),
      importedAt: importedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(importedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      lastResolvedAt: lastResolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastResolvedAt),
      resolutionStatus: Value(resolutionStatus),
      rawJsonCache: rawJsonCache == null && nullToAbsent
          ? const Value.absent()
          : Value(rawJsonCache),
    );
  }

  factory SavedItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedItem(
      id: serializer.fromJson<int>(json['id']),
      permalink: serializer.fromJson<String>(json['permalink']),
      kind: serializer.fromJson<String>(json['kind']),
      subreddit: serializer.fromJson<String>(json['subreddit']),
      author: serializer.fromJson<String>(json['author']),
      createdUtc: serializer.fromJson<int>(json['createdUtc']),
      title: serializer.fromJson<String>(json['title']),
      bodyMarkdown: serializer.fromJson<String?>(json['bodyMarkdown']),
      over18: serializer.fromJson<bool>(json['over18']),
      source: serializer.fromJson<String>(json['source']),
      importedAt: serializer.fromJson<DateTime?>(json['importedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      lastResolvedAt: serializer.fromJson<DateTime?>(json['lastResolvedAt']),
      resolutionStatus: serializer.fromJson<String>(json['resolutionStatus']),
      rawJsonCache: serializer.fromJson<String?>(json['rawJsonCache']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'permalink': serializer.toJson<String>(permalink),
      'kind': serializer.toJson<String>(kind),
      'subreddit': serializer.toJson<String>(subreddit),
      'author': serializer.toJson<String>(author),
      'createdUtc': serializer.toJson<int>(createdUtc),
      'title': serializer.toJson<String>(title),
      'bodyMarkdown': serializer.toJson<String?>(bodyMarkdown),
      'over18': serializer.toJson<bool>(over18),
      'source': serializer.toJson<String>(source),
      'importedAt': serializer.toJson<DateTime?>(importedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'lastResolvedAt': serializer.toJson<DateTime?>(lastResolvedAt),
      'resolutionStatus': serializer.toJson<String>(resolutionStatus),
      'rawJsonCache': serializer.toJson<String?>(rawJsonCache),
    };
  }

  SavedItem copyWith({
    int? id,
    String? permalink,
    String? kind,
    String? subreddit,
    String? author,
    int? createdUtc,
    String? title,
    Value<String?> bodyMarkdown = const Value.absent(),
    bool? over18,
    String? source,
    Value<DateTime?> importedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> lastResolvedAt = const Value.absent(),
    String? resolutionStatus,
    Value<String?> rawJsonCache = const Value.absent(),
  }) => SavedItem(
    id: id ?? this.id,
    permalink: permalink ?? this.permalink,
    kind: kind ?? this.kind,
    subreddit: subreddit ?? this.subreddit,
    author: author ?? this.author,
    createdUtc: createdUtc ?? this.createdUtc,
    title: title ?? this.title,
    bodyMarkdown: bodyMarkdown.present ? bodyMarkdown.value : this.bodyMarkdown,
    over18: over18 ?? this.over18,
    source: source ?? this.source,
    importedAt: importedAt.present ? importedAt.value : this.importedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    lastResolvedAt: lastResolvedAt.present
        ? lastResolvedAt.value
        : this.lastResolvedAt,
    resolutionStatus: resolutionStatus ?? this.resolutionStatus,
    rawJsonCache: rawJsonCache.present ? rawJsonCache.value : this.rawJsonCache,
  );
  SavedItem copyWithCompanion(SavedItemsCompanion data) {
    return SavedItem(
      id: data.id.present ? data.id.value : this.id,
      permalink: data.permalink.present ? data.permalink.value : this.permalink,
      kind: data.kind.present ? data.kind.value : this.kind,
      subreddit: data.subreddit.present ? data.subreddit.value : this.subreddit,
      author: data.author.present ? data.author.value : this.author,
      createdUtc: data.createdUtc.present
          ? data.createdUtc.value
          : this.createdUtc,
      title: data.title.present ? data.title.value : this.title,
      bodyMarkdown: data.bodyMarkdown.present
          ? data.bodyMarkdown.value
          : this.bodyMarkdown,
      over18: data.over18.present ? data.over18.value : this.over18,
      source: data.source.present ? data.source.value : this.source,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      lastResolvedAt: data.lastResolvedAt.present
          ? data.lastResolvedAt.value
          : this.lastResolvedAt,
      resolutionStatus: data.resolutionStatus.present
          ? data.resolutionStatus.value
          : this.resolutionStatus,
      rawJsonCache: data.rawJsonCache.present
          ? data.rawJsonCache.value
          : this.rawJsonCache,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedItem(')
          ..write('id: $id, ')
          ..write('permalink: $permalink, ')
          ..write('kind: $kind, ')
          ..write('subreddit: $subreddit, ')
          ..write('author: $author, ')
          ..write('createdUtc: $createdUtc, ')
          ..write('title: $title, ')
          ..write('bodyMarkdown: $bodyMarkdown, ')
          ..write('over18: $over18, ')
          ..write('source: $source, ')
          ..write('importedAt: $importedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('lastResolvedAt: $lastResolvedAt, ')
          ..write('resolutionStatus: $resolutionStatus, ')
          ..write('rawJsonCache: $rawJsonCache')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    permalink,
    kind,
    subreddit,
    author,
    createdUtc,
    title,
    bodyMarkdown,
    over18,
    source,
    importedAt,
    syncedAt,
    lastResolvedAt,
    resolutionStatus,
    rawJsonCache,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedItem &&
          other.id == this.id &&
          other.permalink == this.permalink &&
          other.kind == this.kind &&
          other.subreddit == this.subreddit &&
          other.author == this.author &&
          other.createdUtc == this.createdUtc &&
          other.title == this.title &&
          other.bodyMarkdown == this.bodyMarkdown &&
          other.over18 == this.over18 &&
          other.source == this.source &&
          other.importedAt == this.importedAt &&
          other.syncedAt == this.syncedAt &&
          other.lastResolvedAt == this.lastResolvedAt &&
          other.resolutionStatus == this.resolutionStatus &&
          other.rawJsonCache == this.rawJsonCache);
}

class SavedItemsCompanion extends UpdateCompanion<SavedItem> {
  final Value<int> id;
  final Value<String> permalink;
  final Value<String> kind;
  final Value<String> subreddit;
  final Value<String> author;
  final Value<int> createdUtc;
  final Value<String> title;
  final Value<String?> bodyMarkdown;
  final Value<bool> over18;
  final Value<String> source;
  final Value<DateTime?> importedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> lastResolvedAt;
  final Value<String> resolutionStatus;
  final Value<String?> rawJsonCache;
  const SavedItemsCompanion({
    this.id = const Value.absent(),
    this.permalink = const Value.absent(),
    this.kind = const Value.absent(),
    this.subreddit = const Value.absent(),
    this.author = const Value.absent(),
    this.createdUtc = const Value.absent(),
    this.title = const Value.absent(),
    this.bodyMarkdown = const Value.absent(),
    this.over18 = const Value.absent(),
    this.source = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.lastResolvedAt = const Value.absent(),
    this.resolutionStatus = const Value.absent(),
    this.rawJsonCache = const Value.absent(),
  });
  SavedItemsCompanion.insert({
    this.id = const Value.absent(),
    required String permalink,
    required String kind,
    required String subreddit,
    required String author,
    required int createdUtc,
    required String title,
    this.bodyMarkdown = const Value.absent(),
    this.over18 = const Value.absent(),
    required String source,
    this.importedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.lastResolvedAt = const Value.absent(),
    required String resolutionStatus,
    this.rawJsonCache = const Value.absent(),
  }) : permalink = Value(permalink),
       kind = Value(kind),
       subreddit = Value(subreddit),
       author = Value(author),
       createdUtc = Value(createdUtc),
       title = Value(title),
       source = Value(source),
       resolutionStatus = Value(resolutionStatus);
  static Insertable<SavedItem> custom({
    Expression<int>? id,
    Expression<String>? permalink,
    Expression<String>? kind,
    Expression<String>? subreddit,
    Expression<String>? author,
    Expression<int>? createdUtc,
    Expression<String>? title,
    Expression<String>? bodyMarkdown,
    Expression<bool>? over18,
    Expression<String>? source,
    Expression<DateTime>? importedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? lastResolvedAt,
    Expression<String>? resolutionStatus,
    Expression<String>? rawJsonCache,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (permalink != null) 'permalink': permalink,
      if (kind != null) 'kind': kind,
      if (subreddit != null) 'subreddit': subreddit,
      if (author != null) 'author': author,
      if (createdUtc != null) 'created_utc': createdUtc,
      if (title != null) 'title': title,
      if (bodyMarkdown != null) 'body_markdown': bodyMarkdown,
      if (over18 != null) 'over18': over18,
      if (source != null) 'source': source,
      if (importedAt != null) 'imported_at': importedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (lastResolvedAt != null) 'last_resolved_at': lastResolvedAt,
      if (resolutionStatus != null) 'resolution_status': resolutionStatus,
      if (rawJsonCache != null) 'raw_json_cache': rawJsonCache,
    });
  }

  SavedItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? permalink,
    Value<String>? kind,
    Value<String>? subreddit,
    Value<String>? author,
    Value<int>? createdUtc,
    Value<String>? title,
    Value<String?>? bodyMarkdown,
    Value<bool>? over18,
    Value<String>? source,
    Value<DateTime?>? importedAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? lastResolvedAt,
    Value<String>? resolutionStatus,
    Value<String?>? rawJsonCache,
  }) {
    return SavedItemsCompanion(
      id: id ?? this.id,
      permalink: permalink ?? this.permalink,
      kind: kind ?? this.kind,
      subreddit: subreddit ?? this.subreddit,
      author: author ?? this.author,
      createdUtc: createdUtc ?? this.createdUtc,
      title: title ?? this.title,
      bodyMarkdown: bodyMarkdown ?? this.bodyMarkdown,
      over18: over18 ?? this.over18,
      source: source ?? this.source,
      importedAt: importedAt ?? this.importedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      lastResolvedAt: lastResolvedAt ?? this.lastResolvedAt,
      resolutionStatus: resolutionStatus ?? this.resolutionStatus,
      rawJsonCache: rawJsonCache ?? this.rawJsonCache,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (permalink.present) {
      map['permalink'] = Variable<String>(permalink.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (subreddit.present) {
      map['subreddit'] = Variable<String>(subreddit.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (createdUtc.present) {
      map['created_utc'] = Variable<int>(createdUtc.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (bodyMarkdown.present) {
      map['body_markdown'] = Variable<String>(bodyMarkdown.value);
    }
    if (over18.present) {
      map['over18'] = Variable<bool>(over18.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (lastResolvedAt.present) {
      map['last_resolved_at'] = Variable<DateTime>(lastResolvedAt.value);
    }
    if (resolutionStatus.present) {
      map['resolution_status'] = Variable<String>(resolutionStatus.value);
    }
    if (rawJsonCache.present) {
      map['raw_json_cache'] = Variable<String>(rawJsonCache.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedItemsCompanion(')
          ..write('id: $id, ')
          ..write('permalink: $permalink, ')
          ..write('kind: $kind, ')
          ..write('subreddit: $subreddit, ')
          ..write('author: $author, ')
          ..write('createdUtc: $createdUtc, ')
          ..write('title: $title, ')
          ..write('bodyMarkdown: $bodyMarkdown, ')
          ..write('over18: $over18, ')
          ..write('source: $source, ')
          ..write('importedAt: $importedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('lastResolvedAt: $lastResolvedAt, ')
          ..write('resolutionStatus: $resolutionStatus, ')
          ..write('rawJsonCache: $rawJsonCache')
          ..write(')'))
        .toString();
  }
}

class $MediaAssetsTable extends MediaAssets
    with TableInfo<$MediaAssetsTable, MediaAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaAssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _savedItemIdMeta = const VerificationMeta(
    'savedItemId',
  );
  @override
  late final GeneratedColumn<int> savedItemId = GeneratedColumn<int>(
    'saved_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES saved_items (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedUrlMeta = const VerificationMeta(
    'normalizedUrl',
  );
  @override
  late final GeneratedColumn<String> normalizedUrl = GeneratedColumn<String>(
    'normalized_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toolHintMeta = const VerificationMeta(
    'toolHint',
  );
  @override
  late final GeneratedColumn<String> toolHint = GeneratedColumn<String>(
    'tool_hint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filenameSuggestedMeta = const VerificationMeta(
    'filenameSuggested',
  );
  @override
  late final GeneratedColumn<String> filenameSuggested =
      GeneratedColumn<String>(
        'filename_suggested',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    savedItemId,
    type,
    sourceUrl,
    normalizedUrl,
    toolHint,
    filenameSuggested,
    metadataJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaAsset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('saved_item_id')) {
      context.handle(
        _savedItemIdMeta,
        savedItemId.isAcceptableOrUnknown(
          data['saved_item_id']!,
          _savedItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_savedItemIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('normalized_url')) {
      context.handle(
        _normalizedUrlMeta,
        normalizedUrl.isAcceptableOrUnknown(
          data['normalized_url']!,
          _normalizedUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedUrlMeta);
    }
    if (data.containsKey('tool_hint')) {
      context.handle(
        _toolHintMeta,
        toolHint.isAcceptableOrUnknown(data['tool_hint']!, _toolHintMeta),
      );
    } else if (isInserting) {
      context.missing(_toolHintMeta);
    }
    if (data.containsKey('filename_suggested')) {
      context.handle(
        _filenameSuggestedMeta,
        filenameSuggested.isAcceptableOrUnknown(
          data['filename_suggested']!,
          _filenameSuggestedMeta,
        ),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaAsset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      savedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_item_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      normalizedUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_url'],
      )!,
      toolHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tool_hint'],
      )!,
      filenameSuggested: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename_suggested'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
    );
  }

  @override
  $MediaAssetsTable createAlias(String alias) {
    return $MediaAssetsTable(attachedDatabase, alias);
  }
}

class MediaAsset extends DataClass implements Insertable<MediaAsset> {
  final int id;
  final int savedItemId;
  final String type;
  final String sourceUrl;
  final String normalizedUrl;
  final String toolHint;
  final String? filenameSuggested;
  final String? metadataJson;
  const MediaAsset({
    required this.id,
    required this.savedItemId,
    required this.type,
    required this.sourceUrl,
    required this.normalizedUrl,
    required this.toolHint,
    this.filenameSuggested,
    this.metadataJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['saved_item_id'] = Variable<int>(savedItemId);
    map['type'] = Variable<String>(type);
    map['source_url'] = Variable<String>(sourceUrl);
    map['normalized_url'] = Variable<String>(normalizedUrl);
    map['tool_hint'] = Variable<String>(toolHint);
    if (!nullToAbsent || filenameSuggested != null) {
      map['filename_suggested'] = Variable<String>(filenameSuggested);
    }
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    return map;
  }

  MediaAssetsCompanion toCompanion(bool nullToAbsent) {
    return MediaAssetsCompanion(
      id: Value(id),
      savedItemId: Value(savedItemId),
      type: Value(type),
      sourceUrl: Value(sourceUrl),
      normalizedUrl: Value(normalizedUrl),
      toolHint: Value(toolHint),
      filenameSuggested: filenameSuggested == null && nullToAbsent
          ? const Value.absent()
          : Value(filenameSuggested),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
    );
  }

  factory MediaAsset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaAsset(
      id: serializer.fromJson<int>(json['id']),
      savedItemId: serializer.fromJson<int>(json['savedItemId']),
      type: serializer.fromJson<String>(json['type']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      normalizedUrl: serializer.fromJson<String>(json['normalizedUrl']),
      toolHint: serializer.fromJson<String>(json['toolHint']),
      filenameSuggested: serializer.fromJson<String?>(
        json['filenameSuggested'],
      ),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'savedItemId': serializer.toJson<int>(savedItemId),
      'type': serializer.toJson<String>(type),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'normalizedUrl': serializer.toJson<String>(normalizedUrl),
      'toolHint': serializer.toJson<String>(toolHint),
      'filenameSuggested': serializer.toJson<String?>(filenameSuggested),
      'metadataJson': serializer.toJson<String?>(metadataJson),
    };
  }

  MediaAsset copyWith({
    int? id,
    int? savedItemId,
    String? type,
    String? sourceUrl,
    String? normalizedUrl,
    String? toolHint,
    Value<String?> filenameSuggested = const Value.absent(),
    Value<String?> metadataJson = const Value.absent(),
  }) => MediaAsset(
    id: id ?? this.id,
    savedItemId: savedItemId ?? this.savedItemId,
    type: type ?? this.type,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    normalizedUrl: normalizedUrl ?? this.normalizedUrl,
    toolHint: toolHint ?? this.toolHint,
    filenameSuggested: filenameSuggested.present
        ? filenameSuggested.value
        : this.filenameSuggested,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
  );
  MediaAsset copyWithCompanion(MediaAssetsCompanion data) {
    return MediaAsset(
      id: data.id.present ? data.id.value : this.id,
      savedItemId: data.savedItemId.present
          ? data.savedItemId.value
          : this.savedItemId,
      type: data.type.present ? data.type.value : this.type,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      normalizedUrl: data.normalizedUrl.present
          ? data.normalizedUrl.value
          : this.normalizedUrl,
      toolHint: data.toolHint.present ? data.toolHint.value : this.toolHint,
      filenameSuggested: data.filenameSuggested.present
          ? data.filenameSuggested.value
          : this.filenameSuggested,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaAsset(')
          ..write('id: $id, ')
          ..write('savedItemId: $savedItemId, ')
          ..write('type: $type, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('normalizedUrl: $normalizedUrl, ')
          ..write('toolHint: $toolHint, ')
          ..write('filenameSuggested: $filenameSuggested, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    savedItemId,
    type,
    sourceUrl,
    normalizedUrl,
    toolHint,
    filenameSuggested,
    metadataJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaAsset &&
          other.id == this.id &&
          other.savedItemId == this.savedItemId &&
          other.type == this.type &&
          other.sourceUrl == this.sourceUrl &&
          other.normalizedUrl == this.normalizedUrl &&
          other.toolHint == this.toolHint &&
          other.filenameSuggested == this.filenameSuggested &&
          other.metadataJson == this.metadataJson);
}

class MediaAssetsCompanion extends UpdateCompanion<MediaAsset> {
  final Value<int> id;
  final Value<int> savedItemId;
  final Value<String> type;
  final Value<String> sourceUrl;
  final Value<String> normalizedUrl;
  final Value<String> toolHint;
  final Value<String?> filenameSuggested;
  final Value<String?> metadataJson;
  const MediaAssetsCompanion({
    this.id = const Value.absent(),
    this.savedItemId = const Value.absent(),
    this.type = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.normalizedUrl = const Value.absent(),
    this.toolHint = const Value.absent(),
    this.filenameSuggested = const Value.absent(),
    this.metadataJson = const Value.absent(),
  });
  MediaAssetsCompanion.insert({
    this.id = const Value.absent(),
    required int savedItemId,
    required String type,
    required String sourceUrl,
    required String normalizedUrl,
    required String toolHint,
    this.filenameSuggested = const Value.absent(),
    this.metadataJson = const Value.absent(),
  }) : savedItemId = Value(savedItemId),
       type = Value(type),
       sourceUrl = Value(sourceUrl),
       normalizedUrl = Value(normalizedUrl),
       toolHint = Value(toolHint);
  static Insertable<MediaAsset> custom({
    Expression<int>? id,
    Expression<int>? savedItemId,
    Expression<String>? type,
    Expression<String>? sourceUrl,
    Expression<String>? normalizedUrl,
    Expression<String>? toolHint,
    Expression<String>? filenameSuggested,
    Expression<String>? metadataJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (savedItemId != null) 'saved_item_id': savedItemId,
      if (type != null) 'type': type,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (normalizedUrl != null) 'normalized_url': normalizedUrl,
      if (toolHint != null) 'tool_hint': toolHint,
      if (filenameSuggested != null) 'filename_suggested': filenameSuggested,
      if (metadataJson != null) 'metadata_json': metadataJson,
    });
  }

  MediaAssetsCompanion copyWith({
    Value<int>? id,
    Value<int>? savedItemId,
    Value<String>? type,
    Value<String>? sourceUrl,
    Value<String>? normalizedUrl,
    Value<String>? toolHint,
    Value<String?>? filenameSuggested,
    Value<String?>? metadataJson,
  }) {
    return MediaAssetsCompanion(
      id: id ?? this.id,
      savedItemId: savedItemId ?? this.savedItemId,
      type: type ?? this.type,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      normalizedUrl: normalizedUrl ?? this.normalizedUrl,
      toolHint: toolHint ?? this.toolHint,
      filenameSuggested: filenameSuggested ?? this.filenameSuggested,
      metadataJson: metadataJson ?? this.metadataJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (savedItemId.present) {
      map['saved_item_id'] = Variable<int>(savedItemId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (normalizedUrl.present) {
      map['normalized_url'] = Variable<String>(normalizedUrl.value);
    }
    if (toolHint.present) {
      map['tool_hint'] = Variable<String>(toolHint.value);
    }
    if (filenameSuggested.present) {
      map['filename_suggested'] = Variable<String>(filenameSuggested.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaAssetsCompanion(')
          ..write('id: $id, ')
          ..write('savedItemId: $savedItemId, ')
          ..write('type: $type, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('normalizedUrl: $normalizedUrl, ')
          ..write('toolHint: $toolHint, ')
          ..write('filenameSuggested: $filenameSuggested, ')
          ..write('metadataJson: $metadataJson')
          ..write(')'))
        .toString();
  }
}

class $DownloadJobsTable extends DownloadJobs
    with TableInfo<$DownloadJobsTable, DownloadJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _savedItemIdMeta = const VerificationMeta(
    'savedItemId',
  );
  @override
  late final GeneratedColumn<int> savedItemId = GeneratedColumn<int>(
    'saved_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES saved_items (id)',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _policySnapshotMeta = const VerificationMeta(
    'policySnapshot',
  );
  @override
  late final GeneratedColumn<String> policySnapshot = GeneratedColumn<String>(
    'policy_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputPathMeta = const VerificationMeta(
    'outputPath',
  );
  @override
  late final GeneratedColumn<String> outputPath = GeneratedColumn<String>(
    'output_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    savedItemId,
    status,
    progress,
    attempts,
    lastError,
    policySnapshot,
    outputPath,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('saved_item_id')) {
      context.handle(
        _savedItemIdMeta,
        savedItemId.isAcceptableOrUnknown(
          data['saved_item_id']!,
          _savedItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_savedItemIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('policy_snapshot')) {
      context.handle(
        _policySnapshotMeta,
        policySnapshot.isAcceptableOrUnknown(
          data['policy_snapshot']!,
          _policySnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_policySnapshotMeta);
    }
    if (data.containsKey('output_path')) {
      context.handle(
        _outputPathMeta,
        outputPath.isAcceptableOrUnknown(data['output_path']!, _outputPathMeta),
      );
    } else if (isInserting) {
      context.missing(_outputPathMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      savedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_item_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      policySnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}policy_snapshot'],
      )!,
      outputPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_path'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $DownloadJobsTable createAlias(String alias) {
    return $DownloadJobsTable(attachedDatabase, alias);
  }
}

class DownloadJob extends DataClass implements Insertable<DownloadJob> {
  final int id;
  final int savedItemId;
  final String status;
  final double progress;
  final int attempts;
  final String? lastError;
  final String policySnapshot;
  final String outputPath;
  final DateTime? startedAt;
  final DateTime? completedAt;
  const DownloadJob({
    required this.id,
    required this.savedItemId,
    required this.status,
    required this.progress,
    required this.attempts,
    this.lastError,
    required this.policySnapshot,
    required this.outputPath,
    this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['saved_item_id'] = Variable<int>(savedItemId);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<double>(progress);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['policy_snapshot'] = Variable<String>(policySnapshot);
    map['output_path'] = Variable<String>(outputPath);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  DownloadJobsCompanion toCompanion(bool nullToAbsent) {
    return DownloadJobsCompanion(
      id: Value(id),
      savedItemId: Value(savedItemId),
      status: Value(status),
      progress: Value(progress),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      policySnapshot: Value(policySnapshot),
      outputPath: Value(outputPath),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory DownloadJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadJob(
      id: serializer.fromJson<int>(json['id']),
      savedItemId: serializer.fromJson<int>(json['savedItemId']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<double>(json['progress']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      policySnapshot: serializer.fromJson<String>(json['policySnapshot']),
      outputPath: serializer.fromJson<String>(json['outputPath']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'savedItemId': serializer.toJson<int>(savedItemId),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<double>(progress),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'policySnapshot': serializer.toJson<String>(policySnapshot),
      'outputPath': serializer.toJson<String>(outputPath),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  DownloadJob copyWith({
    int? id,
    int? savedItemId,
    String? status,
    double? progress,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    String? policySnapshot,
    String? outputPath,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
  }) => DownloadJob(
    id: id ?? this.id,
    savedItemId: savedItemId ?? this.savedItemId,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    policySnapshot: policySnapshot ?? this.policySnapshot,
    outputPath: outputPath ?? this.outputPath,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  DownloadJob copyWithCompanion(DownloadJobsCompanion data) {
    return DownloadJob(
      id: data.id.present ? data.id.value : this.id,
      savedItemId: data.savedItemId.present
          ? data.savedItemId.value
          : this.savedItemId,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      policySnapshot: data.policySnapshot.present
          ? data.policySnapshot.value
          : this.policySnapshot,
      outputPath: data.outputPath.present
          ? data.outputPath.value
          : this.outputPath,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJob(')
          ..write('id: $id, ')
          ..write('savedItemId: $savedItemId, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('policySnapshot: $policySnapshot, ')
          ..write('outputPath: $outputPath, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    savedItemId,
    status,
    progress,
    attempts,
    lastError,
    policySnapshot,
    outputPath,
    startedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadJob &&
          other.id == this.id &&
          other.savedItemId == this.savedItemId &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.policySnapshot == this.policySnapshot &&
          other.outputPath == this.outputPath &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class DownloadJobsCompanion extends UpdateCompanion<DownloadJob> {
  final Value<int> id;
  final Value<int> savedItemId;
  final Value<String> status;
  final Value<double> progress;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<String> policySnapshot;
  final Value<String> outputPath;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  const DownloadJobsCompanion({
    this.id = const Value.absent(),
    this.savedItemId = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.policySnapshot = const Value.absent(),
    this.outputPath = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  DownloadJobsCompanion.insert({
    this.id = const Value.absent(),
    required int savedItemId,
    required String status,
    this.progress = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required String policySnapshot,
    required String outputPath,
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  }) : savedItemId = Value(savedItemId),
       status = Value(status),
       policySnapshot = Value(policySnapshot),
       outputPath = Value(outputPath);
  static Insertable<DownloadJob> custom({
    Expression<int>? id,
    Expression<int>? savedItemId,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<String>? policySnapshot,
    Expression<String>? outputPath,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (savedItemId != null) 'saved_item_id': savedItemId,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (policySnapshot != null) 'policy_snapshot': policySnapshot,
      if (outputPath != null) 'output_path': outputPath,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  DownloadJobsCompanion copyWith({
    Value<int>? id,
    Value<int>? savedItemId,
    Value<String>? status,
    Value<double>? progress,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<String>? policySnapshot,
    Value<String>? outputPath,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? completedAt,
  }) {
    return DownloadJobsCompanion(
      id: id ?? this.id,
      savedItemId: savedItemId ?? this.savedItemId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      policySnapshot: policySnapshot ?? this.policySnapshot,
      outputPath: outputPath ?? this.outputPath,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (savedItemId.present) {
      map['saved_item_id'] = Variable<int>(savedItemId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (policySnapshot.present) {
      map['policy_snapshot'] = Variable<String>(policySnapshot.value);
    }
    if (outputPath.present) {
      map['output_path'] = Variable<String>(outputPath.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadJobsCompanion(')
          ..write('id: $id, ')
          ..write('savedItemId: $savedItemId, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('policySnapshot: $policySnapshot, ')
          ..write('outputPath: $outputPath, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $DownloadOutputsTable extends DownloadOutputs
    with TableInfo<$DownloadOutputsTable, DownloadOutput> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadOutputsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<int> jobId = GeneratedColumn<int>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES download_jobs (id)',
    ),
  );
  static const VerificationMeta _savedItemIdMeta = const VerificationMeta(
    'savedItemId',
  );
  @override
  late final GeneratedColumn<int> savedItemId = GeneratedColumn<int>(
    'saved_item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES saved_items (id)',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jobId,
    savedItemId,
    path,
    kind,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_outputs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadOutput> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('saved_item_id')) {
      context.handle(
        _savedItemIdMeta,
        savedItemId.isAcceptableOrUnknown(
          data['saved_item_id']!,
          _savedItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_savedItemIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadOutput map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadOutput(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}job_id'],
      )!,
      savedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_item_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DownloadOutputsTable createAlias(String alias) {
    return $DownloadOutputsTable(attachedDatabase, alias);
  }
}

class DownloadOutput extends DataClass implements Insertable<DownloadOutput> {
  final int id;
  final int jobId;
  final int savedItemId;
  final String path;
  final String kind;
  final DateTime createdAt;
  const DownloadOutput({
    required this.id,
    required this.jobId,
    required this.savedItemId,
    required this.path,
    required this.kind,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['job_id'] = Variable<int>(jobId);
    map['saved_item_id'] = Variable<int>(savedItemId);
    map['path'] = Variable<String>(path);
    map['kind'] = Variable<String>(kind);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DownloadOutputsCompanion toCompanion(bool nullToAbsent) {
    return DownloadOutputsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      savedItemId: Value(savedItemId),
      path: Value(path),
      kind: Value(kind),
      createdAt: Value(createdAt),
    );
  }

  factory DownloadOutput.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadOutput(
      id: serializer.fromJson<int>(json['id']),
      jobId: serializer.fromJson<int>(json['jobId']),
      savedItemId: serializer.fromJson<int>(json['savedItemId']),
      path: serializer.fromJson<String>(json['path']),
      kind: serializer.fromJson<String>(json['kind']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jobId': serializer.toJson<int>(jobId),
      'savedItemId': serializer.toJson<int>(savedItemId),
      'path': serializer.toJson<String>(path),
      'kind': serializer.toJson<String>(kind),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DownloadOutput copyWith({
    int? id,
    int? jobId,
    int? savedItemId,
    String? path,
    String? kind,
    DateTime? createdAt,
  }) => DownloadOutput(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    savedItemId: savedItemId ?? this.savedItemId,
    path: path ?? this.path,
    kind: kind ?? this.kind,
    createdAt: createdAt ?? this.createdAt,
  );
  DownloadOutput copyWithCompanion(DownloadOutputsCompanion data) {
    return DownloadOutput(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      savedItemId: data.savedItemId.present
          ? data.savedItemId.value
          : this.savedItemId,
      path: data.path.present ? data.path.value : this.path,
      kind: data.kind.present ? data.kind.value : this.kind,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadOutput(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('savedItemId: $savedItemId, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, jobId, savedItemId, path, kind, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadOutput &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.savedItemId == this.savedItemId &&
          other.path == this.path &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt);
}

class DownloadOutputsCompanion extends UpdateCompanion<DownloadOutput> {
  final Value<int> id;
  final Value<int> jobId;
  final Value<int> savedItemId;
  final Value<String> path;
  final Value<String> kind;
  final Value<DateTime> createdAt;
  const DownloadOutputsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.savedItemId = const Value.absent(),
    this.path = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DownloadOutputsCompanion.insert({
    this.id = const Value.absent(),
    required int jobId,
    required int savedItemId,
    required String path,
    required String kind,
    this.createdAt = const Value.absent(),
  }) : jobId = Value(jobId),
       savedItemId = Value(savedItemId),
       path = Value(path),
       kind = Value(kind);
  static Insertable<DownloadOutput> custom({
    Expression<int>? id,
    Expression<int>? jobId,
    Expression<int>? savedItemId,
    Expression<String>? path,
    Expression<String>? kind,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (savedItemId != null) 'saved_item_id': savedItemId,
      if (path != null) 'path': path,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DownloadOutputsCompanion copyWith({
    Value<int>? id,
    Value<int>? jobId,
    Value<int>? savedItemId,
    Value<String>? path,
    Value<String>? kind,
    Value<DateTime>? createdAt,
  }) {
    return DownloadOutputsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      savedItemId: savedItemId ?? this.savedItemId,
      path: path ?? this.path,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<int>(jobId.value);
    }
    if (savedItemId.present) {
      map['saved_item_id'] = Variable<int>(savedItemId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadOutputsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('savedItemId: $savedItemId, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LogEntriesTable extends LogEntries
    with TableInfo<$LogEntriesTable, LogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextJsonMeta = const VerificationMeta(
    'contextJson',
  );
  @override
  late final GeneratedColumn<String> contextJson = GeneratedColumn<String>(
    'context_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relatedJobIdMeta = const VerificationMeta(
    'relatedJobId',
  );
  @override
  late final GeneratedColumn<int> relatedJobId = GeneratedColumn<int>(
    'related_job_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    scope,
    level,
    message,
    contextJson,
    relatedJobId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('context_json')) {
      context.handle(
        _contextJsonMeta,
        contextJson.isAcceptableOrUnknown(
          data['context_json']!,
          _contextJsonMeta,
        ),
      );
    }
    if (data.containsKey('related_job_id')) {
      context.handle(
        _relatedJobIdMeta,
        relatedJobId.isAcceptableOrUnknown(
          data['related_job_id']!,
          _relatedJobIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      contextJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_json'],
      ),
      relatedJobId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}related_job_id'],
      ),
    );
  }

  @override
  $LogEntriesTable createAlias(String alias) {
    return $LogEntriesTable(attachedDatabase, alias);
  }
}

class LogEntry extends DataClass implements Insertable<LogEntry> {
  final int id;
  final DateTime timestamp;
  final String scope;
  final String level;
  final String message;
  final String? contextJson;
  final int? relatedJobId;
  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.scope,
    required this.level,
    required this.message,
    this.contextJson,
    this.relatedJobId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['scope'] = Variable<String>(scope);
    map['level'] = Variable<String>(level);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || contextJson != null) {
      map['context_json'] = Variable<String>(contextJson);
    }
    if (!nullToAbsent || relatedJobId != null) {
      map['related_job_id'] = Variable<int>(relatedJobId);
    }
    return map;
  }

  LogEntriesCompanion toCompanion(bool nullToAbsent) {
    return LogEntriesCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      scope: Value(scope),
      level: Value(level),
      message: Value(message),
      contextJson: contextJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contextJson),
      relatedJobId: relatedJobId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedJobId),
    );
  }

  factory LogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogEntry(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      scope: serializer.fromJson<String>(json['scope']),
      level: serializer.fromJson<String>(json['level']),
      message: serializer.fromJson<String>(json['message']),
      contextJson: serializer.fromJson<String?>(json['contextJson']),
      relatedJobId: serializer.fromJson<int?>(json['relatedJobId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'scope': serializer.toJson<String>(scope),
      'level': serializer.toJson<String>(level),
      'message': serializer.toJson<String>(message),
      'contextJson': serializer.toJson<String?>(contextJson),
      'relatedJobId': serializer.toJson<int?>(relatedJobId),
    };
  }

  LogEntry copyWith({
    int? id,
    DateTime? timestamp,
    String? scope,
    String? level,
    String? message,
    Value<String?> contextJson = const Value.absent(),
    Value<int?> relatedJobId = const Value.absent(),
  }) => LogEntry(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    scope: scope ?? this.scope,
    level: level ?? this.level,
    message: message ?? this.message,
    contextJson: contextJson.present ? contextJson.value : this.contextJson,
    relatedJobId: relatedJobId.present ? relatedJobId.value : this.relatedJobId,
  );
  LogEntry copyWithCompanion(LogEntriesCompanion data) {
    return LogEntry(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      scope: data.scope.present ? data.scope.value : this.scope,
      level: data.level.present ? data.level.value : this.level,
      message: data.message.present ? data.message.value : this.message,
      contextJson: data.contextJson.present
          ? data.contextJson.value
          : this.contextJson,
      relatedJobId: data.relatedJobId.present
          ? data.relatedJobId.value
          : this.relatedJobId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogEntry(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('scope: $scope, ')
          ..write('level: $level, ')
          ..write('message: $message, ')
          ..write('contextJson: $contextJson, ')
          ..write('relatedJobId: $relatedJobId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    scope,
    level,
    message,
    contextJson,
    relatedJobId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogEntry &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.scope == this.scope &&
          other.level == this.level &&
          other.message == this.message &&
          other.contextJson == this.contextJson &&
          other.relatedJobId == this.relatedJobId);
}

class LogEntriesCompanion extends UpdateCompanion<LogEntry> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<String> scope;
  final Value<String> level;
  final Value<String> message;
  final Value<String?> contextJson;
  final Value<int?> relatedJobId;
  const LogEntriesCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.scope = const Value.absent(),
    this.level = const Value.absent(),
    this.message = const Value.absent(),
    this.contextJson = const Value.absent(),
    this.relatedJobId = const Value.absent(),
  });
  LogEntriesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    required String scope,
    required String level,
    required String message,
    this.contextJson = const Value.absent(),
    this.relatedJobId = const Value.absent(),
  }) : timestamp = Value(timestamp),
       scope = Value(scope),
       level = Value(level),
       message = Value(message);
  static Insertable<LogEntry> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? scope,
    Expression<String>? level,
    Expression<String>? message,
    Expression<String>? contextJson,
    Expression<int>? relatedJobId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (scope != null) 'scope': scope,
      if (level != null) 'level': level,
      if (message != null) 'message': message,
      if (contextJson != null) 'context_json': contextJson,
      if (relatedJobId != null) 'related_job_id': relatedJobId,
    });
  }

  LogEntriesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<String>? scope,
    Value<String>? level,
    Value<String>? message,
    Value<String?>? contextJson,
    Value<int?>? relatedJobId,
  }) {
    return LogEntriesCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      scope: scope ?? this.scope,
      level: level ?? this.level,
      message: message ?? this.message,
      contextJson: contextJson ?? this.contextJson,
      relatedJobId: relatedJobId ?? this.relatedJobId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (contextJson.present) {
      map['context_json'] = Variable<String>(contextJson.value);
    }
    if (relatedJobId.present) {
      map['related_job_id'] = Variable<int>(relatedJobId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('scope: $scope, ')
          ..write('level: $level, ')
          ..write('message: $message, ')
          ..write('contextJson: $contextJson, ')
          ..write('relatedJobId: $relatedJobId')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, dataJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final String dataJson;
  final DateTime updatedAt;
  const Setting({
    required this.id,
    required this.dataJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['data_json'] = Variable<String>(dataJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      dataJson: Value(dataJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dataJson': serializer.toJson<String>(dataJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Setting copyWith({int? id, String? dataJson, DateTime? updatedAt}) => Setting(
    id: id ?? this.id,
    dataJson: dataJson ?? this.dataJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('dataJson: $dataJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dataJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.dataJson == this.dataJson &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<String> dataJson;
  final Value<DateTime> updatedAt;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    required String dataJson,
    required DateTime updatedAt,
  }) : dataJson = Value(dataJson),
       updatedAt = Value(updatedAt);
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? dataJson,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dataJson != null) 'data_json': dataJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? dataJson,
    Value<DateTime>? updatedAt,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      dataJson: dataJson ?? this.dataJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('dataJson: $dataJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SavedItemsTable savedItems = $SavedItemsTable(this);
  late final $MediaAssetsTable mediaAssets = $MediaAssetsTable(this);
  late final $DownloadJobsTable downloadJobs = $DownloadJobsTable(this);
  late final $DownloadOutputsTable downloadOutputs = $DownloadOutputsTable(
    this,
  );
  late final $LogEntriesTable logEntries = $LogEntriesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index savedItemsPermalink = Index(
    'saved_items_permalink',
    'CREATE UNIQUE INDEX saved_items_permalink ON saved_items (permalink)',
  );
  late final Index savedItemsSubreddit = Index(
    'saved_items_subreddit',
    'CREATE INDEX saved_items_subreddit ON saved_items (subreddit)',
  );
  late final Index savedItemsOver18 = Index(
    'saved_items_over18',
    'CREATE INDEX saved_items_over18 ON saved_items (over18)',
  );
  late final Index downloadJobsStatus = Index(
    'download_jobs_status',
    'CREATE INDEX download_jobs_status ON download_jobs (status)',
  );
  late final Index downloadOutputsJobId = Index(
    'download_outputs_job_id',
    'CREATE INDEX download_outputs_job_id ON download_outputs (job_id)',
  );
  late final Index downloadOutputsSavedItemId = Index(
    'download_outputs_saved_item_id',
    'CREATE INDEX download_outputs_saved_item_id ON download_outputs (saved_item_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    savedItems,
    mediaAssets,
    downloadJobs,
    downloadOutputs,
    logEntries,
    settings,
    savedItemsPermalink,
    savedItemsSubreddit,
    savedItemsOver18,
    downloadJobsStatus,
    downloadOutputsJobId,
    downloadOutputsSavedItemId,
  ];
}

typedef $$SavedItemsTableCreateCompanionBuilder =
    SavedItemsCompanion Function({
      Value<int> id,
      required String permalink,
      required String kind,
      required String subreddit,
      required String author,
      required int createdUtc,
      required String title,
      Value<String?> bodyMarkdown,
      Value<bool> over18,
      required String source,
      Value<DateTime?> importedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> lastResolvedAt,
      required String resolutionStatus,
      Value<String?> rawJsonCache,
    });
typedef $$SavedItemsTableUpdateCompanionBuilder =
    SavedItemsCompanion Function({
      Value<int> id,
      Value<String> permalink,
      Value<String> kind,
      Value<String> subreddit,
      Value<String> author,
      Value<int> createdUtc,
      Value<String> title,
      Value<String?> bodyMarkdown,
      Value<bool> over18,
      Value<String> source,
      Value<DateTime?> importedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> lastResolvedAt,
      Value<String> resolutionStatus,
      Value<String?> rawJsonCache,
    });

final class $$SavedItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SavedItemsTable, SavedItem> {
  $$SavedItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MediaAssetsTable, List<MediaAsset>>
  _mediaAssetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaAssets,
    aliasName: $_aliasNameGenerator(
      db.savedItems.id,
      db.mediaAssets.savedItemId,
    ),
  );

  $$MediaAssetsTableProcessedTableManager get mediaAssetsRefs {
    final manager = $$MediaAssetsTableTableManager(
      $_db,
      $_db.mediaAssets,
    ).filter((f) => f.savedItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaAssetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DownloadJobsTable, List<DownloadJob>>
  _downloadJobsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.downloadJobs,
    aliasName: $_aliasNameGenerator(
      db.savedItems.id,
      db.downloadJobs.savedItemId,
    ),
  );

  $$DownloadJobsTableProcessedTableManager get downloadJobsRefs {
    final manager = $$DownloadJobsTableTableManager(
      $_db,
      $_db.downloadJobs,
    ).filter((f) => f.savedItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_downloadJobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DownloadOutputsTable, List<DownloadOutput>>
  _downloadOutputsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.downloadOutputs,
    aliasName: $_aliasNameGenerator(
      db.savedItems.id,
      db.downloadOutputs.savedItemId,
    ),
  );

  $$DownloadOutputsTableProcessedTableManager get downloadOutputsRefs {
    final manager = $$DownloadOutputsTableTableManager(
      $_db,
      $_db.downloadOutputs,
    ).filter((f) => f.savedItemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _downloadOutputsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SavedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedItemsTable> {
  $$SavedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permalink => $composableBuilder(
    column: $table.permalink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subreddit => $composableBuilder(
    column: $table.subreddit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdUtc => $composableBuilder(
    column: $table.createdUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyMarkdown => $composableBuilder(
    column: $table.bodyMarkdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get over18 => $composableBuilder(
    column: $table.over18,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastResolvedAt => $composableBuilder(
    column: $table.lastResolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolutionStatus => $composableBuilder(
    column: $table.resolutionStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawJsonCache => $composableBuilder(
    column: $table.rawJsonCache,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mediaAssetsRefs(
    Expression<bool> Function($$MediaAssetsTableFilterComposer f) f,
  ) {
    final $$MediaAssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.savedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableFilterComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> downloadJobsRefs(
    Expression<bool> Function($$DownloadJobsTableFilterComposer f) f,
  ) {
    final $$DownloadJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadJobs,
      getReferencedColumn: (t) => t.savedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadJobsTableFilterComposer(
            $db: $db,
            $table: $db.downloadJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> downloadOutputsRefs(
    Expression<bool> Function($$DownloadOutputsTableFilterComposer f) f,
  ) {
    final $$DownloadOutputsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadOutputs,
      getReferencedColumn: (t) => t.savedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadOutputsTableFilterComposer(
            $db: $db,
            $table: $db.downloadOutputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SavedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedItemsTable> {
  $$SavedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permalink => $composableBuilder(
    column: $table.permalink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subreddit => $composableBuilder(
    column: $table.subreddit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdUtc => $composableBuilder(
    column: $table.createdUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyMarkdown => $composableBuilder(
    column: $table.bodyMarkdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get over18 => $composableBuilder(
    column: $table.over18,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastResolvedAt => $composableBuilder(
    column: $table.lastResolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolutionStatus => $composableBuilder(
    column: $table.resolutionStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawJsonCache => $composableBuilder(
    column: $table.rawJsonCache,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedItemsTable> {
  $$SavedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get permalink =>
      $composableBuilder(column: $table.permalink, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get subreddit =>
      $composableBuilder(column: $table.subreddit, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<int> get createdUtc => $composableBuilder(
    column: $table.createdUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get bodyMarkdown => $composableBuilder(
    column: $table.bodyMarkdown,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get over18 =>
      $composableBuilder(column: $table.over18, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastResolvedAt => $composableBuilder(
    column: $table.lastResolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolutionStatus => $composableBuilder(
    column: $table.resolutionStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawJsonCache => $composableBuilder(
    column: $table.rawJsonCache,
    builder: (column) => column,
  );

  Expression<T> mediaAssetsRefs<T extends Object>(
    Expression<T> Function($$MediaAssetsTableAnnotationComposer a) f,
  ) {
    final $$MediaAssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaAssets,
      getReferencedColumn: (t) => t.savedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaAssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> downloadJobsRefs<T extends Object>(
    Expression<T> Function($$DownloadJobsTableAnnotationComposer a) f,
  ) {
    final $$DownloadJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadJobs,
      getReferencedColumn: (t) => t.savedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.downloadJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> downloadOutputsRefs<T extends Object>(
    Expression<T> Function($$DownloadOutputsTableAnnotationComposer a) f,
  ) {
    final $$DownloadOutputsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadOutputs,
      getReferencedColumn: (t) => t.savedItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadOutputsTableAnnotationComposer(
            $db: $db,
            $table: $db.downloadOutputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SavedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedItemsTable,
          SavedItem,
          $$SavedItemsTableFilterComposer,
          $$SavedItemsTableOrderingComposer,
          $$SavedItemsTableAnnotationComposer,
          $$SavedItemsTableCreateCompanionBuilder,
          $$SavedItemsTableUpdateCompanionBuilder,
          (SavedItem, $$SavedItemsTableReferences),
          SavedItem,
          PrefetchHooks Function({
            bool mediaAssetsRefs,
            bool downloadJobsRefs,
            bool downloadOutputsRefs,
          })
        > {
  $$SavedItemsTableTableManager(_$AppDatabase db, $SavedItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> permalink = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> subreddit = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<int> createdUtc = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> bodyMarkdown = const Value.absent(),
                Value<bool> over18 = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> importedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> lastResolvedAt = const Value.absent(),
                Value<String> resolutionStatus = const Value.absent(),
                Value<String?> rawJsonCache = const Value.absent(),
              }) => SavedItemsCompanion(
                id: id,
                permalink: permalink,
                kind: kind,
                subreddit: subreddit,
                author: author,
                createdUtc: createdUtc,
                title: title,
                bodyMarkdown: bodyMarkdown,
                over18: over18,
                source: source,
                importedAt: importedAt,
                syncedAt: syncedAt,
                lastResolvedAt: lastResolvedAt,
                resolutionStatus: resolutionStatus,
                rawJsonCache: rawJsonCache,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String permalink,
                required String kind,
                required String subreddit,
                required String author,
                required int createdUtc,
                required String title,
                Value<String?> bodyMarkdown = const Value.absent(),
                Value<bool> over18 = const Value.absent(),
                required String source,
                Value<DateTime?> importedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> lastResolvedAt = const Value.absent(),
                required String resolutionStatus,
                Value<String?> rawJsonCache = const Value.absent(),
              }) => SavedItemsCompanion.insert(
                id: id,
                permalink: permalink,
                kind: kind,
                subreddit: subreddit,
                author: author,
                createdUtc: createdUtc,
                title: title,
                bodyMarkdown: bodyMarkdown,
                over18: over18,
                source: source,
                importedAt: importedAt,
                syncedAt: syncedAt,
                lastResolvedAt: lastResolvedAt,
                resolutionStatus: resolutionStatus,
                rawJsonCache: rawJsonCache,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SavedItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                mediaAssetsRefs = false,
                downloadJobsRefs = false,
                downloadOutputsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mediaAssetsRefs) db.mediaAssets,
                    if (downloadJobsRefs) db.downloadJobs,
                    if (downloadOutputsRefs) db.downloadOutputs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mediaAssetsRefs)
                        await $_getPrefetchedData<
                          SavedItem,
                          $SavedItemsTable,
                          MediaAsset
                        >(
                          currentTable: table,
                          referencedTable: $$SavedItemsTableReferences
                              ._mediaAssetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SavedItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaAssetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.savedItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (downloadJobsRefs)
                        await $_getPrefetchedData<
                          SavedItem,
                          $SavedItemsTable,
                          DownloadJob
                        >(
                          currentTable: table,
                          referencedTable: $$SavedItemsTableReferences
                              ._downloadJobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SavedItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).downloadJobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.savedItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (downloadOutputsRefs)
                        await $_getPrefetchedData<
                          SavedItem,
                          $SavedItemsTable,
                          DownloadOutput
                        >(
                          currentTable: table,
                          referencedTable: $$SavedItemsTableReferences
                              ._downloadOutputsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SavedItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).downloadOutputsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.savedItemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SavedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedItemsTable,
      SavedItem,
      $$SavedItemsTableFilterComposer,
      $$SavedItemsTableOrderingComposer,
      $$SavedItemsTableAnnotationComposer,
      $$SavedItemsTableCreateCompanionBuilder,
      $$SavedItemsTableUpdateCompanionBuilder,
      (SavedItem, $$SavedItemsTableReferences),
      SavedItem,
      PrefetchHooks Function({
        bool mediaAssetsRefs,
        bool downloadJobsRefs,
        bool downloadOutputsRefs,
      })
    >;
typedef $$MediaAssetsTableCreateCompanionBuilder =
    MediaAssetsCompanion Function({
      Value<int> id,
      required int savedItemId,
      required String type,
      required String sourceUrl,
      required String normalizedUrl,
      required String toolHint,
      Value<String?> filenameSuggested,
      Value<String?> metadataJson,
    });
typedef $$MediaAssetsTableUpdateCompanionBuilder =
    MediaAssetsCompanion Function({
      Value<int> id,
      Value<int> savedItemId,
      Value<String> type,
      Value<String> sourceUrl,
      Value<String> normalizedUrl,
      Value<String> toolHint,
      Value<String?> filenameSuggested,
      Value<String?> metadataJson,
    });

final class $$MediaAssetsTableReferences
    extends BaseReferences<_$AppDatabase, $MediaAssetsTable, MediaAsset> {
  $$MediaAssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SavedItemsTable _savedItemIdTable(_$AppDatabase db) =>
      db.savedItems.createAlias(
        $_aliasNameGenerator(db.mediaAssets.savedItemId, db.savedItems.id),
      );

  $$SavedItemsTableProcessedTableManager get savedItemId {
    final $_column = $_itemColumn<int>('saved_item_id')!;

    final manager = $$SavedItemsTableTableManager(
      $_db,
      $_db.savedItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_savedItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MediaAssetsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedUrl => $composableBuilder(
    column: $table.normalizedUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toolHint => $composableBuilder(
    column: $table.toolHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filenameSuggested => $composableBuilder(
    column: $table.filenameSuggested,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  $$SavedItemsTableFilterComposer get savedItemId {
    final $$SavedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedItemId,
      referencedTable: $db.savedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedItemsTableFilterComposer(
            $db: $db,
            $table: $db.savedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaAssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedUrl => $composableBuilder(
    column: $table.normalizedUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toolHint => $composableBuilder(
    column: $table.toolHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filenameSuggested => $composableBuilder(
    column: $table.filenameSuggested,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$SavedItemsTableOrderingComposer get savedItemId {
    final $$SavedItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedItemId,
      referencedTable: $db.savedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedItemsTableOrderingComposer(
            $db: $db,
            $table: $db.savedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaAssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaAssetsTable> {
  $$MediaAssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get normalizedUrl => $composableBuilder(
    column: $table.normalizedUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toolHint =>
      $composableBuilder(column: $table.toolHint, builder: (column) => column);

  GeneratedColumn<String> get filenameSuggested => $composableBuilder(
    column: $table.filenameSuggested,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  $$SavedItemsTableAnnotationComposer get savedItemId {
    final $$SavedItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedItemId,
      referencedTable: $db.savedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.savedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaAssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaAssetsTable,
          MediaAsset,
          $$MediaAssetsTableFilterComposer,
          $$MediaAssetsTableOrderingComposer,
          $$MediaAssetsTableAnnotationComposer,
          $$MediaAssetsTableCreateCompanionBuilder,
          $$MediaAssetsTableUpdateCompanionBuilder,
          (MediaAsset, $$MediaAssetsTableReferences),
          MediaAsset,
          PrefetchHooks Function({bool savedItemId})
        > {
  $$MediaAssetsTableTableManager(_$AppDatabase db, $MediaAssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaAssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaAssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaAssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> savedItemId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<String> normalizedUrl = const Value.absent(),
                Value<String> toolHint = const Value.absent(),
                Value<String?> filenameSuggested = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
              }) => MediaAssetsCompanion(
                id: id,
                savedItemId: savedItemId,
                type: type,
                sourceUrl: sourceUrl,
                normalizedUrl: normalizedUrl,
                toolHint: toolHint,
                filenameSuggested: filenameSuggested,
                metadataJson: metadataJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int savedItemId,
                required String type,
                required String sourceUrl,
                required String normalizedUrl,
                required String toolHint,
                Value<String?> filenameSuggested = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
              }) => MediaAssetsCompanion.insert(
                id: id,
                savedItemId: savedItemId,
                type: type,
                sourceUrl: sourceUrl,
                normalizedUrl: normalizedUrl,
                toolHint: toolHint,
                filenameSuggested: filenameSuggested,
                metadataJson: metadataJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaAssetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({savedItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (savedItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.savedItemId,
                                referencedTable: $$MediaAssetsTableReferences
                                    ._savedItemIdTable(db),
                                referencedColumn: $$MediaAssetsTableReferences
                                    ._savedItemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MediaAssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaAssetsTable,
      MediaAsset,
      $$MediaAssetsTableFilterComposer,
      $$MediaAssetsTableOrderingComposer,
      $$MediaAssetsTableAnnotationComposer,
      $$MediaAssetsTableCreateCompanionBuilder,
      $$MediaAssetsTableUpdateCompanionBuilder,
      (MediaAsset, $$MediaAssetsTableReferences),
      MediaAsset,
      PrefetchHooks Function({bool savedItemId})
    >;
typedef $$DownloadJobsTableCreateCompanionBuilder =
    DownloadJobsCompanion Function({
      Value<int> id,
      required int savedItemId,
      required String status,
      Value<double> progress,
      Value<int> attempts,
      Value<String?> lastError,
      required String policySnapshot,
      required String outputPath,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
    });
typedef $$DownloadJobsTableUpdateCompanionBuilder =
    DownloadJobsCompanion Function({
      Value<int> id,
      Value<int> savedItemId,
      Value<String> status,
      Value<double> progress,
      Value<int> attempts,
      Value<String?> lastError,
      Value<String> policySnapshot,
      Value<String> outputPath,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
    });

final class $$DownloadJobsTableReferences
    extends BaseReferences<_$AppDatabase, $DownloadJobsTable, DownloadJob> {
  $$DownloadJobsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SavedItemsTable _savedItemIdTable(_$AppDatabase db) =>
      db.savedItems.createAlias(
        $_aliasNameGenerator(db.downloadJobs.savedItemId, db.savedItems.id),
      );

  $$SavedItemsTableProcessedTableManager get savedItemId {
    final $_column = $_itemColumn<int>('saved_item_id')!;

    final manager = $$SavedItemsTableTableManager(
      $_db,
      $_db.savedItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_savedItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DownloadOutputsTable, List<DownloadOutput>>
  _downloadOutputsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.downloadOutputs,
    aliasName: $_aliasNameGenerator(
      db.downloadJobs.id,
      db.downloadOutputs.jobId,
    ),
  );

  $$DownloadOutputsTableProcessedTableManager get downloadOutputsRefs {
    final manager = $$DownloadOutputsTableTableManager(
      $_db,
      $_db.downloadOutputs,
    ).filter((f) => f.jobId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _downloadOutputsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DownloadJobsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get policySnapshot => $composableBuilder(
    column: $table.policySnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SavedItemsTableFilterComposer get savedItemId {
    final $$SavedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedItemId,
      referencedTable: $db.savedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedItemsTableFilterComposer(
            $db: $db,
            $table: $db.savedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> downloadOutputsRefs(
    Expression<bool> Function($$DownloadOutputsTableFilterComposer f) f,
  ) {
    final $$DownloadOutputsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadOutputs,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadOutputsTableFilterComposer(
            $db: $db,
            $table: $db.downloadOutputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DownloadJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get policySnapshot => $composableBuilder(
    column: $table.policySnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SavedItemsTableOrderingComposer get savedItemId {
    final $$SavedItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedItemId,
      referencedTable: $db.savedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedItemsTableOrderingComposer(
            $db: $db,
            $table: $db.savedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadJobsTable> {
  $$DownloadJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get policySnapshot => $composableBuilder(
    column: $table.policySnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$SavedItemsTableAnnotationComposer get savedItemId {
    final $$SavedItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedItemId,
      referencedTable: $db.savedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.savedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> downloadOutputsRefs<T extends Object>(
    Expression<T> Function($$DownloadOutputsTableAnnotationComposer a) f,
  ) {
    final $$DownloadOutputsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadOutputs,
      getReferencedColumn: (t) => t.jobId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadOutputsTableAnnotationComposer(
            $db: $db,
            $table: $db.downloadOutputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DownloadJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadJobsTable,
          DownloadJob,
          $$DownloadJobsTableFilterComposer,
          $$DownloadJobsTableOrderingComposer,
          $$DownloadJobsTableAnnotationComposer,
          $$DownloadJobsTableCreateCompanionBuilder,
          $$DownloadJobsTableUpdateCompanionBuilder,
          (DownloadJob, $$DownloadJobsTableReferences),
          DownloadJob,
          PrefetchHooks Function({bool savedItemId, bool downloadOutputsRefs})
        > {
  $$DownloadJobsTableTableManager(_$AppDatabase db, $DownloadJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> savedItemId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String> policySnapshot = const Value.absent(),
                Value<String> outputPath = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => DownloadJobsCompanion(
                id: id,
                savedItemId: savedItemId,
                status: status,
                progress: progress,
                attempts: attempts,
                lastError: lastError,
                policySnapshot: policySnapshot,
                outputPath: outputPath,
                startedAt: startedAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int savedItemId,
                required String status,
                Value<double> progress = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required String policySnapshot,
                required String outputPath,
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => DownloadJobsCompanion.insert(
                id: id,
                savedItemId: savedItemId,
                status: status,
                progress: progress,
                attempts: attempts,
                lastError: lastError,
                policySnapshot: policySnapshot,
                outputPath: outputPath,
                startedAt: startedAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DownloadJobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({savedItemId = false, downloadOutputsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (downloadOutputsRefs) db.downloadOutputs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (savedItemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.savedItemId,
                                    referencedTable:
                                        $$DownloadJobsTableReferences
                                            ._savedItemIdTable(db),
                                    referencedColumn:
                                        $$DownloadJobsTableReferences
                                            ._savedItemIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (downloadOutputsRefs)
                        await $_getPrefetchedData<
                          DownloadJob,
                          $DownloadJobsTable,
                          DownloadOutput
                        >(
                          currentTable: table,
                          referencedTable: $$DownloadJobsTableReferences
                              ._downloadOutputsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DownloadJobsTableReferences(
                                db,
                                table,
                                p0,
                              ).downloadOutputsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.jobId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DownloadJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadJobsTable,
      DownloadJob,
      $$DownloadJobsTableFilterComposer,
      $$DownloadJobsTableOrderingComposer,
      $$DownloadJobsTableAnnotationComposer,
      $$DownloadJobsTableCreateCompanionBuilder,
      $$DownloadJobsTableUpdateCompanionBuilder,
      (DownloadJob, $$DownloadJobsTableReferences),
      DownloadJob,
      PrefetchHooks Function({bool savedItemId, bool downloadOutputsRefs})
    >;
typedef $$DownloadOutputsTableCreateCompanionBuilder =
    DownloadOutputsCompanion Function({
      Value<int> id,
      required int jobId,
      required int savedItemId,
      required String path,
      required String kind,
      Value<DateTime> createdAt,
    });
typedef $$DownloadOutputsTableUpdateCompanionBuilder =
    DownloadOutputsCompanion Function({
      Value<int> id,
      Value<int> jobId,
      Value<int> savedItemId,
      Value<String> path,
      Value<String> kind,
      Value<DateTime> createdAt,
    });

final class $$DownloadOutputsTableReferences
    extends
        BaseReferences<_$AppDatabase, $DownloadOutputsTable, DownloadOutput> {
  $$DownloadOutputsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DownloadJobsTable _jobIdTable(_$AppDatabase db) =>
      db.downloadJobs.createAlias(
        $_aliasNameGenerator(db.downloadOutputs.jobId, db.downloadJobs.id),
      );

  $$DownloadJobsTableProcessedTableManager get jobId {
    final $_column = $_itemColumn<int>('job_id')!;

    final manager = $$DownloadJobsTableTableManager(
      $_db,
      $_db.downloadJobs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_jobIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SavedItemsTable _savedItemIdTable(_$AppDatabase db) =>
      db.savedItems.createAlias(
        $_aliasNameGenerator(db.downloadOutputs.savedItemId, db.savedItems.id),
      );

  $$SavedItemsTableProcessedTableManager get savedItemId {
    final $_column = $_itemColumn<int>('saved_item_id')!;

    final manager = $$SavedItemsTableTableManager(
      $_db,
      $_db.savedItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_savedItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DownloadOutputsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadOutputsTable> {
  $$DownloadOutputsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DownloadJobsTableFilterComposer get jobId {
    final $$DownloadJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.downloadJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadJobsTableFilterComposer(
            $db: $db,
            $table: $db.downloadJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SavedItemsTableFilterComposer get savedItemId {
    final $$SavedItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedItemId,
      referencedTable: $db.savedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedItemsTableFilterComposer(
            $db: $db,
            $table: $db.savedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadOutputsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadOutputsTable> {
  $$DownloadOutputsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DownloadJobsTableOrderingComposer get jobId {
    final $$DownloadJobsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.downloadJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadJobsTableOrderingComposer(
            $db: $db,
            $table: $db.downloadJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SavedItemsTableOrderingComposer get savedItemId {
    final $$SavedItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedItemId,
      referencedTable: $db.savedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedItemsTableOrderingComposer(
            $db: $db,
            $table: $db.savedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadOutputsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadOutputsTable> {
  $$DownloadOutputsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DownloadJobsTableAnnotationComposer get jobId {
    final $$DownloadJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.jobId,
      referencedTable: $db.downloadJobs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.downloadJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SavedItemsTableAnnotationComposer get savedItemId {
    final $$SavedItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.savedItemId,
      referencedTable: $db.savedItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.savedItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadOutputsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadOutputsTable,
          DownloadOutput,
          $$DownloadOutputsTableFilterComposer,
          $$DownloadOutputsTableOrderingComposer,
          $$DownloadOutputsTableAnnotationComposer,
          $$DownloadOutputsTableCreateCompanionBuilder,
          $$DownloadOutputsTableUpdateCompanionBuilder,
          (DownloadOutput, $$DownloadOutputsTableReferences),
          DownloadOutput,
          PrefetchHooks Function({bool jobId, bool savedItemId})
        > {
  $$DownloadOutputsTableTableManager(
    _$AppDatabase db,
    $DownloadOutputsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadOutputsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadOutputsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadOutputsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> jobId = const Value.absent(),
                Value<int> savedItemId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DownloadOutputsCompanion(
                id: id,
                jobId: jobId,
                savedItemId: savedItemId,
                path: path,
                kind: kind,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int jobId,
                required int savedItemId,
                required String path,
                required String kind,
                Value<DateTime> createdAt = const Value.absent(),
              }) => DownloadOutputsCompanion.insert(
                id: id,
                jobId: jobId,
                savedItemId: savedItemId,
                path: path,
                kind: kind,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DownloadOutputsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({jobId = false, savedItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (jobId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.jobId,
                                referencedTable:
                                    $$DownloadOutputsTableReferences
                                        ._jobIdTable(db),
                                referencedColumn:
                                    $$DownloadOutputsTableReferences
                                        ._jobIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (savedItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.savedItemId,
                                referencedTable:
                                    $$DownloadOutputsTableReferences
                                        ._savedItemIdTable(db),
                                referencedColumn:
                                    $$DownloadOutputsTableReferences
                                        ._savedItemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DownloadOutputsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadOutputsTable,
      DownloadOutput,
      $$DownloadOutputsTableFilterComposer,
      $$DownloadOutputsTableOrderingComposer,
      $$DownloadOutputsTableAnnotationComposer,
      $$DownloadOutputsTableCreateCompanionBuilder,
      $$DownloadOutputsTableUpdateCompanionBuilder,
      (DownloadOutput, $$DownloadOutputsTableReferences),
      DownloadOutput,
      PrefetchHooks Function({bool jobId, bool savedItemId})
    >;
typedef $$LogEntriesTableCreateCompanionBuilder =
    LogEntriesCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      required String scope,
      required String level,
      required String message,
      Value<String?> contextJson,
      Value<int?> relatedJobId,
    });
typedef $$LogEntriesTableUpdateCompanionBuilder =
    LogEntriesCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<String> scope,
      Value<String> level,
      Value<String> message,
      Value<String?> contextJson,
      Value<int?> relatedJobId,
    });

class $$LogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get relatedJobId => $composableBuilder(
    column: $table.relatedJobId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get relatedJobId => $composableBuilder(
    column: $table.relatedJobId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get relatedJobId => $composableBuilder(
    column: $table.relatedJobId,
    builder: (column) => column,
  );
}

class $$LogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogEntriesTable,
          LogEntry,
          $$LogEntriesTableFilterComposer,
          $$LogEntriesTableOrderingComposer,
          $$LogEntriesTableAnnotationComposer,
          $$LogEntriesTableCreateCompanionBuilder,
          $$LogEntriesTableUpdateCompanionBuilder,
          (LogEntry, BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry>),
          LogEntry,
          PrefetchHooks Function()
        > {
  $$LogEntriesTableTableManager(_$AppDatabase db, $LogEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String?> contextJson = const Value.absent(),
                Value<int?> relatedJobId = const Value.absent(),
              }) => LogEntriesCompanion(
                id: id,
                timestamp: timestamp,
                scope: scope,
                level: level,
                message: message,
                contextJson: contextJson,
                relatedJobId: relatedJobId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                required String scope,
                required String level,
                required String message,
                Value<String?> contextJson = const Value.absent(),
                Value<int?> relatedJobId = const Value.absent(),
              }) => LogEntriesCompanion.insert(
                id: id,
                timestamp: timestamp,
                scope: scope,
                level: level,
                message: message,
                contextJson: contextJson,
                relatedJobId: relatedJobId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogEntriesTable,
      LogEntry,
      $$LogEntriesTableFilterComposer,
      $$LogEntriesTableOrderingComposer,
      $$LogEntriesTableAnnotationComposer,
      $$LogEntriesTableCreateCompanionBuilder,
      $$LogEntriesTableUpdateCompanionBuilder,
      (LogEntry, BaseReferences<_$AppDatabase, $LogEntriesTable, LogEntry>),
      LogEntry,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      required String dataJson,
      required DateTime updatedAt,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<String> dataJson,
      Value<DateTime> updatedAt,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                dataJson: dataJson,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dataJson,
                required DateTime updatedAt,
              }) => SettingsCompanion.insert(
                id: id,
                dataJson: dataJson,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SavedItemsTableTableManager get savedItems =>
      $$SavedItemsTableTableManager(_db, _db.savedItems);
  $$MediaAssetsTableTableManager get mediaAssets =>
      $$MediaAssetsTableTableManager(_db, _db.mediaAssets);
  $$DownloadJobsTableTableManager get downloadJobs =>
      $$DownloadJobsTableTableManager(_db, _db.downloadJobs);
  $$DownloadOutputsTableTableManager get downloadOutputs =>
      $$DownloadOutputsTableTableManager(_db, _db.downloadOutputs);
  $$LogEntriesTableTableManager get logEntries =>
      $$LogEntriesTableTableManager(_db, _db.logEntries);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
