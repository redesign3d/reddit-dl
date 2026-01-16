import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/data/app_database.dart';
import 'package:reddit_dl/data/settings_repository.dart';
import 'package:reddit_dl/services/path_template_engine.dart';

void main() {
  test('resolves tokens into directory path', () {
    final settings = AppSettings.defaults().copyWith(
      downloadRoot: '/downloads',
      mediaPathTemplate: '{type}/{subreddit}/{yyyy}/{mm}/{title_slug}-{id}',
    );
    final engine = PathTemplateEngine(settings);
    final item = _buildItem(
      title: 'Hello World',
      createdUtc: 1700000000,
      permalink: 'https://www.reddit.com/r/test/comments/abc/title',
    );
    final asset = _buildAsset();

    final result = engine.resolve(item: item, asset: asset);
    expect(result.isValid, isTrue);
    expect(
      result.directoryPath,
      contains('/downloads/post/test/2023/11/hello-world-abc'),
    );
  });

  test('sanitizes unsafe segments and warns on traversal', () {
    final settings = AppSettings.defaults().copyWith(
      downloadRoot: '/downloads',
      mediaPathTemplate: '../{subreddit}/../{title_slug}',
    );
    final engine = PathTemplateEngine(settings);
    final item = _buildItem(
      title: 'Bad/Title:*',
      permalink: 'https://www.reddit.com/r/test/comments/abc/title',
    );
    final asset = _buildAsset();

    final result = engine.resolve(item: item, asset: asset);
    expect(result.isValid, isTrue);
    expect(result.warnings, isNotEmpty);
  });

  test('applies folder-per-media layout', () {
    final settings = AppSettings.defaults().copyWith(
      downloadRoot: '/downloads',
      mediaLayoutMode: MediaLayoutMode.folderPerMedia,
    );
    final engine = PathTemplateEngine(settings);
    final item = _buildItem(
      title: 'Gallery',
      permalink: 'https://www.reddit.com/r/test/comments/abc/title',
    );
    final asset = _buildAsset(
      sourceUrl: 'https://i.redd.it/image.png',
      normalizedUrl: 'https://i.redd.it/image.png',
    );

    final result = engine.resolve(item: item, asset: asset);
    expect(result.isValid, isTrue);
    expect(result.filePath, contains('/image/image.png'));
  });

  test('truncates long title slugs', () {
    final settings = AppSettings.defaults().copyWith(
      downloadRoot: '/downloads',
      mediaPathTemplate: '{title_slug}',
    );
    final engine = PathTemplateEngine(settings);
    final longTitle = List.filled(200, 'a').join();
    final item = _buildItem(title: longTitle);
    final asset = _buildAsset();

    final result = engine.resolve(item: item, asset: asset);
    expect(result.isValid, isTrue);
    final segment = result.directoryPath.split('/').last;
    expect(segment.length, lessThanOrEqualTo(80));
    expect(
      result.warnings.any((warning) => warning.contains('title_slug')),
      isTrue,
    );
  });

  test('warns when path length exceeds limit', () {
    final settings = AppSettings.defaults().copyWith(
      downloadRoot: '/downloads/${List.filled(260, 'a').join()}',
      mediaPathTemplate: '{title_slug}',
    );
    final engine = PathTemplateEngine(settings);
    final item = _buildItem(title: 'Long path warning');
    final asset = _buildAsset(
      sourceUrl:
          'https://example.com/${List.filled(200, 'file').join()}-image.jpg',
    );

    final result = engine.resolve(item: item, asset: asset);
    expect(result.isValid, isTrue);
    expect(
      result.warnings.any((warning) => warning.contains('Path length exceeds')),
      isTrue,
    );
  });
}

SavedItem _buildItem({
  String title = 'Sample',
  int createdUtc = 1700000000,
  String permalink = 'https://www.reddit.com/r/test/comments/abc/title',
}) {
  return SavedItem(
    id: 1,
    permalink: permalink,
    kind: 'post',
    subreddit: 'test',
    author: 'alice',
    createdUtc: createdUtc,
    title: title,
    bodyMarkdown: null,
    over18: false,
    source: 'sync',
    importedAt: null,
    syncedAt: null,
    lastResolvedAt: null,
    resolutionStatus: 'ok',
    rawJsonCache: null,
  );
}

MediaAsset _buildAsset({
  String sourceUrl = 'https://example.com/image.jpg',
  String normalizedUrl = 'https://example.com/image.jpg',
}) {
  return MediaAsset(
    id: 1,
    savedItemId: 1,
    type: 'image',
    sourceUrl: sourceUrl,
    normalizedUrl: normalizedUrl,
    toolHint: 'none',
    filenameSuggested: null,
    metadataJson: null,
  );
}
