import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../data/app_database.dart';
import '../../data/settings_repository.dart';
import '../../features/sync/permalink_utils.dart';
import '../path_template_engine.dart';
import '../download/overwrite_policy.dart';
import 'export_result.dart';

class ThreadCommentsMarkdownExporter {
  ThreadCommentsMarkdownExporter(this._dio);

  final Dio _dio;

  Future<ExportResult> export({
    required SavedItem item,
    required PathTemplateEngine engine,
    required OverwritePolicy policy,
    required CommentSort sort,
    int? maxCount,
    int? timeframeDays,
    CancelToken? cancelToken,
  }) async {
    if (item.kind != 'post') {
      return ExportResult.skipped('Not a post.', '');
    }

    final comments = await _fetchComments(
      item.permalink,
      sort: sort,
      maxCount: maxCount,
      timeframeDays: timeframeDays,
      cancelToken: cancelToken,
    );
    if (comments.isEmpty) {
      return ExportResult.skipped('No comments found.', '');
    }

    final placeholder = MediaAsset(
      id: 0,
      savedItemId: item.id,
      type: 'image',
      sourceUrl: item.permalink,
      normalizedUrl: item.permalink,
      toolHint: 'none',
      filenameSuggested: null,
      metadataJson: null,
    );
    final pathResult = engine.resolve(item: item, asset: placeholder);
    if (!pathResult.isValid) {
      return ExportResult.failed(pathResult.error ?? 'Invalid path.', '');
    }

    final commentsDir = Directory(p.join(pathResult.directoryPath, 'comments'));
    final targetFile = File(p.join(commentsDir.path, 'comments.md'));

    if (await targetFile.exists()) {
      if (policy == OverwritePolicy.skipIfExists) {
        return ExportResult.skipped('File exists.', targetFile.path);
      }
      return ExportResult.skipped(
        'Unable to determine newer export.',
        targetFile.path,
      );
    }

    if (!await commentsDir.exists()) {
      await commentsDir.create(recursive: true);
    }

    final content = _buildMarkdown(
      item,
      comments,
      sort,
      maxCount,
      timeframeDays,
    );
    await targetFile.writeAsString(content);
    return ExportResult.completed(targetFile.path);
  }

  Future<List<ThreadComment>> _fetchComments(
    String permalink, {
    required CommentSort sort,
    int? maxCount,
    int? timeframeDays,
    CancelToken? cancelToken,
  }) async {
    final url = _commentsUrl(permalink, sort, maxCount);
    final response = await _dio.get<dynamic>(url, cancelToken: cancelToken);
    final status = response.statusCode ?? 0;
    if (status == 429) {
      final retryAfter = response.headers.value(HttpHeaders.retryAfterHeader);
      throw DownloadRateLimitException(
        retryAfterSeconds: retryAfter == null ? null : int.tryParse(retryAfter),
      );
    }
    if (status >= 400) {
      return const [];
    }
    final comments = _extractComments(response.data);
    var filtered = comments;
    if (timeframeDays != null && timeframeDays > 0) {
      final cutoff = DateTime.now().toUtc().subtract(
        Duration(days: timeframeDays),
      );
      filtered =
          comments
              .where(
                (comment) => DateTime.fromMillisecondsSinceEpoch(
                  comment.createdUtc * 1000,
                  isUtc: true,
                ).isAfter(cutoff),
              )
              .toList();
    }
    if (maxCount != null && maxCount > 0 && filtered.length > maxCount) {
      filtered = filtered.take(maxCount).toList();
    }
    return filtered;
  }

  String _commentsUrl(String permalink, CommentSort sort, int? maxCount) {
    final normalized = normalizePermalink(permalink);
    final base = normalized.endsWith('.json') ? normalized : '$normalized.json';
    final uri = Uri.parse(base);
    final params = <String, String>{'sort': _sortValue(sort), 'raw_json': '1'};
    if (maxCount != null && maxCount > 0) {
      params['limit'] = maxCount.toString();
    }
    return uri.replace(queryParameters: params).toString();
  }

