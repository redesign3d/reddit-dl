import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/features/import/zip_import_parser.dart';

void main() {
  test('parses saved posts and comments from zip', () {
    final zipBytes = _buildZip({
      'data/saved_posts.csv': _savedPostsCsv(),
      'data/saved_comments.csv': _savedCommentsCsv(),
    });

    final parser = ZipImportParser();
    final result = parser.parseBytes(zipBytes);
    expect(result.posts, hasLength(2));
    expect(result.comments, hasLength(1));
    expect(result.posts.first.permalink, contains('/r/test/'));
    expect(result.comments.first.kind, ImportKind.comment);
  });

  test('throws when zip missing saved csv files', () {
    final zipBytes = _buildZip({'data/other.csv': 'id,name\n1,example'});

    final parser = ZipImportParser();

    expect(
      () => parser.parseBytes(zipBytes),
      throwsA(isA<ZipImportException>()),
    );
  });

  test('normalizes supported permalink forms and skips invalid rows', () {
    final zipBytes = _buildZip({
      'saved_posts.csv': [
        'permalink,subreddit,author,title,created_utc',
        'https://old.reddit.com/r/test/comments/abc/post-1/,test,alice,Post one,1700000000',
        '/r/test/comments/abc/post-1/.json,test,alice,Post one,1700000000',
        'https://www.reddit.com/r/test,test,alice,Unsupported row,1700000001',
      ].join('\n'),
    });

    final parser = ZipImportParser();
    final result = parser.parseBytes(zipBytes);

    expect(result.posts, hasLength(2));
    expect(result.posts.map((post) => post.permalink).toSet(), {
      'https://www.reddit.com/r/test/comments/abc/post-1',
    });
  });
}

Uint8List _buildZip(Map<String, String> files) {
  final archive = Archive();
  files.forEach((path, content) {
    archive.addFile(ArchiveFile.string(path, content));
  });
  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded);
}

String _savedPostsCsv() {
  return [
    'permalink,subreddit,author,title,created_utc',
    'https://reddit.com/r/test/comments/abc/post-1,test,alice,Post one,1700000000',
    'https://reddit.com/r/test/comments/def/post-2,test,bob,Post two,1700000100',
  ].join('\n');
}

String _savedCommentsCsv() {
  return [
    'permalink,subreddit,author,body,created_utc',
    'https://reddit.com/r/test/comments/xyz/comment-1,test,charlie,Hello!,1700000200',
  ].join('\n');
}
