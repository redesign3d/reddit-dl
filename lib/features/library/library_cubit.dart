import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(const LibraryState(items: [], hasIndexed: false));

  void addItems(List<LibraryItem> items) {
    final merged = <String, LibraryItem>{
      for (final item in state.items) item.permalink: item,
    };
    for (final item in items) {
      merged[item.permalink] = item;
    }
    final mergedList = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    emit(state.copyWith(
      items: mergedList,
      hasIndexed: true,
    ));
  }

  void clear() {
    emit(const LibraryState(items: [], hasIndexed: false));
  }
}

enum SavedKind { post, comment }

enum LibrarySource { zip, sync }

class LibraryItem extends Equatable {
  const LibraryItem({
    required this.permalink,
    required this.title,
    required this.subreddit,
    required this.author,
    required this.createdAt,
    required this.isNsfw,
    required this.kind,
    required this.source,
  });

  final String permalink;
  final String title;
  final String subreddit;
  final String author;
  final DateTime createdAt;
  final bool isNsfw;
  final SavedKind kind;
  final LibrarySource source;

  @override
  List<Object?> get props => [
        permalink,
        title,
        subreddit,
        author,
        createdAt,
        isNsfw,
        kind,
        source,
      ];
}

class LibraryState extends Equatable {
  const LibraryState({
    required this.items,
    required this.hasIndexed,
  });

  final List<LibraryItem> items;
  final bool hasIndexed;

  Set<String> get subreddits =>
      items.map((item) => item.subreddit).toSet();

  LibraryState copyWith({
    List<LibraryItem>? items,
    bool? hasIndexed,
  }) {
    return LibraryState(
      items: items ?? this.items,
      hasIndexed: hasIndexed ?? this.hasIndexed,
    );
  }

  @override
  List<Object?> get props => [items, hasIndexed];
}
