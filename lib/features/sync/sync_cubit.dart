import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/reddit_json_resolver.dart';
import '../../data/reddit_saved_listing_client.dart';
import '../../data/session_repository.dart';
import '../../data/sync_repository.dart';
import '../logs/log_record.dart';
import '../../data/logs_repository.dart';
import 'reddit_saved_listing_parser.dart';
import 'webview_cookie_bridge.dart';

class SyncCubit extends Cubit<SyncState> {
  SyncCubit(
    this._sessionRepository,
    this._syncRepository,
    this._logs,
  )   : _webViewBridge = WebViewCookieBridge(_sessionRepository),
        super(SyncState.initial());

  final SessionRepository _sessionRepository;
  final SyncRepository _syncRepository;
  final LogsRepository _logs;
  final WebViewCookieBridge _webViewBridge;

  CancelToken? _cancelToken;
  bool _cancelRequested = false;

  Future<void> updateRememberSession(bool remember) async {
    await _sessionRepository.initialize(remember: remember);
    await _webViewBridge.syncCookiesToWebView();
  }

  Future<void> prepareLogin({required bool rememberSession}) async {
    emit(state.copyWith(
      phase: SyncPhase.login,
      loginVisible: true,
      errorMessage: null,
    ));
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
    emit(state.copyWith(phase: SyncPhase.login, errorMessage: null));
    await _sessionRepository.initialize(remember: rememberSession);
    await _webViewBridge.syncCookiesFromWebView();

    final client =
        RedditSavedListingClient(cookieJar: _sessionRepository.cookieJar);
    while (true) {
      try {
        final result = await client.checkSession();
        if (!result.isValid) {
          emit(state.copyWith(
            phase: SyncPhase.error,
            sessionValid: false,
            errorMessage: 'Session invalid. Please log in again.',
          ));
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
        emit(state.copyWith(
          phase: SyncPhase.ready,
          sessionValid: true,
          loginVisible: false,
          username: result.username,
          errorMessage: null,
        ));
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
        emit(state.copyWith(
          phase: SyncPhase.error,
          sessionValid: false,
          errorMessage: 'Session check failed: $error',
        ));
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
        emit(state.copyWith(
          phase: SyncPhase.error,
          sessionValid: false,
          errorMessage: 'Session check failed: $error',
        ));
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
    emit(state.copyWith(
      phase: SyncPhase.idle,
      sessionValid: false,
      username: null,
      manualUsername: '',
      progress: const SyncProgress(),
      summary: null,
      errorMessage: null,
    ));
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
    emit(state.copyWith(
      phase: SyncPhase.syncing,
      progress: const SyncProgress(),
      summary: null,
      errorMessage: null,
      isCancelling: false,
    ));
    _cancelRequested = false;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    await _sessionRepository.initialize(remember: rememberSession);

    final client =
        RedditSavedListingClient(cookieJar: _sessionRepository.cookieJar);
    final resolver =
        RedditJsonResolver(cookieJar: _sessionRepository.cookieJar);

    final sessionResult = await _checkSessionWithRetry(client);
    if (!sessionResult.isValid) {
      emit(state.copyWith(
        phase: SyncPhase.error,
        sessionValid: false,
        errorMessage: 'Session expired. Please log in again.',
      ));
      return;
    }
    if (state.username == null && sessionResult.username != null) {
      emit(state.copyWith(
        username: sessionResult.username,
        sessionValid: true,
      ));
    }

    final effectiveUsername = _effectiveUsername() ?? sessionResult.username;
    if (effectiveUsername == null || effectiveUsername.isEmpty) {
      emit(state.copyWith(
        phase: SyncPhase.error,
        errorMessage: 'Enter a username or log in to detect one.',
      ));
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
        : DateTime.now()
            .toUtc()
            .subtract(Duration(days: timeframeDays));
    final seen = <String>{};
    String? nextUrl;
    var shouldStop = false;
    var pages = 0;
    var resolvedCount = 0;
    var upsertedCount = 0;
    var failures = 0;
    var mediaInserted = 0;

    try {
      while (true) {
        _throwIfCancelled();
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
          emit(state.copyWith(
            progress: state.progress.copyWith(
              pagesScanned: pages,
              permalinksFound: permalinksFound,
              retryAfterSeconds: null,
            ),
          ));

          ResolvedItem resolvedItem;
          try {
            resolvedItem = await _resolveWithRetry(
              resolver,
              item.permalink,
              item.kindHint,
            );
          } on SyncCancelledException {
            rethrow;
          } catch (error) {
            failures += 1;
            await _syncRepository.markResolutionFailed(item.permalink);
            await _logs.add(
              LogRecord(
                timestamp: DateTime.now(),
                scope: 'resolve',
                level: 'error',
                message: 'Failed to resolve ${item.permalink}: $error',
              ),
            );
            emit(state.copyWith(
              progress: state.progress.copyWith(
                pagesScanned: pages,
                permalinksFound: permalinksFound,
                resolved: resolvedCount,
                upserted: upsertedCount,
                failures: failures,
                mediaInserted: mediaInserted,
              ),
            ));
            continue;
          }

          resolvedCount += 1;

          final upsert = await _syncRepository.upsertResolved(resolvedItem);
          upsertedCount += upsert.inserted || upsert.updated ? 1 : 0;
          mediaInserted += upsert.mediaInserted;

          emit(state.copyWith(
            progress: state.progress.copyWith(
              pagesScanned: pages,
              permalinksFound: permalinksFound,
              resolved: resolvedCount,
              upserted: upsertedCount,
              failures: failures,
              mediaInserted: mediaInserted,
            ),
          ));

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
        failures: failures,
        mediaInserted: mediaInserted,
      );
      emit(state.copyWith(
        phase: SyncPhase.completed,
        summary: summary,
        progress: state.progress.copyWith(
          pagesScanned: summary.pagesScanned,
          permalinksFound: summary.permalinksFound,
          resolved: summary.resolved,
          upserted: summary.upserted,
          failures: summary.failures,
          mediaInserted: summary.mediaInserted,
        ),
      ));
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
      emit(state.copyWith(phase: SyncPhase.cancelled, isCancelling: false));
      await _logs.add(
        LogRecord(
          timestamp: DateTime.now(),
          scope: 'sync',
          level: 'warn',
          message: 'Sync cancelled by user.',
        ),
      );
    } catch (error) {
      emit(state.copyWith(
        phase: SyncPhase.error,
        errorMessage: 'Sync failed: $error',
        isCancelling: false,
      ));
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
    emit(state.copyWith(
      progress: state.progress.copyWith(retryAfterSeconds: delaySeconds),
    ));
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
}

class SyncState extends Equatable {
  const SyncState({
    required this.phase,
    required this.loginVisible,
    required this.sessionValid,
    required this.username,
    required this.manualUsername,
    required this.progress,
    required this.summary,
    required this.errorMessage,
    required this.isCancelling,
  });

  factory SyncState.initial() {
    return const SyncState(
      phase: SyncPhase.idle,
      loginVisible: false,
      sessionValid: false,
      username: null,
      manualUsername: '',
      progress: SyncProgress(),
      summary: null,
      errorMessage: null,
      isCancelling: false,
    );
  }

  final SyncPhase phase;
  final bool loginVisible;
  final bool sessionValid;
  final String? username;
  final String manualUsername;
  final SyncProgress progress;
  final SyncSummary? summary;
  final String? errorMessage;
  final bool isCancelling;

  SyncState copyWith({
    SyncPhase? phase,
    bool? loginVisible,
    bool? sessionValid,
    String? username,
    String? manualUsername,
    SyncProgress? progress,
    SyncSummary? summary,
    String? errorMessage,
    bool? isCancelling,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      loginVisible: loginVisible ?? this.loginVisible,
      sessionValid: sessionValid ?? this.sessionValid,
      username: username ?? this.username,
      manualUsername: manualUsername ?? this.manualUsername,
      progress: progress ?? this.progress,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
      isCancelling: isCancelling ?? this.isCancelling,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        loginVisible,
        sessionValid,
        username,
        manualUsername,
        progress,
        summary,
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
    this.failures = 0,
    this.mediaInserted = 0,
    this.retryAfterSeconds,
  });

  final int pagesScanned;
  final int permalinksFound;
  final int resolved;
  final int upserted;
  final int failures;
  final int mediaInserted;
  final int? retryAfterSeconds;

  SyncProgress copyWith({
    int? pagesScanned,
    int? permalinksFound,
    int? resolved,
    int? upserted,
    int? failures,
    int? mediaInserted,
    int? retryAfterSeconds,
  }) {
    return SyncProgress(
      pagesScanned: pagesScanned ?? this.pagesScanned,
      permalinksFound: permalinksFound ?? this.permalinksFound,
      resolved: resolved ?? this.resolved,
      upserted: upserted ?? this.upserted,
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
    required this.failures,
    required this.mediaInserted,
  });

  final int pagesScanned;
  final int permalinksFound;
  final int resolved;
  final int upserted;
  final int failures;
  final int mediaInserted;

  @override
  List<Object?> get props => [
        pagesScanned,
        permalinksFound,
        resolved,
        upserted,
        failures,
        mediaInserted,
      ];
}

enum SyncPhase { idle, login, ready, syncing, completed, cancelled, error }

class SyncCancelledException implements Exception {}
