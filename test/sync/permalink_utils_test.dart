import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/features/sync/permalink_utils.dart';

void main() {
  test('normalizes reddit permalinks', () {
    expect(
      normalizePermalink('https://old.reddit.com/r/test/comments/abc/title/'),
      'https://www.reddit.com/r/test/comments/abc/title',
    );
    expect(
      normalizePermalink('/r/test/comments/abc/title/'),
      'https://www.reddit.com/r/test/comments/abc/title',
    );
    expect(
      normalizePermalink(
        'https://www.reddit.com/r/test/comments/abc/title/.json',
      ),
      'https://www.reddit.com/r/test/comments/abc/title',
    );
  });
}
