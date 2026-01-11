import 'package:html/parser.dart' as html_parser;

import 'reddit_saved_listing_parser.dart';

class ResolvedItem {
  const ResolvedItem({
    required this.permalink,
    required this.kind,
    required this.subreddit,
    required this.author,
    required this.createdUtc,
    required this.title,
    required this.body,
    required this.over18,
    required this.media,
    required this.status,
  });

  final String permalink;
  final String kind;
  final String subreddit;
  final String author;
  final int createdUtc;
  final String title;
  final String body;
  final bool over18;
  final List<ResolvedMediaAsset> media;
  final ResolutionStatus status;
}

class ResolvedMediaAsset {
  const ResolvedMediaAsset({
    required this.type,
    required this.sourceUrl,
    required this.normalizedUrl,
    required this.toolHint,
    this.metadata,
  });

  final String type;
  final String sourceUrl;
  final String normalizedUrl;
  final String toolHint;
  final Map<String, dynamic>? metadata;
}

enum ResolutionStatus { ok, partial, failed }

class RedditJsonParser {
  ResolvedItem? parse(
    dynamic json, {
    required String permalink,
    ListingKindHint hint = ListingKindHint.unknown,
  }) {
    final children = _extractChildren(json);
    if (children.isEmpty) {
      return null;
    }

    final selected = _pickChild(children, hint);
    if (selected == null) {
      return null;
    }

    final data = selected['data'] as Map<String, dynamic>? ?? {};
    final kind = _kindFrom(selected['kind'] as String?);
    final subreddit = data['subreddit'] as String? ?? '';
    final author = data['author'] as String? ?? 'unknown';
    final createdUtc = (data['created_utc'] as num?)?.toInt() ?? 0;
    final title = kind == 'comment'
        ? (data['link_title'] as String? ?? '')
        : (data['title'] as String? ?? '');
    final body = kind == 'comment'
        ? (data['body'] as String? ?? '')
        : (data['selftext'] as String? ?? '');
    final over18 = data['over_18'] as bool? ?? false;

    final media = kind == 'post' ? _extractMedia(data) : <ResolvedMediaAsset>[];
    final status = _resolutionStatus(subreddit, author, createdUtc, kind);

    return ResolvedItem(
      permalink: permalink,
      kind: kind,
      subreddit: subreddit,
      author: author,
      createdUtc: createdUtc,
      title: title,
      body: body,
      over18: over18,
      media: media,
      status: status,
    );
  }

  List<Map<String, dynamic>> _extractChildren(dynamic json) {
    final listings = <dynamic>[];
    if (json is List) {
      listings.addAll(json);
    } else if (json is Map<String, dynamic>) {
      listings.add(json);
    }

    final children = <Map<String, dynamic>>[];
    for (final listing in listings) {
      final data = listing is Map<String, dynamic> ? listing['data'] : null;
      final listingData = data is Map<String, dynamic> ? data : null;
      final childList = listingData?['children'];
      if (childList is List) {
        for (final child in childList) {
          if (child is Map<String, dynamic>) {
            children.add(child);
          }
        }
      }
    }
    return children;
  }

  Map<String, dynamic>? _pickChild(
    List<Map<String, dynamic>> children,
    ListingKindHint hint,
  ) {
    if (hint == ListingKindHint.comment) {
      return children.firstWhere(
        (child) => child['kind'] == 't1',
        orElse: () => children.first,
      );
    }
    if (hint == ListingKindHint.post) {
      return children.firstWhere(
        (child) => child['kind'] == 't3',
        orElse: () => children.first,
      );
    }
    return children.firstWhere(
      (child) => child['kind'] == 't3',
      orElse: () => children.first,
    );
  }

  String _kindFrom(String? kind) {
    if (kind == 't1') {
      return 'comment';
    }
    return 'post';
  }

  ResolutionStatus _resolutionStatus(
    String subreddit,
    String author,
    int createdUtc,
    String kind,
  ) {
    if (subreddit.isEmpty || author.isEmpty || createdUtc <= 0) {
      return ResolutionStatus.partial;
    }
    if (kind.isEmpty) {
      return ResolutionStatus.partial;
    }
    return ResolutionStatus.ok;
  }

