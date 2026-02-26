import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/reddit_json_resolver.dart';
import '../../data/reddit_saved_listing_client.dart';
import '../../data/session_repository.dart';
import '../../data/sync_repository.dart';
import '../logs/log_record.dart';
import '../../data/logs_repository.dart';
import 'reddit_json_parser.dart';
import 'reddit_saved_listing_parser.dart';
import 'webview_cookie_bridge.dart';

class SyncCubit extends Cubit<SyncState> {
  SyncCubit(this._sessionRepository, this._syncRepository, this._logs)
    : _webViewBridge = WebViewCookieBridge(_sessionRepository),
      super(SyncState.initial());

  final SessionRepository _sessionRepository;
  final SyncRepository _syncRepository;
  final LogsRepository _logs;
  final WebViewCookieBridge _webViewBridge;

  CancelToken? _cancelToken;
  bool _cancelRequested = false;
  static const _maxRecentErrors = 8;

  Future<void> updateRememberSession(bool remember) async {
    await _sessionRepository.initialize(remember: remember);
    await _webViewBridge.syncCookiesToWebView();
  }

  Future<void> prepareLogin({required bool rememberSession}) async {
    emit(
      state.copyWith(
        phase: SyncPhase.login,
        runStage: SyncRunStage.idle,
        loginVisible: true,
        errorMessage: null,
      ),
    );
    await _sessionRepository.initialize(remember: rememberSession);
    await _webViewBridge.syncCookiesToWebView();
    await _logs.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: 'sync',
        level: 'info',
        message: 'Login flow opened.',
      ),
    );
  }

  void hideLogin() {
    emit(state.copyWith(loginVisible: false));
  }

  Future<void> checkSession({required bool rememberSession}) async {
    emit(
      state.copyWith(
        phase: SyncPhase.login,
        runStage: SyncRunStage.idle,
        errorMessage: null,
      ),
    );
    await _sessionRepository.initialize(remember: rememberSession);
    await _webViewBridge.syncCookiesFromWebView();
    final cookieCount = await _countSessionCookies();

    final client = RedditSavedListingClient(
      cookieJar: _sessionRepository.cookieJar,
    );
    while (true) {
      try {
        final result = await client.checkSession();
        if (!result.isValid) {
          emit(
            state.copyWith(
              phase: SyncPhase.error,
              runStage: SyncRunStage.idle,
              sessionValid: false,
              sessionCookieCount: cookieCount,
              savedAccessOk: const Value(null),
              errorMessage: 'Session invalid. Please log in again.',
            ),
          );
          await _logs.add(
            LogRecord(
              timestamp: DateTime.now(),
              scope: 'sync',
              level: 'warn',
              message: 'Session check failed.',
            ),
          );
          return;
        }
        final savedAccess = result.username == null || result.username!.isEmpty
            ? null
            : await _probeSavedAccess(client, result.username!);
        emit(
          state.copyWith(
            phase: SyncPhase.ready,
            runStage: SyncRunStage.idle,
            sessionValid: true,
            loginVisible: false,
            username: Value(result.username),
            sessionCookieCount: cookieCount,
            savedAccessOk: Value(savedAccess),
            errorMessage: null,
          ),
        );
        await _logs.add(
          LogRecord(
            timestamp: DateTime.now(),
            scope: 'sync',
            level: 'info',
            message: 'Session validated for u/${result.username ?? 'unknown'}.',
          ),
        );
        return;
      } on RateLimitException catch (error) {
        await _handleRateLimit(error);
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          return;
        }
        emit(
          state.copyWith(
            phase: SyncPhase.error,
            runStage: SyncRunStage.idle,
            sessionValid: false,
            sessionCookieCount: cookieCount,
            savedAccessOk: const Value(null),
            errorMessage: 'Session check failed: $error',
          ),
        );
        await _logs.add(
          LogRecord(
            timestamp: DateTime.now(),
            scope: 'sync',
            level: 'error',
            message: 'Session check failed: $error',
          ),
        );
        return;
      } catch (error) {
        emit(
          state.copyWith(
            phase: SyncPhase.error,
            runStage: SyncRunStage.idle,
            sessionValid: false,
            sessionCookieCount: cookieCount,
            savedAccessOk: const Value(null),
            errorMessage: 'Session check failed: $error',
          ),
        );
        await _logs.add(
          LogRecord(
            timestamp: DateTime.now(),
            scope: 'sync',
            level: 'error',
            message: 'Session check failed: $error',
          ),
        );
        return;
      }
    }
  }

  Future<void> clearSession({required bool rememberSession}) async {
    await _sessionRepository.initialize(remember: rememberSession);
    await _sessionRepository.clearSession(removePersisted: true);
    await _webViewBridge.clearWebViewCookies();
    emit(
      state.copyWith(
        phase: SyncPhase.idle,
        runStage: SyncRunStage.idle,
        sessionValid: false,
        username: const Value(null),
        manualUsername: '',
        sessionCookieCount: 0,
        savedAccessOk: const Value(null),
        progress: const SyncProgress(),
        summary: const Value(null),
        recentErrors: const <String>[],
        failedPermalinks: const <String>[],
        errorMessage: null,
      ),
    );
    await _logs.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: 'sync',
        level: 'info',
        message: 'Session cleared.',
      ),
    );
  }

  void updateManualUsername(String value) {
    emit(state.copyWith(manualUsername: value.trim()));
  }

  Future<void> startSync({
    required bool rememberSession,
    required int rateLimitPerMinute,
    int? maxItems,
    int? timeframeDays,
  }) async {
    emit(
      state.copyWith(
        phase: SyncPhase.syncing,
        runStage: SyncRunStage.scanning,
        recentErrors: const <String>[],
        failedPermalinks: const <String>[],
        progress: const SyncProgress(),
        summary: const Value(null),
        errorMessage: null,
        isCancelling: false,
      ),
    );
    _cancelRequested = false;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    await _sessionRepository.initialize(remember: rememberSession);

    final client = RedditSavedListingClient(
      cookieJar: _sessionRepository.cookieJar,
    );
    final resolver = RedditJsonResolver(
      cookieJar: _sessionRepository.cookieJar,
    );

    final sessionResult = await _checkSessionWithRetry(client);
    if (!sessionResult.isValid) {
      emit(
        state.copyWith(
          phase: SyncPhase.error,
          sessionValid: false,
          errorMessage: 'Session expired. Please log in again.',
        ),
      );
      return;
    }
    if (!state.sessionValid || state.username == null) {
      emit(
        state.copyWith(
          username: Value(sessionResult.username),
          sessionValid: true,
        ),
      );
    }

    final effectiveUsername = _effectiveUsername() ?? sessionResult.username;
    if (effectiveUsername == null || effectiveUsername.isEmpty) {
      emit(
        state.copyWith(
          phase: SyncPhase.error,
          errorMessage: 'Enter a username or log in to detect one.',
        ),
      );
      return;
    }

    await _logs.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: 'sync',
        level: 'info',
        message: 'Sync started for u/$effectiveUsername.',
      ),
    );

    final cutoff = timeframeDays == null
        ? null
        : DateTime.now().toUtc().subtract(Duration(days: timeframeDays));
    final seen = <String>{};
    String? nextUrl;
    var shouldStop = false;
    var pages = 0;
    var resolvedCount = 0;
    var upsertedCount = 0;
    var insertedCount = 0;
    var updatedCount = 0;
    var failures = 0;
    var mediaInserted = 0;
    final insertedItemIds = <int>{};
    final failedPermalinks = <String>{};

    try {
      while (true) {
        _throwIfCancelled();
        emit(state.copyWith(runStage: SyncRunStage.scanning));
        final page = await _fetchListingWithRetry(
          client,
          effectiveUsername,
          nextUrl,
        );
        pages += 1;
        final items = page.items;

        var permalinksFound = seen.length;
        for (final item in items) {
          _throwIfCancelled();
          if (seen.contains(item.permalink)) {
            continue;
          }
          seen.add(item.permalink);
          permalinksFound = seen.length;
          emit(
            state.copyWith(
              progress: state.progress.copyWith(
                pagesScanned: pages,
                permalinksFound: permalinksFound,
                retryAfterSeconds: null,
              ),
            ),
          );

          ResolvedItem resolvedItem;
          try {
            emit(state.copyWith(runStage: SyncRunStage.resolving));
            resolvedItem = await _resolveWithRetry(
              resolver,
              item.permalink,
              item.kindHint,
            );
          } on SyncCancelledException {
            rethrow;
          } catch (error) {
            failures += 1;
            failedPermalinks.add(item.permalink);
            await _syncRepository.markResolutionFailed(item.permalink);
            _appendRecentError(
              'Failed to resolve ${item.permalink}: $error',
              failedPermalink: item.permalink,
            );
            await _logs.add(
              LogRecord(
                timestamp: DateTime.now(),
                scope: 'resolve',
                level: 'error',
                message: 'Failed to resolve ${item.permalink}: $error',
              ),
            );
            emit(
              state.copyWith(
                failedPermalinks: failedPermalinks.toList(growable: false),
                progress: state.progress.copyWith(
                  pagesScanned: pages,
                  permalinksFound: permalinksFound,
                  resolved: resolvedCount,
                  upserted: upsertedCount,
                  inserted: insertedCount,
                  updated: updatedCount,
                  failures: failures,
                  mediaInserted: mediaInserted,
                ),
              ),
            );
            continue;
          }

          resolvedCount += 1;

          final upsert = await _syncRepository.upsertResolved(resolvedItem);
          failedPermalinks.remove(item.permalink);
          upsertedCount += upsert.inserted || upsert.updated ? 1 : 0;
          if (upsert.inserted) {
            insertedCount += 1;
            insertedItemIds.add(upsert.savedItemId);
          }
          if (upsert.updated) {
            updatedCount += 1;
          }
          mediaInserted += upsert.mediaInserted;

          emit(
            state.copyWith(
              failedPermalinks: failedPermalinks.toList(growable: false),
              progress: state.progress.copyWith(
                pagesScanned: pages,
                permalinksFound: permalinksFound,
                resolved: resolvedCount,
                upserted: upsertedCount,
                inserted: insertedCount,
                updated: updatedCount,
                failures: failures,
                mediaInserted: mediaInserted,
              ),
            ),
          );

          if (maxItems != null) {
            final processed = resolvedCount + failures;
            if (processed >= maxItems) {
              shouldStop = true;
              break;
            }
          }

          if (cutoff != null && resolvedItem.createdUtc > 0) {
            final created = DateTime.fromMillisecondsSinceEpoch(
              resolvedItem.createdUtc * 1000,
              isUtc: true,
            );
            if (created.isBefore(cutoff)) {
              shouldStop = true;
              break;
            }
          }

          await _respectRateLimit(rateLimitPerMinute);
        }

        if (shouldStop) {
          break;
        }
        nextUrl = page.nextPage;
        if (nextUrl == null || nextUrl.isEmpty) {
          break;
        }
        await _respectRateLimit(rateLimitPerMinute);
      }

      final summary = SyncSummary(
        pagesScanned: pages,
        permalinksFound: seen.length,
        resolved: resolvedCount,
        upserted: upsertedCount,
        inserted: insertedCount,
        updated: updatedCount,
        failures: failures,
        mediaInserted: mediaInserted,
        insertedItemIds: insertedItemIds.toList(growable: false),
      );
      emit(
        state.copyWith(
          phase: SyncPhase.completed,
          runStage: SyncRunStage.completed,
          summary: Value(summary),
          failedPermalinks: failedPermalinks.toList(growable: false),
          progress: state.progress.copyWith(
            pagesScanned: summary.pagesScanned,
            permalinksFound: summary.permalinksFound,
            resolved: summary.resolved,
            upserted: summary.upserted,
            inserted: summary.inserted,
            updated: summary.updated,
            failures: summary.failures,
            mediaInserted: summary.mediaInserted,
          ),
        ),
      );
      await _logs.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'sync',
          level: 'info',
          message:
              'Sync complete: ${summary.permalinksFound} permalinks, ${summary.resolved} resolved, ${summary.failures} failed.',
        ),
      );
    } on SyncCancelledException {
      emit(
        state.copyWith(
          phase: SyncPhase.cancelled,
          runStage: SyncRunStage.idle,
          isCancelling: false,
        ),
      );
      await _logs.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'sync',
          level: 'warn',
          message: 'Sync cancelled by user.',
        ),
      );
    } catch (error) {
      _appendRecentError('Sync failed: $error');
      emit(
        state.copyWith(
          phase: SyncPhase.error,
          runStage: SyncRunStage.idle,
          errorMessage: 'Sync failed: $error',
          isCancelling: false,
        ),
      );
      await _logs.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'sync',
          level: 'error',
          message: 'Sync failed: $error',
        ),
      );
    }
  }

  void cancelSync() {
    if (state.phase != SyncPhase.syncing) {
      return;
    }
    _cancelRequested = true;
    _cancelToken?.cancel('Cancelled by user.');
    emit(state.copyWith(isCancelling: true));
  }

  Future<void> retryFailedResolutions({
    required bool rememberSession,
    required int rateLimitPerMinute,
  }) async {
    if (state.phase == SyncPhase.syncing) {
      return;
    }
    final retryPermalinks = state.failedPermalinks.toSet().toList(
      growable: false,
    );
    if (retryPermalinks.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        phase: SyncPhase.syncing,
        runStage: SyncRunStage.resolving,
        summary: const Value(null),
        recentErrors: const <String>[],
        errorMessage: null,
        isCancelling: false,
        progress: state.progress.copyWith(
          resolved: 0,
          upserted: 0,
          inserted: 0,
          updated: 0,
          failures: 0,
          mediaInserted: 0,
          retryAfterSeconds: null,
        ),
      ),
    );
    _cancelRequested = false;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    await _sessionRepository.initialize(remember: rememberSession);
    final client = RedditSavedListingClient(
      cookieJar: _sessionRepository.cookieJar,
    );
    final resolver = RedditJsonResolver(
      cookieJar: _sessionRepository.cookieJar,
    );
    final sessionResult = await _checkSessionWithRetry(client);
    if (!sessionResult.isValid) {
      emit(
        state.copyWith(
          phase: SyncPhase.error,
          runStage: SyncRunStage.idle,
          errorMessage: 'Session expired. Please log in again.',
        ),
      );
      return;
    }

    var resolved = 0;
    var upserted = 0;
    var inserted = 0;
    var updated = 0;
    var failures = 0;
    var mediaInserted = 0;
    final insertedItemIds = <int>{};
    final remainingFailed = <String>{};
    try {
      for (final permalink in retryPermalinks) {
        _throwIfCancelled();
        try {
          final hint = permalink.contains('/comments/')
              ? ListingKindHint.post
              : ListingKindHint.comment;
          final resolvedItem = await _resolveWithRetry(
            resolver,
            permalink,
            hint,
          );
          final upsert = await _syncRepository.upsertResolved(resolvedItem);
          resolved += 1;
          if (upsert.inserted || upsert.updated) {
            upserted += 1;
          }
          if (upsert.inserted) {
            inserted += 1;
            insertedItemIds.add(upsert.savedItemId);
          }
          if (upsert.updated) {
            updated += 1;
          }
          mediaInserted += upsert.mediaInserted;
        } catch (error) {
          failures += 1;
          remainingFailed.add(permalink);
          await _syncRepository.markResolutionFailed(permalink);
          _appendRecentError(
            'Retry failed for $permalink: $error',
            failedPermalink: permalink,
          );
        }
        emit(
          state.copyWith(
            failedPermalinks: remainingFailed.toList(growable: false),
            progress: state.progress.copyWith(
              resolved: resolved,
              upserted: upserted,
              inserted: inserted,
              updated: updated,
              failures: failures,
              mediaInserted: mediaInserted,
            ),
          ),
        );
        await _respectRateLimit(rateLimitPerMinute);
      }

      final summary = SyncSummary(
        pagesScanned: state.progress.pagesScanned,
        permalinksFound: state.progress.permalinksFound,
        resolved: resolved,
        upserted: upserted,
        inserted: inserted,
        updated: updated,
        failures: failures,
        mediaInserted: mediaInserted,
        insertedItemIds: insertedItemIds.toList(growable: false),
      );
      emit(
        state.copyWith(
          phase: SyncPhase.completed,
          runStage: SyncRunStage.completed,
          summary: Value(summary),
          failedPermalinks: remainingFailed.toList(growable: false),
        ),
      );
    } on SyncCancelledException {
      emit(
        state.copyWith(
          phase: SyncPhase.cancelled,
          runStage: SyncRunStage.idle,
          isCancelling: false,
          failedPermalinks: remainingFailed.toList(growable: false),
        ),
      );
    } catch (error) {
      _appendRecentError('Retry failed: $error');
      emit(
        state.copyWith(
          phase: SyncPhase.error,
          runStage: SyncRunStage.idle,
          errorMessage: 'Retry failed: $error',
          failedPermalinks: remainingFailed.toList(growable: false),
        ),
      );
    }
  }

  Future<SavedListingPage> _fetchListingWithRetry(
    RedditSavedListingClient client,
    String username,
    String? url,
  ) async {
    while (true) {
      _throwIfCancelled();
      try {
        return await client.fetchSavedPage(
          username: username,
          url: url,
          cancelToken: _cancelToken,
        );
      } on RateLimitException catch (error) {
        await _handleRateLimit(error);
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          throw SyncCancelledException();
        }
        rethrow;
      }
    }
  }

  Future<SessionCheckResult> _checkSessionWithRetry(
    RedditSavedListingClient client,
  ) async {
    while (true) {
      _throwIfCancelled();
      try {
        return await client.checkSession(cancelToken: _cancelToken);
      } on RateLimitException catch (error) {
        await _handleRateLimit(error);
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          throw SyncCancelledException();
        }
        rethrow;
      }
    }
  }

  Future<ResolvedItem> _resolveWithRetry(
    RedditJsonResolver resolver,
    String permalink,
    ListingKindHint hint,
  ) async {
    while (true) {
      _throwIfCancelled();
      try {
        return await resolver.resolve(
          permalink,
          hint: hint,
          cancelToken: _cancelToken,
        );
      } on RateLimitException catch (error) {
        await _handleRateLimit(error);
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          throw SyncCancelledException();
        }
        rethrow;
      }
    }
  }

  Future<void> _handleRateLimit(RateLimitException error) async {
    final delaySeconds = error.retryAfterSeconds ?? 10;
    emit(
      state.copyWith(
        progress: state.progress.copyWith(retryAfterSeconds: delaySeconds),
      ),
    );
    await _logs.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: 'sync',
        level: 'warn',
        message: 'Rate limited. Retrying after ${delaySeconds}s.',
      ),
    );
    await _delayWithCancel(Duration(seconds: delaySeconds));
  }

  Future<void> _respectRateLimit(int rateLimitPerMinute) async {
    if (rateLimitPerMinute <= 0) {
      return;
    }
    final delayMs = (60000 / rateLimitPerMinute).round();
    await _delayWithCancel(Duration(milliseconds: delayMs));
  }

  Future<void> _delayWithCancel(Duration duration) async {
    if (duration.inMilliseconds <= 0) {
      return;
    }
    final chunks = duration.inMilliseconds ~/ 250;
    for (var i = 0; i < chunks; i++) {
      _throwIfCancelled();
      await Future.delayed(const Duration(milliseconds: 250));
    }
    final remainder = duration.inMilliseconds % 250;
    if (remainder > 0) {
      _throwIfCancelled();
      await Future.delayed(Duration(milliseconds: remainder));
    }
  }

  void _throwIfCancelled() {
    if (_cancelRequested) {
      throw SyncCancelledException();
    }
  }

  String? _effectiveUsername() {
    if (state.username != null && state.username!.isNotEmpty) {
      return state.username;
    }
    if (state.manualUsername.isNotEmpty) {
      return state.manualUsername;
    }
    return null;
  }

  Future<int> _countSessionCookies() async {
    final cookies = await _sessionRepository.loadCookies(
      Uri.parse('https://old.reddit.com/'),
    );
    return cookies.length;
  }

  Future<bool?> _probeSavedAccess(
    RedditSavedListingClient client,
    String username,
  ) async {
    try {
      await client.fetchSavedPage(
        username: username,
        cancelToken: _cancelToken,
      );
      return true;
    } on RateLimitException {
      return true;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        throw SyncCancelledException();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _appendRecentError(String message, {String? failedPermalink}) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      return;
    }
    final nextErrors = [trimmedMessage, ...state.recentErrors];
    if (nextErrors.length > _maxRecentErrors) {
      nextErrors.removeRange(_maxRecentErrors, nextErrors.length);
    }
    final failed = state.failedPermalinks.toSet();
    if (failedPermalink != null && failedPermalink.trim().isNotEmpty) {
      failed.add(failedPermalink.trim());
    }
    emit(
      state.copyWith(
        recentErrors: nextErrors,
        failedPermalinks: failed.toList(growable: false),
      ),
    );
  }
}

