import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';

class ZipImportParser {
  ImportArchive parseBytes(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);

    final postsCsv = _readCsvFile(archive, 'saved_posts.csv');
    final commentsCsv = _readCsvFile(archive, 'saved_comments.csv');

    if (postsCsv == null && commentsCsv == null) {
      throw const ZipImportException(
        'ZIP missing saved_posts.csv and saved_comments.csv.',
      );
    }

    final posts =
        postsCsv == null
            ? <ImportItem>[]
            : _parseCsv(postsCsv, ImportKind.post);
    final comments =
        commentsCsv == null
            ? <ImportItem>[]
            : _parseCsv(commentsCsv, ImportKind.comment);

    return ImportArchive(posts: posts, comments: comments);
  }

  String? _readCsvFile(Archive archive, String targetName) {
    for (final file in archive) {
      final name = file.name.toLowerCase();
      if (name.endsWith(targetName)) {
        final content = file.readBytes();
        if (content == null) {
          return null;
        }
        return utf8.decode(content, allowMalformed: true);
      }
    }
    return null;
  }

  List<ImportItem> _parseCsv(String csvText, ImportKind kind) {
    final converter = const CsvToListConverter(
      shouldParseNumbers: false,
      allowInvalid: true,
      eol: '\n',
    );
    final rows = converter.convert(csvText);
    if (rows.isEmpty) {
      return [];
    }

    final headers =
        rows.first
            .map((value) => value.toString().trim())
            .map((value) => value.replaceFirst('\uFEFF', ''))
            .map((value) => value.toLowerCase())
            .toList();
    final indices = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      indices[headers[i]] = i;
    }

    final permalinkIndex = _indexFor(indices, ['permalink', 'link']);
    if (permalinkIndex == null) {
      throw const ZipImportException('CSV missing permalink column.');
    }

    return rows
        .skip(1)
        .where((row) => row.isNotEmpty)
        .map((row) {
          final permalink = _cell(row, permalinkIndex) ?? '';
          final subreddit = _cell(row, _indexFor(indices, ['subreddit'])) ?? '';
          final author =
              _cell(row, _indexFor(indices, ['author', 'author_name'])) ??
              'unknown';
          final title = _cell(row, _indexFor(indices, ['title'])) ?? '';
          final body =
              _cell(row, _indexFor(indices, ['body', 'comment', 'selftext'])) ??
              '';
          final createdUtc = _parseInt(
            _cell(row, _indexFor(indices, ['created_utc', 'created'])),
          );

          return ImportItem(
            kind: kind,
            permalink: permalink,
            subreddit: subreddit,
            author: author,
            title: title,
            body: body,
            createdUtc: createdUtc,
          );
        })
        .where((item) => item.permalink.isNotEmpty)
        .toList();
  }

  int? _indexFor(Map<String, int> indices, List<String> keys) {
    for (final key in keys) {
      final index = indices[key];
      if (index != null) {
        return index;
      }
    }
    return null;
  }

  String? _cell(List<dynamic> row, int? index) {
    if (index == null || index >= row.length) {
      return null;
    }
    final value = row[index].toString().trim();
    return value.isEmpty ? null : value;
  }

  int? _parseInt(String? value) {
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }
}

enum ImportKind { post, comment }

class ImportItem {
  const ImportItem({
    required this.kind,
    required this.permalink,
    required this.subreddit,
    required this.author,
    required this.title,
    required this.body,
    required this.createdUtc,
  });

  final ImportKind kind;
  final String permalink;
  final String subreddit;
  final String author;
  final String title;
  final String body;
  final int? createdUtc;
}

class ImportArchive {
  const ImportArchive({required this.posts, required this.comments});

  final List<ImportItem> posts;
  final List<ImportItem> comments;
}

class ZipImportException implements Exception {
  const ZipImportException(this.message);

  final String message;

  @override
  String toString() => 'ZipImportException: $message';
}
