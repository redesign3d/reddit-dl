import 'package:flutter_test/flutter_test.dart';

import 'package:reddit_dl/features/sync/reddit_saved_listing_parser.dart';

void main() {
  test('parses saved listing and next page link', () {
    const html = '''
    <html>
      <body>
        <div id="header-bottom-right">
          <span class="user">
            <a href="https://www.reddit.com/user/testuser/">testuser</a>
          </span>
        </div>
        <div class="thing" data-fullname="t3_abc" data-permalink="/r/test/comments/abc/title/"></div>
        <div class="thing" data-fullname="t1_def" data-permalink="https://old.reddit.com/r/test/comments/abc/title/def/"></div>
        <span class="next-button">
          <a href="/user/testuser/saved/?count=25&amp;after=t3_abc">next</a>
        </span>
      </body>
    </html>
    ''';

    final parser = RedditSavedListingParser();
    final page = parser.parse(html);

    expect(page.items, hasLength(2));
    expect(page.items.first.kindHint, ListingKindHint.post);
    expect(page.items.last.kindHint, ListingKindHint.comment);
    expect(
      page.items.first.permalink,
      'https://www.reddit.com/r/test/comments/abc/title',
    );
    expect(
      page.nextPage,
      'https://old.reddit.com/user/testuser/saved/?count=25&after=t3_abc',
    );
    expect(parser.parseUsername(html), 'testuser');
  });
}
