import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_database.dart';
import '../../data/library_repository.dart';

typedef LibraryKindFilter = LibraryItemKind;

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repository)
    : super(
        const LibraryState(
          items: [],
          subreddits: [],
          searchQuery: '',
          includeSubreddit: null,
          excludeSubreddit: null,
          kindFilter: LibraryItemKind.all,
          showNsfw: true,
          resolutionFilter: LibraryResolutionFilter.all,
          pageSize: 50,
          pageIndex: 0,
          totalCount: 0,
          isPageLoading: true,
          selectedItemId: null,
          hasIndexed: false,
        ),
      ) {
    _subredditSubscription = _repository.watchSubreddits().listen((subs) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(subreddits: subs));
    });
    _reloadPage(resetPage: true);
  }

  final LibraryRepository _repository;
  StreamSubscription<List<SavedItem>>? _itemsSubscription;
  late final StreamSubscription<List<String>> _subredditSubscription;
  Timer? _searchDebounce;
  int _activeQueryToken = 0;

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _reloadPage(resetPage: true);
    });
  }

  void updateIncludeSubreddit(String? subreddit) {
    emit(state.copyWith(includeSubreddit: subreddit));
    _reloadPage(resetPage: true);
  }

  void updateExcludeSubreddit(String? subreddit) {
    emit(state.copyWith(excludeSubreddit: subreddit));
    _reloadPage(resetPage: true);
  }

  void updateKindFilter(LibraryItemKind filter) {
    emit(state.copyWith(kindFilter: filter));
    _reloadPage(resetPage: true);
  }

  void toggleShowNsfw(bool value) {
    emit(state.copyWith(showNsfw: value));
    _reloadPage(resetPage: true);
  }

  void updateResolutionFilter(LibraryResolutionFilter filter) {
    emit(state.copyWith(resolutionFilter: filter));
    _reloadPage(resetPage: true);
  }

  void selectItem(int? itemId) {
    emit(state.copyWith(selectedItemId: itemId));
  }

  void goToNextPage() {
    if (!state.hasNextPage || state.isPageLoading) {
      return;
    }
    _reloadPage(pageIndex: state.pageIndex + 1);
  }

  void goToPreviousPage() {
    if (!state.hasPreviousPage || state.isPageLoading) {
      return;
    }
    _reloadPage(pageIndex: state.pageIndex - 1);
  }

  void _reloadPage({bool resetPage = false, int? pageIndex}) {
    final targetPage = resetPage ? 0 : (pageIndex ?? state.pageIndex);
    final safePage = targetPage < 0 ? 0 : targetPage;
    final filters = _currentFilters();
    final token = ++_activeQueryToken;

    emit(state.copyWith(pageIndex: safePage, isPageLoading: true));
    unawaited(
      _subscribeToPage(filters: filters, pageIndex: safePage, token: token),
    );
    unawaited(_refreshCounts(filters: filters, token: token));
  }

  Future<void> _subscribeToPage({
    required LibraryQueryFilters filters,
    required int pageIndex,
    required int token,
  }) async {
    await _itemsSubscription?.cancel();
    if (token != _activeQueryToken || isClosed) {
      return;
    }

    final offset = pageIndex * state.pageSize;
    _itemsSubscription = _repository
        .watchLibraryPage(
          filters: filters,
          limit: state.pageSize,
          offset: offset,
        )
        .listen((items) {
          if (token != _activeQueryToken || isClosed) {
            return;
          }
          final nextSelectedId = _resolveSelectedItemId(items);
          emit(
            state.copyWith(
              items: items,
              isPageLoading: false,
              selectedItemId: nextSelectedId,
            ),
          );
        });
  }

  Future<void> _refreshCounts({
    required LibraryQueryFilters filters,
    required int token,
  }) async {
    final totalCount = await _repository.countLibrary(filters);
    final indexedCount = await _repository.countLibrary(
      const LibraryQueryFilters(),
    );
    if (token != _activeQueryToken || isClosed) {
      return;
    }

    final maxPageIndex = totalCount == 0
        ? 0
        : (totalCount - 1) ~/ state.pageSize;
    if (state.pageIndex > maxPageIndex) {
      _reloadPage(pageIndex: maxPageIndex);
      return;
    }

    emit(state.copyWith(totalCount: totalCount, hasIndexed: indexedCount > 0));
  }

  LibraryQueryFilters _currentFilters() {
    return LibraryQueryFilters(
      searchQuery: state.searchQuery,
      subreddit: state.includeSubreddit,
      excludedSubreddit: state.excludeSubreddit,
      kind: state.kindFilter,
      includeNsfw: state.showNsfw,
      resolutionStatus: state.resolutionFilter,
    );
  }

  int? _resolveSelectedItemId(List<SavedItem> items) {
    if (items.isEmpty) {
      return null;
    }
    final selectedItemId = state.selectedItemId;
    if (selectedItemId != null &&
        items.any((item) => item.id == selectedItemId)) {
      return selectedItemId;
    }
    return items.first.id;
  }

  @override
  Future<void> close() async {
    _searchDebounce?.cancel();
    await _itemsSubscription?.cancel();
    await _subredditSubscription.cancel();
    return super.close();
  }
}

