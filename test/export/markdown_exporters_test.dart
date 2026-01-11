import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/settings_repository.dart';
import 'package:reddit_dl/services/export/saved_comment_markdown_exporter.dart';
import 'package:reddit_dl/services/export/text_post_markdown_exporter.dart';
import 'package:reddit_dl/services/export/thread_comments_markdown_exporter.dart';
import 'package:reddit_dl/services/path_template_engine.dart';

void main() {
  test('text post exporter writes markdown file', () async {
    final tempDir = await Directory.systemTemp.createTemp('export-text');
    addTearDown(() async => tempDir.delete(recursive: true));
    final settings = AppSettings.defaults().copyWith(
      downloadRoot: tempDir.path,
      textRoot: 'text',
      mediaPathTemplate: '{type}/{subreddit}/{yyyy}/{mm}/{title_slug}-{id}',
    );
    final engine = PathTemplateEngine(settings);
    final exporter = TextPostMarkdownExporter();

    final item = _buildItem(
      kind: 'post',
      bodyMarkdown: 'Hello **world**',
    );

    final result = await exporter.export(
      item: item,
      engine: engine,
      policy: OverwritePolicy.skipIfExists,
    );

    expect(result.isCompleted, isTrue);
    final content = await File(result.outputPath).readAsString();
    expect(content, contains('Hello **world**'));
  });

  test('saved comment exporter writes markdown file', () async {
    final tempDir = await Directory.systemTemp.createTemp('export-comment');
    addTearDown(() async => tempDir.delete(recursive: true));
    final settings = AppSettings.defaults().copyWith(
      downloadRoot: tempDir.path,
      commentsRoot: 'comments',
      mediaPathTemplate: '{type}/{subreddit}/{yyyy}/{mm}/{title_slug}-{id}',
    );
    final engine = PathTemplateEngine(settings);
    final exporter = SavedCommentMarkdownExporter();

    final item = _buildItem(
      kind: 'comment',
      bodyMarkdown: 'Saved comment',
    );

    final result = await exporter.export(
      item: item,
      engine: engine,
      policy: OverwritePolicy.skipIfExists,
    );

    expect(result.isCompleted, isTrue);
    final content = await File(result.outputPath).readAsString();
    expect(content, contains('Saved comment'));
  });

  test('thread comments exporter writes nested markdown', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    final exporter = ThreadCommentsMarkdownExporter(dio);

    final tempDir = await Directory.systemTemp.createTemp('export-thread');
    addTearDown(() async => tempDir.delete(recursive: true));
    final settings = AppSettings.defaults().copyWith(
      downloadRoot: tempDir.path,
      mediaPathTemplate: '{type}/{subreddit}/{yyyy}/{mm}/{title_slug}-{id}',
    );
    final engine = PathTemplateEngine(settings);

    const url =
        'https://www.reddit.com/r/test/comments/abc/title.json?sort=best&raw_json=1';
    adapter.onGet(
      url,
      (server) => server.reply(
        200,
        jsonDecode(_threadCommentsJson),
      ),
    );

    final item = _buildItem(kind: 'post');
    final result = await exporter.export(
      item: item,
      engine: engine,
      policy: OverwritePolicy.skipIfExists,
      sort: CommentSort.best,
    );

    expect(result.isCompleted, isTrue);
    final content = await File(result.outputPath).readAsString();
    expect(content, contains('u/alice'));
    expect(content, contains('u/bob'));
  });
}

SavedItem _buildItem({
  required String kind,
  String? bodyMarkdown,
}) {
  return SavedItem(
    id: 1,
    permalink: 'https://www.reddit.com/r/test/comments/abc/title',
    kind: kind,
    subreddit: 'test',
    author: 'alice',
    createdUtc: 1700000000,
    title: 'Title',
    bodyMarkdown: bodyMarkdown,
    over18: false,
    source: 'sync',
    importedAt: null,
    syncedAt: null,
    lastResolvedAt: null,
    resolutionStatus: 'ok',
    rawJsonCache: null,
  );
}

const _threadCommentsJson = '''
[
  {
    "data": {
      "children": [
        {
          "kind": "t3",
          "data": { "id": "abc" }
        }
      ]
    }
  },
  {
    "data": {
      "children": [
        {
          "kind": "t1",
          "data": {
            "author": "alice",
            "body": "Top level",
            "created_utc": 1700000001,
            "score": 12,
            "permalink": "/r/test/comments/abc/title/comment1",
            "replies": {
              "data": {
                "children": [
                  {
                    "kind": "t1",
                    "data": {
                      "author": "bob",
                      "body": "Nested reply",
                      "created_utc": 1700000002,
                      "score": 4,
                      "permalink": "/r/test/comments/abc/title/comment2"
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
]
''';
