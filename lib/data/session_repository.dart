import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SessionRepository {
  SessionRepository();

  CookieJar _cookieJar = CookieJar();
  bool _remember = false;

  bool get rememberSession => _remember;
  CookieJar get cookieJar => _cookieJar;

  Future<void> initialize({required bool remember}) async {
    if (_remember == remember) {
      return;
    }
    final previous = _cookieJar;
    if (!remember) {
      await _deletePersistedStore();
    }
    _cookieJar = await _buildJar(remember);
    _remember = remember;
    await _copyCookies(previous, _cookieJar);
  }

  Future<void> storeCookies(Uri url, List<Cookie> cookies) async {
    if (cookies.isEmpty) {
      return;
    }
    await _cookieJar.saveFromResponse(url, cookies);
  }

  Future<List<Cookie>> loadCookies(Uri url) {
    return _cookieJar.loadForRequest(url);
  }

  Future<void> clearSession({bool removePersisted = false}) async {
    await _cookieJar.deleteAll();
    if (removePersisted) {
      await _deletePersistedStore();
      if (_remember) {
        _cookieJar = await _buildJar(true);
      }
    }
  }

  Future<CookieJar> _buildJar(bool remember) async {
    if (!remember) {
      return CookieJar();
    }
    final dir = await _ensureCookieStorageDir();
    return PersistCookieJar(storage: FileStorage(dir.path));
  }

  Future<Directory> _ensureCookieStorageDir() async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, 'reddit_dl', 'cookies'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _deletePersistedStore() async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, 'reddit_dl', 'cookies'));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> _copyCookies(CookieJar from, CookieJar to) async {
    const urls = ['https://old.reddit.com/', 'https://www.reddit.com/'];
    for (final url in urls) {
      final uri = Uri.parse(url);
      final cookies = await from.loadForRequest(uri);
      if (cookies.isNotEmpty) {
        await to.saveFromResponse(uri, cookies);
      }
    }
  }
}