class SyncState extends Equatable {
  const SyncState({
    required this.phase,
    required this.runStage,
    required this.loginVisible,
    required this.sessionValid,
    required this.username,
    required this.manualUsername,
    required this.sessionCookieCount,
    required this.savedAccessOk,
    required this.progress,
    required this.summary,
    required this.recentErrors,
    required this.failedPermalinks,
    required this.errorMessage,
    required this.isCancelling,
  });

  factory SyncState.initial() {
    return const SyncState(
      phase: SyncPhase.idle,
      runStage: SyncRunStage.idle,
      loginVisible: false,
      sessionValid: false,
      username: null,
      manualUsername: '',
      sessionCookieCount: 0,
      savedAccessOk: null,
      progress: SyncProgress(),
      summary: null,
      recentErrors: <String>[],
      failedPermalinks: <String>[],
      errorMessage: null,
      isCancelling: false,
    );
  }

  final SyncPhase phase;
  final SyncRunStage runStage;
  final bool loginVisible;
  final bool sessionValid;
  final String? username;
  final String manualUsername;
  final int sessionCookieCount;
  final bool? savedAccessOk;
  final SyncProgress progress;
  final SyncSummary? summary;
  final List<String> recentErrors;
  final List<String> failedPermalinks;
  final String? errorMessage;
  final bool isCancelling;