class LibraryState extends Equatable {
  const LibraryState({
    required this.items,
    required this.subreddits,
    required this.searchQuery,
    required this.includeSubreddit,
    required this.excludeSubreddit,
    required this.kindFilter,
    required this.showNsfw,
    required this.resolutionFilter,
    required this.pageSize,
    required this.pageIndex,
    required this.totalCount,
    required this.isPageLoading,
    required this.selectedItemId,
    required this.hasIndexed,
  });

  final List<SavedItem> items;
  final List<String> subreddits;
  final String searchQuery;
  final String? includeSubreddit;
  final String? excludeSubreddit;
  final LibraryItemKind kindFilter;
  final bool showNsfw;
  final LibraryResolutionFilter resolutionFilter;
  final int pageSize;
  final int pageIndex;
  final int totalCount;
  final bool isPageLoading;
  final int? selectedItemId;
  final bool hasIndexed;

  static const _unset = Object();

  LibraryState copyWith({
    List<SavedItem>? items,
    List<String>? subreddits,
    String? searchQuery,
    Object? includeSubreddit = _unset,
    Object? excludeSubreddit = _unset,
    LibraryItemKind? kindFilter,
    bool? showNsfw,
    LibraryResolutionFilter? resolutionFilter,
    int? pageSize,
    int? pageIndex,
    int? totalCount,
    bool? isPageLoading,
    Object? selectedItemId = _unset,
    bool? hasIndexed,
  }) {
    return LibraryState(
      items: items ?? this.items,
      subreddits: subreddits ?? this.subreddits,
      searchQuery: searchQuery ?? this.searchQuery,
      includeSubreddit: includeSubreddit == _unset
          ? this.includeSubreddit
          : includeSubreddit as String?,
      excludeSubreddit: excludeSubreddit == _unset
          ? this.excludeSubreddit
          : excludeSubreddit as String?,
      kindFilter: kindFilter ?? this.kindFilter,
      showNsfw: showNsfw ?? this.showNsfw,
      resolutionFilter: resolutionFilter ?? this.resolutionFilter,
      pageSize: pageSize ?? this.pageSize,
      pageIndex: pageIndex ?? this.pageIndex,
      totalCount: totalCount ?? this.totalCount,
      isPageLoading: isPageLoading ?? this.isPageLoading,
      selectedItemId: selectedItemId == _unset
          ? this.selectedItemId
          : selectedItemId as int?,
      hasIndexed: hasIndexed ?? this.hasIndexed,
    );
  }

  bool get hasPreviousPage => pageIndex > 0;

  bool get hasNextPage => (pageIndex + 1) * pageSize < totalCount;

  int get pageCount {
    if (totalCount == 0) {
      return 1;
    }
    return (totalCount / pageSize).ceil();
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
    resolutionFilter,
    pageSize,
    pageIndex,
    totalCount,
    isPageLoading,
    selectedItemId,
    hasIndexed,
  ];
}
