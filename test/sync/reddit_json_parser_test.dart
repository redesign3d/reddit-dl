import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/features/sync/reddit_json_parser.dart';
import 'package:reddit_dl/features/sync/reddit_saved_listing_parser.dart';

void main() {
  final parser = RedditJsonParser();

  test('parses image post json', () {
    final jsonData = jsonDecode(_imageJson);
    final result = parser.parse(
      jsonData,
      permalink: 'https://www.reddit.com/r/pics/comments/abc/title',
      hint: ListingKindHint.post,
    );
    expect(result, isNotNull);
    expect(result!.kind, 'post');
    expect(result.subreddit, 'pics');
    expect(result.media.where((asset) => asset.type == 'image').length, 2);
  });

  test('parses gallery post json', () {
    final jsonData = jsonDecode(_galleryJson);
    final result = parser.parse(
      jsonData,
      permalink: 'https://www.reddit.com/r/test/comments/gal/gallery',
      hint: ListingKindHint.post,
    );
    expect(result, isNotNull);
    expect(result!.media.where((asset) => asset.type == 'gallery').length, 1);
  });

  test('parses video post json', () {
    final jsonData = jsonDecode(_videoJson);
    final result = parser.parse(
      jsonData,
      permalink: 'https://www.reddit.com/r/test/comments/vid/video',
      hint: ListingKindHint.post,
    );
    expect(result, isNotNull);
    expect(result!.media.where((asset) => asset.type == 'video').length, 1);
  });
}

const _imageJson = '''
[
  {
    "data": {
      "children": [
        {
          "kind": "t3",
          "data": {
            "subreddit": "pics",
            "author": "alice",
            "created_utc": 1700000000,
            "title": "Test Image",
            "selftext": "",
            "over_18": false,
            "post_hint": "image",
            "url_overridden_by_dest": "https://i.redd.it/abc.jpg",
            "preview": {
              "images": [
                { "source": { "url": "https://preview.redd.it/abc.jpg?width=640&amp;auto=webp" } }
              ]
            }
          }
        }
      ]
    }
  },
  { "data": { "children": [] } }
]
''';

const _galleryJson = '''
[
  {
    "data": {
      "children": [
        {
          "kind": "t3",
          "data": {
            "subreddit": "test",
            "author": "bob",
            "created_utc": 1700000100,
            "title": "Gallery",
            "selftext": "",
            "gallery_data": {
              "items": [ { "media_id": "m1" } ]
            },
            "media_metadata": {
              "m1": { "s": { "u": "https://preview.redd.it/gallery1.jpg" } }
            }
          }
        }
      ]
    }
  },
  { "data": { "children": [] } }
]
''';

const _videoJson = '''
[
  {
    "data": {
      "children": [
        {
          "kind": "t3",
          "data": {
            "subreddit": "test",
            "author": "charlie",
            "created_utc": 1700000200,
            "title": "Video",
            "selftext": "",
            "media": {
              "reddit_video": {
                "fallback_url": "https://v.redd.it/video/DASH_720.mp4"
              }
            }
          }
        }
      ]
    }
  },
  { "data": { "children": [] } }
]
''';
