import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_database.dart';
import '../../data/library_repository.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repository)
    : super(
        const LibraryState(
          items: [],
          subreddits: [],
          searchQuery: '',
          includeSubreddit: null,
          excludeSubreddit: null,
          kindFilter: LibraryKindFilter.all,
          showNsfw: true,
          hasIndexed: false,
        ),
      ) {
    _itemsSubscription = _repository.watchAll().listen((items) {
      _allItems = items;
      _applyFilters();
    });
    _subredditSubscription = _repository.watchSubreddits().listen((subs) {
      _subreddits = subs;
      _applyFilters();
    });
  }

  final LibraryRepository _repository;
  late final StreamSubscription<List<SavedItem>> _itemsSubscription;
  late final StreamSubscription<List<String>> _subredditSubscription;
  List<SavedItem> _allItems = [];
  List<String> _subreddits = [];

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilters();
  }

  void updateIncludeSubreddit(String? subreddit) {
    emit(state.copyWith(includeSubreddit: subreddit));
    _applyFilters();
  }

  void updateExcludeSubreddit(String? subreddit) {
    emit(state.copyWith(excludeSubreddit: subreddit));
    _applyFilters();
  }

  void updateKindFilter(LibraryKindFilter filter) {
    emit(state.copyWith(kindFilter: filter));
    _applyFilters();
  }

  void toggleShowNsfw(bool value) {
    emit(state.copyWith(showNsfw: value));
    _applyFilters();
  }

  void _applyFilters() {
    final query = state.searchQuery.trim().toLowerCase();
    var items = List<SavedItem>.from(_allItems);

    if (query.isNotEmpty) {
      items =
          items.where((item) {
            return item.title.toLowerCase().contains(query) ||
                item.permalink.toLowerCase().contains(query) ||
                item.subreddit.toLowerCase().contains(query) ||
                item.author.toLowerCase().contains(query);
          }).toList();
    }

    if (!state.showNsfw) {
      items = items.where((item) => !item.over18).toList();
    }

    if (state.kindFilter != LibraryKindFilter.all) {
      final kind = state.kindFilter.name;
      items = items.where((item) => item.kind == kind).toList();
    }

    if (state.includeSubreddit != null) {
      items =
          items
              .where((item) => item.subreddit == state.includeSubreddit)
              .toList();
    }

    if (state.excludeSubreddit != null) {
      items =
          items
              .where((item) => item.subreddit != state.excludeSubreddit)
              .toList();
    }

    emit(
      state.copyWith(
        items: items,
        subreddits: _subreddits,
        hasIndexed: _allItems.isNotEmpty,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _itemsSubscription.cancel();
    await _subredditSubscription.cancel();
    return super.close();
  }
}

enum LibraryKindFilter { all, post, comment }

class LibraryState extends Equatable {
  const LibraryState({
    required this.items,
    required this.subreddits,
    required this.searchQuery,
    required this.includeSubreddit,
    required this.excludeSubreddit,
    required this.kindFilter,
    required this.showNsfw,
    required this.hasIndexed,
  });

  final List<SavedItem> items;
  final List<String> subreddits;
  final String searchQuery;
  final String? includeSubreddit;
  final String? excludeSubreddit;
  final LibraryKindFilter kindFilter;
  final bool showNsfw;
  final bool hasIndexed;

  static const _unset = Object();

  LibraryState copyWith({
    List<SavedItem>? items,
    List<String>? subreddits,
    String? searchQuery,
    Object? includeSubreddit = _unset,
    Object? excludeSubreddit = _unset,
    LibraryKindFilter? kindFilter,
    bool? showNsfw,
    bool? hasIndexed,
  }) {
    return LibraryState(
      items: items ?? this.items,
      subreddits: subreddits ?? this.subreddits,
      searchQuery: searchQuery ?? this.searchQuery,
      includeSubreddit:
          includeSubreddit == _unset
              ? this.includeSubreddit
              : includeSubreddit as String?,
      excludeSubreddit:
          excludeSubreddit == _unset
              ? this.excludeSubreddit
              : excludeSubreddit as String?,
      kindFilter: kindFilter ?? this.kindFilter,
      showNsfw: showNsfw ?? this.showNsfw,
      hasIndexed: hasIndexed ?? this.hasIndexed,
    );
  }

  @override
  List<Object?> get props => [
    items,
    subreddits,
    searchQuery,
    includeSubreddit,
    excludeSubreddit,
    kindFilter,
    showNsfw,
    hasIndexed,
  ];
}
