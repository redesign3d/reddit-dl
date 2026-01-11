import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'permalink_utils.dart';

class SavedListingItem {
  const SavedListingItem({
    required this.permalink,
    required this.kindHint,
  });

  final String permalink;
  final ListingKindHint kindHint;
}

class SavedListingPage {
  const SavedListingPage({
    required this.items,
    required this.nextPage,
  });

  final List<SavedListingItem> items;
  final String? nextPage;
}

enum ListingKindHint { post, comment, unknown }

class RedditSavedListingParser {
  SavedListingPage parse(String html) {
    final document = html_parser.parse(html);
    final things = document.querySelectorAll('.thing');
    final items = <SavedListingItem>[];
    final seen = <String>{};

    for (final thing in things) {
      final rawPermalink = thing.attributes['data-permalink'] ??
          thing.querySelector('a.comments')?.attributes['href'] ??
          thing.querySelector('a.bylink')?.attributes['href'] ??
          thing.querySelector('a.title')?.attributes['href'] ??
          '';
      final permalink = normalizePermalink(rawPermalink);
      if (permalink.isEmpty || seen.contains(permalink)) {
        continue;
      }
      seen.add(permalink);
      items.add(SavedListingItem(
        permalink: permalink,
        kindHint: _inferKind(thing.attributes),
      ));
    }

    final nextLink = document.querySelector('span.next-button a');
    final nextHref = nextLink?.attributes['href'];
    final nextPage = _normalizeNextPage(nextHref);

    return SavedListingPage(items: items, nextPage: nextPage);
  }

  String? parseUsername(String html) {
    final document = html_parser.parse(html);
    final headerAnchor =
        document.querySelector('#header-bottom-right a[href*=\"/user/\"]');
    final username = _usernameFromAnchor(headerAnchor);
    if (username != null) {
      return username;
    }

    for (final anchor in document.querySelectorAll('a[href*=\"/user/\"]')) {
      final candidate = _usernameFromAnchor(anchor);
      if (candidate != null) {
        return candidate;
      }
    }
    return null;
  }

  String? _usernameFromAnchor(dom.Element? anchor) {
    if (anchor == null) {
      return null;
    }
    final text = anchor.text.trim();
    if (text.isNotEmpty) {
      return text;
    }
    final href = anchor.attributes['href'];
    if (href == null) {
      return null;
    }
    final match = RegExp(r'/user/([^/]+)/?').firstMatch(href);
    return match?.group(1);
  }

  ListingKindHint _inferKind(Map<String, String> attributes) {
    final fullname = attributes['data-fullname'];
    if (fullname != null) {
      if (fullname.startsWith('t1_')) {
        return ListingKindHint.comment;
      }
      if (fullname.startsWith('t3_')) {
        return ListingKindHint.post;
      }
    }
    final dataType = attributes['data-type'];
    if (dataType == 'comment') {
      return ListingKindHint.comment;
    }
    if (dataType == 'link') {
      return ListingKindHint.post;
    }
    return ListingKindHint.unknown;
  }

  String? _normalizeNextPage(String? href) {
    if (href == null || href.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(href);
    if (parsed == null) {
      return null;
    }
    if (parsed.hasScheme) {
      return parsed.toString();
    }
    if (href.startsWith('/')) {
      return 'https://old.reddit.com$href';
    }
    return 'https://old.reddit.com/$href';
  }
}
