import 'dart:io' as io;

import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;

import '../../data/session_repository.dart';

class WebViewCookieBridge {
  WebViewCookieBridge(this._sessionRepository);

  final SessionRepository _sessionRepository;

  Future<void> syncCookiesFromWebView() async {
    final cookies = await inapp.CookieManager.instance().getCookies(
      url: inapp.WebUri('https://old.reddit.com/'),
    );
    await _storeWebViewCookies(Uri.parse('https://old.reddit.com/'), cookies);

    final wwwCookies = await inapp.CookieManager.instance().getCookies(
      url: inapp.WebUri('https://www.reddit.com/'),
    );
    await _storeWebViewCookies(
      Uri.parse('https://www.reddit.com/'),
      wwwCookies,
    );
  }

  Future<void> syncCookiesToWebView() async {
    await _applyCookies(Uri.parse('https://old.reddit.com/'));
    await _applyCookies(Uri.parse('https://www.reddit.com/'));
  }

  Future<void> clearWebViewCookies() async {
    await inapp.CookieManager.instance().deleteAllCookies();
  }

  Future<void> _storeWebViewCookies(Uri url, List<inapp.Cookie> cookies) async {
    if (cookies.isEmpty) {
      return;
    }
    final ioCookies = cookies.map(_toIoCookie).toList();
    await _sessionRepository.storeCookies(url, ioCookies);
  }

  io.Cookie _toIoCookie(inapp.Cookie cookie) {
    final ioCookie = io.Cookie(cookie.name, cookie.value);
    if (cookie.domain != null) {
      ioCookie.domain = cookie.domain;
    }
    if (cookie.path != null) {
      ioCookie.path = cookie.path;
    }
    if (cookie.expiresDate != null) {
      ioCookie.expires = DateTime.fromMillisecondsSinceEpoch(
        cookie.expiresDate!,
      );
    }
    if (cookie.isHttpOnly != null) {
      ioCookie.httpOnly = cookie.isHttpOnly!;
    }
    if (cookie.isSecure != null) {
      ioCookie.secure = cookie.isSecure!;
    }
    return ioCookie;
  }

  Future<void> _applyCookies(Uri url) async {
    final cookies = await _sessionRepository.loadCookies(url);
    for (final cookie in cookies) {
      final domain = cookie.domain;
      await inapp.CookieManager.instance().setCookie(
        url: inapp.WebUri(url.toString()),
        name: cookie.name,
        value: cookie.value,
        domain: domain != null && domain.isNotEmpty ? domain : null,
        path: cookie.path ?? '/',
        expiresDate: cookie.expires?.millisecondsSinceEpoch,
        isSecure: cookie.secure,
        isHttpOnly: cookie.httpOnly,
      );
    }
  }
}