  List<ThreadComment> _extractComments(dynamic json) {
    if (json is! List || json.length < 2) {
      return const [];
    }
    final listing = json[1];
    final data = listing is Map<String, dynamic> ? listing['data'] : null;
    final listingData = data is Map<String, dynamic> ? data : null;
    final children = listingData?['children'];
    if (children is! List) {
      return const [];
    }
    final results = <ThreadComment>[];
    _walkComments(children, 0, results);
    return results;
  }

  void _walkComments(
    List<dynamic> children,
    int depth,
    List<ThreadComment> results,
  ) {
    for (final child in children) {
      if (child is! Map<String, dynamic>) {
        continue;
      }
      final kind = child['kind'] as String?;
      final data = child['data'];
      if (kind == 't1' && data is Map<String, dynamic>) {
        final body = data['body'] as String? ?? '';
        final author = data['author'] as String? ?? 'unknown';
        final createdUtc = (data['created_utc'] as num?)?.toInt() ?? 0;
        final score = (data['score'] as num?)?.toInt() ?? 0;
        final permalink = data['permalink'] as String? ?? '';
        results.add(
          ThreadComment(
            author: author,
            body: body,
            createdUtc: createdUtc,
            depth: depth,
            score: score,
            permalink: permalink,
          ),
        );
        final replies = data['replies'];
        if (replies is Map<String, dynamic>) {
          final replyData = replies['data'];
          final replyListing =
              replyData is Map<String, dynamic> ? replyData : null;
          final replyChildren = replyListing?['children'];
          if (replyChildren is List) {
            _walkComments(replyChildren, depth + 1, results);
          }
        }
      }
    }
  }

  String _buildMarkdown(
    SavedItem item,
    List<ThreadComment> comments,
    CommentSort sort,
    int? maxCount,
    int? timeframeDays,
  ) {
    final buffer = StringBuffer();
    buffer.writeln(
      '# Comments for ${item.title.isEmpty ? 'Untitled post' : item.title}',
    );
    buffer.writeln();
    buffer.writeln('- Subreddit: r/${item.subreddit}');
    buffer.writeln('- Permalink: ${item.permalink}');
    buffer.writeln('- Sort: ${_sortValue(sort)}');
    buffer.writeln('- Max count: ${maxCount ?? 'all'}');
    buffer.writeln(
      '- Timeframe: ${timeframeDays == null ? 'all' : 'last $timeframeDays days'}',
    );
    buffer.writeln();
    for (final comment in comments) {
      final indent = '  ' * comment.depth;
      final created =
          comment.createdUtc > 0
              ? DateTime.fromMillisecondsSinceEpoch(
                comment.createdUtc * 1000,
                isUtc: true,
              ).toLocal()
              : null;
      final createdText =
          created == null
              ? 'Unknown'
              : '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
      buffer.writeln(
        '${indent}- **u/${comment.author}** • $createdText • score ${comment.score}',
      );
      final lines =
          comment.body.trim().isEmpty
              ? const ['_No text body provided._']
              : comment.body.trim().split('\n');
      for (final line in lines) {
        buffer.writeln('${indent}  > $line');
      }
      buffer.writeln();
    }
    return buffer.toString().replaceAll('\r\n', '\n');
  }

  String _sortValue(CommentSort sort) {
    switch (sort) {
      case CommentSort.newest:
        return 'new';
      case CommentSort.top:
        return 'top';
      case CommentSort.controversial:
        return 'controversial';
      case CommentSort.best:
      default:
        return 'best';
    }
  }
}

class ThreadComment {
  const ThreadComment({
    required this.author,
    required this.body,
    required this.createdUtc,
    required this.depth,
    required this.score,
    required this.permalink,
  });

  final String author;
  final String body;
  final int createdUtc;
  final int depth;
  final int score;
  final String permalink;
}
