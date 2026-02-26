import '../data/queue_repository.dart';
import '../data/settings_repository.dart';

Future<String?> resolveRevealPath({
  required QueueRepository queueRepository,
  required SettingsRepository settingsRepository,
  int? jobId,
  int? savedItemId,
  String? legacyOutputPath,
}) async {
  final candidates = <String>[];

  final jobPath = jobId == null
      ? null
      : await queueRepository.fetchLatestOutputPathForJob(jobId);
  final itemPath = savedItemId == null
      ? null
      : await queueRepository.fetchLatestOutputPathForSavedItem(savedItemId);
  final normalizedLegacy = _normalizePath(legacyOutputPath);
  final settings = await settingsRepository.load();
  final rootPath = _normalizePath(settings.downloadRoot);

  for (final candidate in [jobPath, itemPath, normalizedLegacy, rootPath]) {
    final normalized = _normalizePath(candidate);
    if (normalized == null || candidates.contains(normalized)) {
      continue;
    }
    candidates.add(normalized);
  }

  if (candidates.isEmpty) {
    return null;
  }
  return candidates.first;
}

String? _normalizePath(String? path) {
  if (path == null) {
    return null;
  }
  final normalized = path.trim();
  if (normalized.isEmpty || normalized == 'pending') {
    return null;
  }
  return normalized;
}
