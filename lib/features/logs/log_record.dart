class LogRecord {
  const LogRecord({
    required this.timestamp,
    required this.scope,
    required this.level,
    required this.message,
  });

  final DateTime timestamp;
  final String scope;
  final String level;
  final String message;
}
