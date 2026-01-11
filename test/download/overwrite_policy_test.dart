import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:reddit_dl/data/settings_repository.dart';
import 'package:reddit_dl/services/download/overwrite_policy.dart';

void main() {
  test('skip if exists returns skip decision', () async {
    final dio = Dio();
    final evaluator = OverwritePolicyEvaluator(dio);
    final dir = await Directory.systemTemp.createTemp('overwrite-test');
    addTearDown(() async => dir.delete(recursive: true));
    final file = File('${dir.path}/file.jpg');
    await file.writeAsString('data');

    final decision = await evaluator.evaluate(
      file,
      Uri.parse('https://example.com/file.jpg'),
      OverwritePolicy.skipIfExists,
    );

    expect(decision.shouldDownload, isFalse);
  });

  test('overwrite if newer uses last-modified header', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    final evaluator = OverwritePolicyEvaluator(dio);
    final dir = await Directory.systemTemp.createTemp('overwrite-test');
    addTearDown(() async => dir.delete(recursive: true));
    final file = File('${dir.path}/file.jpg');
    await file.writeAsString('data');
    await file.setLastModified(DateTime(2023, 1, 1));

    adapter.onHead(
      'https://example.com/file.jpg',
      (server) => server.reply(
        200,
        '',
        headers: {
          HttpHeaders.lastModifiedHeader: HttpDate.format(DateTime(2024, 1, 1)),
        },
      ),
    );

    final decision = await evaluator.evaluate(
      file,
      Uri.parse('https://example.com/file.jpg'),
      OverwritePolicy.overwriteIfNewer,
    );

    expect(decision.shouldDownload, isTrue);
  });

  test('overwrite if newer skips when undetermined', () async {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    final evaluator = OverwritePolicyEvaluator(dio);
    final dir = await Directory.systemTemp.createTemp('overwrite-test');
    addTearDown(() async => dir.delete(recursive: true));
    final file = File('${dir.path}/file.jpg');
    await file.writeAsString('data');

    adapter.onHead(
      'https://example.com/file.jpg',
      (server) => server.reply(200, ''),
    );

    final decision = await evaluator.evaluate(
      file,
      Uri.parse('https://example.com/file.jpg'),
      OverwritePolicy.overwriteIfNewer,
    );

    expect(decision.shouldDownload, isFalse);
  });
}
