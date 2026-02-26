class DownloadResumeState {
  const DownloadResumeState({
    required this.jobId,
    required this.mediaAssetId,
    required this.url,
    required this.localTempPath,
    required this.expectedFinalPath,
    required this.etag,
    required this.lastModified,
    required this.totalBytes,
    required this.downloadedBytes,
  });

  final int jobId;
  final int mediaAssetId;
  final String url;
  final String localTempPath;
  final String expectedFinalPath;
  final String? etag;
  final String? lastModified;
  final int? totalBytes;
  final int downloadedBytes;
}

abstract class DownloadResumeStateStore {
  Future<DownloadResumeState?> fetchResumeState({
    required int jobId,
    required int mediaAssetId,
  });

  Future<void> upsertResumeState(DownloadResumeState state);

  Future<void> clearResumeState({
    required int jobId,
    required int mediaAssetId,
  });
}