  static const _unset = Object();

  SyncState copyWith({
    SyncPhase? phase,
    SyncRunStage? runStage,
    bool? loginVisible,
    bool? sessionValid,
    Value<String?>? username,
    String? manualUsername,
    int? sessionCookieCount,
    Value<bool?>? savedAccessOk,
    SyncProgress? progress,
    Value<SyncSummary?>? summary,
    List<String>? recentErrors,
    List<String>? failedPermalinks,
    Object? errorMessage = _unset,
    bool? isCancelling,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      runStage: runStage ?? this.runStage,
      loginVisible: loginVisible ?? this.loginVisible,
      sessionValid: sessionValid ?? this.sessionValid,
      username: username == null ? this.username : username.value,
      manualUsername: manualUsername ?? this.manualUsername,
      sessionCookieCount: sessionCookieCount ?? this.sessionCookieCount,
      savedAccessOk: savedAccessOk == null
          ? this.savedAccessOk
          : savedAccessOk.value,
      progress: progress ?? this.progress,
      summary: summary == null ? this.summary : summary.value,
      recentErrors: recentErrors ?? this.recentErrors,
      failedPermalinks: failedPermalinks ?? this.failedPermalinks,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      isCancelling: isCancelling ?? this.isCancelling,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    runStage,
    loginVisible,
    sessionValid,
    username,
    manualUsername,
    sessionCookieCount,
    savedAccessOk,
    progress,
    summary,
    recentErrors,
    failedPermalinks,
    errorMessage,
    isCancelling,
  ];
}

class SyncProgress extends Equatable {
  const SyncProgress({
    this.pagesScanned = 0,
    this.permalinksFound = 0,
    this.resolved = 0,
    this.upserted = 0,
    this.inserted = 0,
    this.updated = 0,
    this.failures = 0,
    this.mediaInserted = 0,
    this.retryAfterSeconds,
  });

