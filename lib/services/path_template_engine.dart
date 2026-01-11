import 'package:path/path.dart' as p;

import '../data/app_database.dart';
import '../data/settings_repository.dart';

class PathTemplateEngine {
  PathTemplateEngine(this.settings);

  final AppSettings settings;

  PathTemplateResult resolve({
    required SavedItem item,
    required MediaAsset asset,
    int mediaIndex = 0,
    String? filenameOverride,
  }) {
    final warnings = <String>[];

    if (settings.downloadRoot.trim().isEmpty) {
      return PathTemplateResult.invalid(
        'Download root is not set.',
      );
    }

    final tokens = _buildTokens(item);
    final template = settings.mediaPathTemplate.trim();
    final relativeDir = _applyTemplate(template, tokens, warnings);
    if (relativeDir.isEmpty) {
      return PathTemplateResult.invalid('Media path template is empty.');
    }

    final root = _normalizeRoot(settings.downloadRoot);
    final directoryPath = _safeJoin(root, relativeDir, warnings);
    if (directoryPath == null) {
      return PathTemplateResult.invalid('Invalid path template.');
    }

    final filename = _buildFilename(asset, mediaIndex, filenameOverride);
    final safeFilename = _sanitizeSegment(filename);
    final filePath = _applyLayout(directoryPath, safeFilename, warnings);

    _warnIfTooLong(filePath, warnings);

    return PathTemplateResult(
      directoryPath: directoryPath,
      filePath: filePath,
      warnings: warnings,
    );
  }

  PathTemplatePreview previewForItem(SavedItem item) {
    final placeholder = MediaAsset(
      id: 0,
      savedItemId: item.id,
      type: 'image',
      sourceUrl: 'https://example.com/media.jpg',
      normalizedUrl: 'https://example.com/media.jpg',
      toolHint: 'none',
      filenameSuggested: null,
      metadataJson: null,
    );
    final result = resolve(item: item, asset: placeholder);
    return PathTemplatePreview(
      directoryPath: result.directoryPath,
      filePath: result.filePath,
      warnings: result.warnings,
      isValid: result.isValid,
      error: result.error,
    );
  }

  String resolveTextRoot() {
    return _resolveRoot(settings.textRoot);
  }

  String resolveCommentsRoot() {
    return _resolveRoot(settings.commentsRoot);
  }

  PathTemplateResult resolveTextPath({
    required SavedItem item,
    required String filename,
  }) {
    return _resolveTextLikePath(
      item: item,
      root: resolveTextRoot(),
      filename: filename,
      emptyError: 'Text export root is not set.',
    );
  }

  PathTemplateResult resolveCommentsPath({
    required SavedItem item,
    required String filename,
  }) {
    return _resolveTextLikePath(
      item: item,
      root: resolveCommentsRoot(),
      filename: filename,
      emptyError: 'Comments export root is not set.',
    );
  }

  Map<String, String> _buildTokens(SavedItem item) {
    final created = _createdDate(item);
    final postId = _extractPostId(item.permalink);
    final commentId = _extractCommentId(item.permalink);
    final titleSlug = _slugify(item.title);
    return {
      'type': item.kind,
      'subreddit': item.subreddit,
      'author': item.author,
      'id': postId.isNotEmpty ? postId : item.id.toString(),
      'comment_id': commentId,
      'yyyy': created.year.toString(),
      'mm': created.month.toString().padLeft(2, '0'),
      'dd': created.day.toString().padLeft(2, '0'),
      'title_slug': titleSlug,
      'nsfw': item.over18 ? 'nsfw' : 'sfw',
      'source': item.source,
    };
  }

  String _applyTemplate(
    String template,
    Map<String, String> tokens,
    List<String> warnings,
  ) {
    var normalized = template.replaceAll('\\', '/');
    if (RegExp(r'^[a-zA-Z]:').hasMatch(normalized)) {
      normalized = normalized.replaceFirst(RegExp(r'^[a-zA-Z]:[\\/]*'), '');
      warnings.add('Template should be relative; drive prefix ignored.');
    }
    normalized = normalized.replaceFirst(RegExp(r'^/+'), '');

    final parts = normalized.split('/');
    final resolved = <String>[];
    for (final raw in parts) {
      if (raw.isEmpty) {
        continue;
      }
      final unsafeRaw = raw == '.' || raw == '..' || raw.contains('..');
      var segment = raw;
      tokens.forEach((key, value) {
        segment = segment.replaceAll('{$key}', value);
      });
      segment = _sanitizeSegment(segment);
      if (unsafeRaw || segment == '.' || segment == '..' || segment.contains('..')) {
        warnings.add('Template contained unsafe path segments.');
        segment = segment.replaceAll('..', '_');
      }
      if (segment.isEmpty) {
        segment = 'unknown';
      }
      resolved.add(segment);
    }
    return resolved.isEmpty ? '' : p.joinAll(resolved);
  }

  String _applyLayout(
    String directoryPath,
    String filename,
    List<String> warnings,
  ) {
    if (settings.mediaLayoutMode == MediaLayoutMode.folderPerMedia) {
      final folderName = _sanitizeSegment(
        p.basenameWithoutExtension(filename),
      );
      if (folderName.isEmpty) {
        warnings.add('Media folder name fallback applied.');
      }
      final safeFolder = folderName.isEmpty ? 'media' : folderName;
      return p.join(directoryPath, safeFolder, filename);
    }
    return p.join(directoryPath, filename);
  }

