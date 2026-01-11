import 'dart:io';

import '../../data/app_database.dart';
import '../../data/settings_repository.dart';
import '../path_template_engine.dart';
import 'export_result.dart';

class SavedCommentMarkdownExporter {
  Future<ExportResult> export({
    required SavedItem item,
    required PathTemplateEngine engine,
    required OverwritePolicy policy,
  }) async {
    if (item.kind != 'comment') {
      return ExportResult.skipped('Not a comment.', '');
    }
    if ((item.bodyMarkdown ?? '').trim().isEmpty) {
      return ExportResult.skipped('No comment body.', '');
    }

    final pathResult = engine.resolveCommentsPath(
      item: item,
      filename: 'comment.md',
    );
    if (!pathResult.isValid) {
      return ExportResult.failed(pathResult.error ?? 'Invalid path.', '');
    }

    final targetFile = File(pathResult.filePath);
    if (await targetFile.exists()) {
      if (policy == OverwritePolicy.skipIfExists) {
        return ExportResult.skipped('File exists.', targetFile.path);
      }
      return ExportResult.skipped(
        'Unable to determine newer export.',
        targetFile.path,
      );
    }

    if (!await targetFile.parent.exists()) {
      await targetFile.parent.create(recursive: true);
    }

    final content = _buildMarkdown(item);
    await targetFile.writeAsString(content);
    return ExportResult.completed(targetFile.path);
  }

  String _buildMarkdown(SavedItem item) {
    final created =
        item.createdUtc > 0
            ? DateTime.fromMillisecondsSinceEpoch(
              item.createdUtc * 1000,
              isUtc: true,
            ).toLocal()
            : null;
    final createdText =
        created == null
            ? 'Unknown'
            : '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
    final buffer = StringBuffer();
    buffer.writeln('# Comment by u/${item.author}');
    buffer.writeln();
    buffer.writeln('- Subreddit: r/${item.subreddit}');
    buffer.writeln('- Created: $createdText');
    buffer.writeln('- Permalink: ${item.permalink}');
    buffer.writeln('- Source: ${item.source}');
    buffer.writeln('- NSFW: ${item.over18 ? 'yes' : 'no'}');
    buffer.writeln();
    buffer.writeln(item.bodyMarkdown!.trim());
    buffer.writeln();
    return buffer.toString().replaceAll('\r\n', '\n');
  }
}
