import 'dart:io';

import '../../data/app_database.dart';
import '../../data/settings_repository.dart';
import '../path_template_engine.dart';
import 'export_result.dart';

class TextPostMarkdownExporter {
  Future<ExportResult> export({
    required SavedItem item,
    required PathTemplateEngine engine,
    required OverwritePolicy policy,
  }) async {
    if (item.kind != 'post') {
      return ExportResult.skipped('Not a post.', '');
    }
    if ((item.bodyMarkdown ?? '').trim().isEmpty && item.title.trim().isEmpty) {
      return ExportResult.skipped('No text content.', '');
    }

    final pathResult = engine.resolveTextPath(
      item: item,
      filename: 'post.md',
    );
    if (!pathResult.isValid) {
      return ExportResult.failed(pathResult.error ?? 'Invalid path.', '');
    }

    final targetFile = File(pathResult.filePath);
    if (await targetFile.exists()) {
      if (policy == OverwritePolicy.skipIfExists) {
        return ExportResult.skipped('File exists.', targetFile.path);
      }
      return ExportResult.skipped('Unable to determine newer export.', targetFile.path);
    }

    if (!await targetFile.parent.exists()) {
      await targetFile.parent.create(recursive: true);
    }

    final content = _buildMarkdown(item);
    await targetFile.writeAsString(content);
    return ExportResult.completed(targetFile.path);
  }

  String _buildMarkdown(SavedItem item) {
    final created = item.createdUtc > 0
        ? DateTime.fromMillisecondsSinceEpoch(item.createdUtc * 1000, isUtc: true)
            .toLocal()
        : null;
    final createdText = created == null
        ? 'Unknown'
        : '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
    final buffer = StringBuffer();
    buffer.writeln('# ${item.title.isEmpty ? 'Untitled post' : item.title}');
    buffer.writeln();
    buffer.writeln('- Subreddit: r/${item.subreddit}');
    buffer.writeln('- Author: u/${item.author}');
    buffer.writeln('- Created: $createdText');
    buffer.writeln('- Permalink: ${item.permalink}');
    buffer.writeln('- Source: ${item.source}');
    buffer.writeln('- NSFW: ${item.over18 ? 'yes' : 'no'}');
    buffer.writeln();
    if ((item.bodyMarkdown ?? '').trim().isNotEmpty) {
      buffer.writeln(item.bodyMarkdown!.trim());
    } else {
      buffer.writeln('_No text body provided._');
    }
    buffer.writeln();
    return buffer.toString().replaceAll('\r\n', '\n');
  }
}
