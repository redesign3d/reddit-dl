import 'package:html/parser.dart' as html_parser;

String normalizePermalink(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final decoded = _decodeHtml(trimmed);
  final parsed = Uri.tryParse(decoded);
  var path = '';
  if (parsed != null && parsed.hasScheme) {
    path = parsed.path;
  } else {
    path = decoded;
  }

  if (!path.startsWith('/')) {
    path = '/$path';
  }
  path = path.replaceFirst(RegExp(r'\.json$'), '');
  path = path.replaceAll(RegExp(r'/+$'), '');

  if (path == '/' || path.isEmpty) {
    return '';
  }
  return 'https://www.reddit.com$path';
}

String _decodeHtml(String value) {
  return html_parser.parseFragment(value).text ?? '';
}