  final int pagesScanned;
  final int permalinksFound;
  final int resolved;
  final int upserted;
  final int inserted;
  final int updated;
  final int failures;
  final int mediaInserted;
  final int? retryAfterSeconds;

  SyncProgress copyWith({
    int? pagesScanned,
    int? permalinksFound,
    int? resolved,
    int? upserted,
    int? inserted,
    int? updated,
    int? failures,
    int? mediaInserted,
    int? retryAfterSeconds,
  }) {
    return SyncProgress(
      pagesScanned: pagesScanned ?? this.pagesScanned,
      permalinksFound: permalinksFound ?? this.permalinksFound,
      resolved: resolved ?? this.resolved,
      upserted: upserted ?? this.upserted,
      inserted: inserted ?? this.inserted,
      updated: updated ?? this.updated,
      failures: failures ?? this.failures,
      mediaInserted: mediaInserted ?? this.mediaInserted,
      retryAfterSeconds: retryAfterSeconds ?? this.retryAfterSeconds,
    );
  }

  @override
  List<Object?> get props => [
    pagesScanned,
    permalinksFound,
    resolved,
    upserted,
    inserted,
    updated,
    failures,
    mediaInserted,
    retryAfterSeconds,
  ];
}

class SyncSummary extends Equatable {
  const SyncSummary({
    required this.pagesScanned,
    required this.permalinksFound,
    required this.resolved,
    required this.upserted,
    required this.inserted,
    required this.updated,
    required this.failures,
    required this.mediaInserted,
    required this.insertedItemIds,
  });

  final int pagesScanned;
  final int permalinksFound;
  final int resolved;
  final int upserted;
  final int inserted;
  final int updated;
  final int failures;
  final int mediaInserted;
  final List<int> insertedItemIds;

  @override
  List<Object?> get props => [
    pagesScanned,
    permalinksFound,
    resolved,
    upserted,
    inserted,
    updated,
    failures,
    mediaInserted,
    insertedItemIds,
  ];
}

enum SyncPhase { idle, login, ready, syncing, completed, cancelled, error }

enum SyncRunStage { idle, scanning, resolving, completed }

enum SyncUiStep { login, validateSession, scanSavedPages, resolveJson, summary }

SyncUiStep syncUiStepFromState(SyncState state) {
  if (state.phase == SyncPhase.completed) {
    return SyncUiStep.summary;
  }
  if (state.phase == SyncPhase.syncing &&
      state.runStage == SyncRunStage.resolving) {
    return SyncUiStep.resolveJson;
  }
  if (state.phase == SyncPhase.syncing) {
    return SyncUiStep.scanSavedPages;
  }
  if (state.sessionValid) {
    return SyncUiStep.validateSession;
  }
  return SyncUiStep.login;
}

class SyncCancelledException implements Exception {}
