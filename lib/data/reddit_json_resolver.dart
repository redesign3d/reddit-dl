import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../features/sync/permalink_utils.dart';
import '../features/sync/reddit_json_parser.dart';
import '../features/sync/reddit_saved_listing_parser.dart';
import 'reddit_saved_listing_client.dart';

class RedditJsonResolver {
  RedditJsonResolver({
    required CookieJar cookieJar,
    RedditJsonParser? parser,
    Dio? dio,
  })  : _parser = parser ?? RedditJsonParser(),
        _dio = dio ??
            Dio(
              BaseOptions(
                headers: {
                  HttpHeaders.userAgentHeader:
                      'reddit-dl/0.1 (+https://github.com/redesign3d/reddit-dl)',
                  HttpHeaders.acceptHeader: 'application/json',
                },
                validateStatus: (status) => status != null && status < 500,
              ),
            ) {
    _dio.interceptors.add(CookieManager(cookieJar));
  }

  final Dio _dio;
  final RedditJsonParser _parser;

  Future<ResolvedItem> resolve(
    String permalink, {
    ListingKindHint hint = ListingKindHint.unknown,
  }) async {
    final url = _jsonUrlFor(permalink);
    final response = await _dio.get<dynamic>(url);
    final status = response.statusCode ?? 0;
    if (status == 429) {
      final retryAfter = _retryAfter(response.headers);
      throw RateLimitException(retryAfterSeconds: retryAfter);
    }
    if (status >= 400) {
      throw RedditJsonException('Failed to resolve JSON ($status).');
    }
    final parsed = _parser.parse(
      response.data,
      permalink: normalizePermalink(permalink),
      hint: hint,
    );
    if (parsed == null) {
      throw const RedditJsonException('Malformed JSON payload.');
    }
    return parsed;
  }

  String _jsonUrlFor(String permalink) {
    final normalized = normalizePermalink(permalink);
    if (normalized.isEmpty) {
      throw const RedditJsonException('Missing permalink.');
    }
    return normalized.endsWith('.json') ? normalized : '$normalized.json';
  }

  int? _retryAfter(Headers headers) {
    final value = headers.value(HttpHeaders.retryAfterHeader);
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }
}

class RedditJsonException implements Exception {
  const RedditJsonException(this.message);

  final String message;

  @override
  String toString() => 'RedditJsonException: $message';
}