  List<ResolvedMediaAsset> _extractMedia(Map<String, dynamic> data) {
    final assets = <ResolvedMediaAsset>[];
    final seen = <String>{};

    void addAsset(
      String type,
      String? url, {
      Map<String, dynamic>? metadata,
      String toolHint = 'none',
    }) {
      if (url == null || url.isEmpty) {
        return;
      }
      final decoded = _decodeHtml(url);
      final normalized = _normalizeMediaUrl(decoded);
      if (normalized.isEmpty || seen.contains(normalized)) {
        return;
      }
      seen.add(normalized);
      assets.add(
        ResolvedMediaAsset(
          type: type,
          sourceUrl: decoded,
          normalizedUrl: normalized,
          toolHint: toolHint,
          metadata: metadata,
        ),
      );
    }

    final urlOverride = data['url_overridden_by_dest'] as String?;
    final postHint = data['post_hint'] as String?;
    if (urlOverride != null) {
      if (_isImage(urlOverride) || postHint == 'image') {
        addAsset('image', urlOverride);
      } else if (_isGif(urlOverride)) {
        addAsset('gif', urlOverride);
      } else if (postHint == 'link' && !_isRedditUrl(urlOverride)) {
        addAsset(
          'external',
          urlOverride,
          toolHint: _externalToolHint(urlOverride),
        );
      }
    }

    final preview = data['preview'];
    if (preview is Map<String, dynamic>) {
      final images = preview['images'];
      if (images is List) {
        for (final image in images) {
          if (image is Map<String, dynamic>) {
            final source = image['source'];
            if (source is Map<String, dynamic>) {
              addAsset('image', source['url'] as String?);
            }
            final variants = image['variants'];
            if (variants is Map<String, dynamic>) {
              final gif = variants['gif'];
              if (gif is Map<String, dynamic>) {
                final source = gif['source'];
                if (source is Map<String, dynamic>) {
                  addAsset('gif', source['url'] as String?);
                }
              }
              final mp4 = variants['mp4'];
              if (mp4 is Map<String, dynamic>) {
                final source = mp4['source'];
                if (source is Map<String, dynamic>) {
                  addAsset('gif', source['url'] as String?);
                }
              }
            }
          }
        }
      }
      final videoPreview = preview['reddit_video_preview'];
      if (videoPreview is Map<String, dynamic>) {
        addAsset('gif', videoPreview['fallback_url'] as String?);
      }
    }

    final galleryData = data['gallery_data'];
    final mediaMetadata = data['media_metadata'];
    if (galleryData is Map<String, dynamic> &&
        mediaMetadata is Map<String, dynamic>) {
      final items = galleryData['items'];
      if (items is List) {
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final mediaId = item['media_id'];
            final meta = mediaMetadata[mediaId];
            if (meta is Map<String, dynamic>) {
              final source = meta['s'];
              if (source is Map<String, dynamic>) {
                addAsset(
                  'gallery',
                  source['u'] as String?,
                  metadata: {'media_id': mediaId},
                );
              }
            }
          }
        }
      }
    }

    final media = data['media'];
    final secureMedia = data['secure_media'];
    final video = _redditVideoFrom(media) ?? _redditVideoFrom(secureMedia);
    if (video != null) {
      final metadata = <String, dynamic>{};
      final fallback = video['fallback_url'] as String?;
      final dash = video['dash_url'] as String?;
      final hls = video['hls_url'] as String?;
      final isGif = video['is_gif'] as bool?;
      if (fallback != null) {
        metadata['fallback_url'] = fallback;
      }
      if (dash != null) {
        metadata['dash_url'] = dash;
      }
      if (hls != null) {
        metadata['hls_url'] = hls;
      }
      if (isGif != null) {
        metadata['is_gif'] = isGif;
      }
      addAsset(
        'video',
        fallback,
        metadata: metadata.isEmpty ? null : metadata,
      );
    }

    return assets;
  }

  Map<String, dynamic>? _redditVideoFrom(dynamic media) {
    if (media is Map<String, dynamic>) {
      final video = media['reddit_video'];
      if (video is Map<String, dynamic>) {
        return video;
      }
    }
    return null;
  }

  bool _isImage(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp');
  }

  bool _isGif(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.gif') ||
        lower.contains('.gifv') ||
        lower.contains('.mp4');
  }

  bool _isRedditUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('reddit.com') || lower.contains('redd.it');
  }

  String _externalToolHint(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (_videoDomains.any((domain) => host.contains(domain))) {
      return 'ytdlp';
    }
    return 'gallerydl';
  }

  String _normalizeMediaUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) {
      return url;
    }
    return parsed.replace(fragment: '').toString();
  }

  String _decodeHtml(String value) {
    return html_parser.parseFragment(value).text ?? '';
  }
}

const _videoDomains = [
  'youtube.com',
  'youtu.be',
  'vimeo.com',
  'tiktok.com',
  'twitch.tv',
  'streamable.com',
];
