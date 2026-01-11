import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../features/sync/reddit_saved_listing_parser.dart';

class RedditSavedListingClient {
  RedditSavedListingClient({
    required CookieJar cookieJar,
    RedditSavedListingParser? parser,
    Dio? dio,
  })  : _parser = parser ?? RedditSavedListingParser(),
        _dio = dio ??
            Dio(
              BaseOptions(
                headers: {
                  HttpHeaders.userAgentHeader:
                      'reddit-dl/0.1 (+https://github.com/redesign3d/reddit-dl)',
                  HttpHeaders.acceptHeader: 'text/html',
                },
                validateStatus: (status) => status != null && status < 500,
              ),
            ) {
    _dio.interceptors.add(CookieManager(cookieJar));
  }

  final Dio _dio;
  final RedditSavedListingParser _parser;

  Future<SessionCheckResult> checkSession({CancelToken? cancelToken}) async {
    final response = await _dio.get<String>(
      'https://old.reddit.com/',
      cancelToken: cancelToken,
    );
    final html = response.data ?? '';
    final username = _parser.parseUsername(html);
    return SessionCheckResult(
      isValid: username != null && username.isNotEmpty,
      username: username,
    );
  }

  Future<SavedListingPage> fetchSavedPage({
    required String username,
    String? url,
    CancelToken? cancelToken,
  }) async {
    final target = url ?? 'https://old.reddit.com/user/$username/saved/';
    final response = await _dio.get<String>(
      target,
      cancelToken: cancelToken,
    );
    final status = response.statusCode ?? 0;
    if (status == 429) {
      final retryAfter = _retryAfter(response.headers);
      throw RateLimitException(retryAfterSeconds: retryAfter);
    }
    if (status >= 400) {
      throw RedditListingException('Failed to fetch saved listing ($status).');
    }
    final html = response.data ?? '';
    return _parser.parse(html);
  }

  int? _retryAfter(Headers headers) {
    final value = headers.value(HttpHeaders.retryAfterHeader);
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }
}

class SessionCheckResult {
  const SessionCheckResult({required this.isValid, this.username});

  final bool isValid;
  final String? username;
}

class RateLimitException implements Exception {
  RateLimitException({this.retryAfterSeconds});

  final int? retryAfterSeconds;

  @override
  String toString() =>
      'RateLimitException(retryAfterSeconds: $retryAfterSeconds)';
}

class RedditListingException implements Exception {
  const RedditListingException(this.message);

  final String message;

  @override
  String toString() => 'RedditListingException: $message';
}