  PathTemplateResult _resolveTextLikePath({
    required SavedItem item,
    required String root,
    required String filename,
    required String emptyError,
  }) {
    final warnings = <String>[];

    if (settings.downloadRoot.trim().isEmpty) {
      return PathTemplateResult.invalid('Download root is not set.');
    }

    if (root.trim().isEmpty) {
      return PathTemplateResult.invalid(emptyError);
    }

    final tokens = _buildTokens(item);
    final template = settings.mediaPathTemplate.trim();
    final relativeDir = _applyTemplate(template, tokens, warnings);
    if (relativeDir.isEmpty) {
      return PathTemplateResult.invalid('Media path template is empty.');
    }

    final directoryPath = _safeJoin(root, relativeDir, warnings);
    if (directoryPath == null) {
      return PathTemplateResult.invalid('Invalid path template.');
    }

    final safeFilename = _sanitizeSegment(filename);
    final resolvedFilename = safeFilename.isEmpty ? 'export.md' : safeFilename;
    final filePath = p.join(directoryPath, resolvedFilename);

    _warnIfTooLong(filePath, warnings);

    return PathTemplateResult(
      directoryPath: directoryPath,
      filePath: filePath,
      warnings: warnings,
    );
  }

  String _buildFilename(
    MediaAsset asset,
    int mediaIndex,
    String? override,
  ) {
    if (override != null && override.trim().isNotEmpty) {
      return override.trim();
    }
    final url = asset.filenameSuggested?.trim().isNotEmpty == true
        ? asset.filenameSuggested!
        : asset.normalizedUrl.isNotEmpty
            ? asset.normalizedUrl
            : asset.sourceUrl;
    final parsed = Uri.tryParse(url);
    final path = parsed?.path ?? url;
    final base = p.basename(path);
    if (base.isNotEmpty && base.contains('.')) {
      return base;
    }
    return 'media-${asset.id == 0 ? mediaIndex + 1 : asset.id}';
  }

  String _sanitizeSegment(String value) {
    var sanitized = value
        .replaceAll(RegExp(r'[<>:"/\\\\|?*]'), '_')
        .replaceAll(RegExp(r'[\x00-\x1F]'), '')
        .trim();
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');
    sanitized = sanitized.replaceAll('..', '_');
    if (sanitized.isEmpty) {
      return 'unknown';
    }
    final lower = sanitized.toLowerCase();
    if (_windowsReserved.contains(lower)) {
      sanitized = '${sanitized}_';
    }
    return sanitized;
  }

  String _slugify(String value) {
    final lower = value.toLowerCase();
    var slug = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    slug = slug.replaceAll(RegExp(r'-+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) {
      return 'untitled';
    }
    return slug;
  }

  DateTime _createdDate(SavedItem item) {
    if (item.createdUtc <= 0) {
      return DateTime.now();
    }
    return DateTime.fromMillisecondsSinceEpoch(
      item.createdUtc * 1000,
      isUtc: true,
    ).toLocal();
  }

  String _extractPostId(String permalink) {
    final match = RegExp(r'/comments/([a-z0-9]+)/', caseSensitive: false)
        .firstMatch(permalink);
    return match?.group(1) ?? '';
  }

  String _extractCommentId(String permalink) {
    final match = RegExp(
      r'/comments/[a-z0-9]+/[^/]+/([a-z0-9]+)/?',
      caseSensitive: false,
    ).firstMatch(permalink);
    return match?.group(1) ?? '';
  }

  String _normalizeRoot(String root) {
    return p.normalize(root.trim());
  }

  String _resolveRoot(String root) {
    final base = _normalizeRoot(settings.downloadRoot);
    if (root.trim().isEmpty) {
      return base;
    }
    final candidate = p.normalize(root.trim());
    if (p.isAbsolute(candidate)) {
      return candidate;
    }
    return p.normalize(p.join(base, candidate));
  }

  String? _safeJoin(
    String root,
    String relative,
    List<String> warnings,
  ) {
    final joined = p.normalize(p.join(root, relative));
    if (!p.isWithin(root, joined) && joined != root) {
      warnings.add('Template resolved outside of download root.');
      return null;
    }
    return joined;
  }

  void _warnIfTooLong(String path, List<String> warnings) {
    if (path.length > 240) {
      warnings.add('Path length exceeds 240 characters.');
    }
  }
}

class PathTemplateResult {
  PathTemplateResult({
    required this.directoryPath,
    required this.filePath,
    required this.warnings,
  })  : isValid = true,
        error = null;

  PathTemplateResult.invalid(this.error)
      : directoryPath = '',
        filePath = '',
        warnings = const [],
        isValid = false;

  final String directoryPath;
  final String filePath;
  final List<String> warnings;
  final bool isValid;
  final String? error;
}

class PathTemplatePreview {
  const PathTemplatePreview({
    required this.directoryPath,
    required this.filePath,
    required this.warnings,
    required this.isValid,
    required this.error,
  });

  final String directoryPath;
  final String filePath;
  final List<String> warnings;
  final bool isValid;
  final String? error;
}

const _windowsReserved = {
  'con',
  'prn',
  'aux',
  'nul',
  'com1',
  'com2',
  'com3',
  'com4',
  'com5',
  'com6',
  'com7',
  'com8',
  'com9',
  'lpt1',
  'lpt2',
  'lpt3',
  'lpt4',
  'lpt5',
  'lpt6',
  'lpt7',
  'lpt8',
  'lpt9',
};
