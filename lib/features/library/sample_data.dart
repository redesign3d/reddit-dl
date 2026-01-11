import 'library_cubit.dart';

List<LibraryItem> sampleImportItems(DateTime now) {
  return [
    LibraryItem(
      permalink: 'https://reddit.com/r/spaceporn/comments/abc123/starfield',
      title: 'Hubble composite with real-time color grading notes',
      subreddit: 'spaceporn',
      author: 'nebula_archivist',
      createdAt: now.subtract(const Duration(days: 40)),
      isNsfw: false,
      kind: SavedKind.post,
      source: LibrarySource.zip,
    ),
    LibraryItem(
      permalink: 'https://reddit.com/r/woodworking/comments/def456/jig',
      title: 'My compact mitre sled build log (with templates)',
      subreddit: 'woodworking',
      author: 'grainchaser',
      createdAt: now.subtract(const Duration(days: 12)),
      isNsfw: false,
      kind: SavedKind.post,
      source: LibrarySource.zip,
    ),
    LibraryItem(
      permalink: 'https://reddit.com/r/printmaking/comments/ghi789/inktober',
      title: 'Layered risograph palette breakdown',
      subreddit: 'printmaking',
      author: 'ink_habits',
      createdAt: now.subtract(const Duration(days: 4)),
      isNsfw: false,
      kind: SavedKind.comment,
      source: LibrarySource.zip,
    ),
  ];
}

List<LibraryItem> sampleSyncItems(DateTime now) {
  return [
    LibraryItem(
      permalink: 'https://reddit.com/r/analog/comments/jkl012/scan',
      title: 'Medium format scan workflow checklist',
      subreddit: 'analog',
      author: 'fixer_lab',
      createdAt: now.subtract(const Duration(days: 1)),
      isNsfw: false,
      kind: SavedKind.post,
      source: LibrarySource.sync,
    ),
    LibraryItem(
      permalink: 'https://reddit.com/r/cyberpunk/comments/mno345/city',
      title: 'City ambience mix for late-night renders',
      subreddit: 'cyberpunk',
      author: 'glowdistrict',
      createdAt: now.subtract(const Duration(hours: 12)),
      isNsfw: true,
      kind: SavedKind.post,
      source: LibrarySource.sync,
    ),
  ];
}
