import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<AppSettings> load() async {
    final row = await (_db.select(_db.settings)
          ..where((tbl) => tbl.id.equals(AppSettings.storageId)))
        .getSingleOrNull();
    if (row == null) {
      final defaults = AppSettings.defaults();
      await save(defaults);
      return defaults;
    }
    final jsonMap = jsonDecode(row.dataJson) as Map<String, dynamic>;
    return AppSettings.fromJson(jsonMap);
  }

  Future<void> save(AppSettings settings) async {
    final data = jsonEncode(settings.toJson());
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion(
            id: const Value(AppSettings.storageId),
            dataJson: Value(data),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Stream<AppSettings> watch() {
    final query = (_db.select(_db.settings)
          ..where((tbl) => tbl.id.equals(AppSettings.storageId)))
        .watchSingleOrNull();
    return query.map((row) {
      if (row == null) {
        return AppSettings.defaults();
      }
      final jsonMap = jsonDecode(row.dataJson) as Map<String, dynamic>;
      return AppSettings.fromJson(jsonMap);
    });
  }
}

enum AppThemeMode { light, dark }

enum OverwritePolicy { skipIfExists, overwriteIfNewer }

class AppSettings {
  const AppSettings({
    required this.downloadRoot,
    required this.overwritePolicy,
    required this.downloadNsfw,
    required this.rememberSession,
    required this.themeMode,
    required this.concurrency,
    required this.rateLimitPerMinute,
  });

  static const int storageId = 1;

  final String downloadRoot;
  final OverwritePolicy overwritePolicy;
  final bool downloadNsfw;
  final bool rememberSession;
  final AppThemeMode themeMode;
  final int concurrency;
  final int rateLimitPerMinute;

  static AppSettings defaults() {
    return const AppSettings(
      downloadRoot: '',
      overwritePolicy: OverwritePolicy.skipIfExists,
      downloadNsfw: false,
      rememberSession: false,
      themeMode: AppThemeMode.light,
      concurrency: 2,
      rateLimitPerMinute: 30,
    );
  }

  AppSettings copyWith({
    String? downloadRoot,
    OverwritePolicy? overwritePolicy,
    bool? downloadNsfw,
    bool? rememberSession,
    AppThemeMode? themeMode,
    int? concurrency,
    int? rateLimitPerMinute,
  }) {
    return AppSettings(
      downloadRoot: downloadRoot ?? this.downloadRoot,
      overwritePolicy: overwritePolicy ?? this.overwritePolicy,
      downloadNsfw: downloadNsfw ?? this.downloadNsfw,
      rememberSession: rememberSession ?? this.rememberSession,
      themeMode: themeMode ?? this.themeMode,
      concurrency: concurrency ?? this.concurrency,
      rateLimitPerMinute: rateLimitPerMinute ?? this.rateLimitPerMinute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'downloadRoot': downloadRoot,
      'overwritePolicy': overwritePolicy.name,
      'downloadNsfw': downloadNsfw,
      'rememberSession': rememberSession,
      'themeMode': themeMode.name,
      'concurrency': concurrency,
      'rateLimitPerMinute': rateLimitPerMinute,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      downloadRoot: json['downloadRoot'] as String? ?? '',
      overwritePolicy: _parseOverwritePolicy(
        json['overwritePolicy'] as String?,
      ),
      downloadNsfw: json['downloadNsfw'] as bool? ?? false,
      rememberSession: json['rememberSession'] as bool? ?? false,
      themeMode: _parseThemeMode(json['themeMode'] as String?),
      concurrency: json['concurrency'] as int? ?? 2,
      rateLimitPerMinute: json['rateLimitPerMinute'] as int? ?? 30,
    );
  }

  ThemeMode get themeModeValue {
    switch (themeMode) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
    }
  }
}

AppThemeMode _parseThemeMode(String? value) {
  switch (value) {
    case 'dark':
      return AppThemeMode.dark;
    case 'light':
    default:
      return AppThemeMode.light;
  }
}

OverwritePolicy _parseOverwritePolicy(String? value) {
  switch (value) {
    case 'overwriteIfNewer':
      return OverwritePolicy.overwriteIfNewer;
    case 'skipIfExists':
    default:
      return OverwritePolicy.skipIfExists;
  }
}
