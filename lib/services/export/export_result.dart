class ExportResult {
  const ExportResult._({
    required this.status,
    required this.outputPath,
    this.message,
  });

  final ExportStatus status;
  final String outputPath;
  final String? message;

  bool get isCompleted => status == ExportStatus.completed;
  bool get isSkipped => status == ExportStatus.skipped;
  bool get isFailed => status == ExportStatus.failed;

  factory ExportResult.completed(String path) {
    return ExportResult._(status: ExportStatus.completed, outputPath: path);
  }

  factory ExportResult.skipped(String reason, String path) {
    return ExportResult._(
      status: ExportStatus.skipped,
      outputPath: path,
      message: reason,
    );
  }

  factory ExportResult.failed(String reason, String path) {
    return ExportResult._(
      status: ExportStatus.failed,
      outputPath: path,
      message: reason,
    );
  }
}

enum ExportStatus { completed, skipped, failed }
