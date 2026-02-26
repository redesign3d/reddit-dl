import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../../data/logs_repository.dart';
import '../../data/queue_repository.dart';
import '../../data/session_repository.dart';
import '../../data/settings_repository.dart';
import '../../features/logs/log_record.dart';
import '../ffmpeg_runtime_manager.dart';
import '../path_template_engine.dart';
import 'download_telemetry.dart';
import 'external_media_downloader.dart';
import '../export/export_result.dart';
import '../export/saved_comment_markdown_exporter.dart';
import '../export/text_post_markdown_exporter.dart';
import '../export/thread_comments_markdown_exporter.dart';
import 'ffmpeg_executor.dart';
import 'http_media_downloader.dart';
import 'overwrite_policy.dart';
import 'reddit_video_downloader.dart';
import '../tools/external_tool_runner.dart';
import '../tools/tool_detector.dart';

class DownloadScheduler {
  DownloadScheduler({
    required QueueRepository queueRepository,
    required SettingsRepository settingsRepository,
    required LogsRepository logsRepository,
    required SessionRepository sessionRepository,
    required DownloadTelemetry telemetry,
    Dio? dio,
    OverwritePolicyEvaluator? policyEvaluator,
    HttpMediaDownloader? downloader,
    RedditVideoDownloader? videoDownloader,
    FfmpegRuntimeManager? ffmpegRuntimeManager,
    FfmpegExecutor? ffmpegExecutor,
    ExternalMediaDownloader? externalDownloader,
    ToolDetector? toolDetector,
    ExternalToolRunner? toolRunner,
    TextPostMarkdownExporter? textPostExporter,
    SavedCommentMarkdownExporter? savedCommentExporter,
    ThreadCommentsMarkdownExporter? threadCommentsExporter,
  }) : _queueRepository = queueRepository,
       _settingsRepository = settingsRepository,
       _logsRepository = logsRepository,
       _sessionRepository = sessionRepository,
       _telemetry = telemetry {
    _settings = AppSettings.defaults();
    _dio =
        dio ??
        Dio(
          BaseOptions(
            validateStatus: (status) => status != null && status < 500,
            headers: {
              HttpHeaders.userAgentHeader:
                  'reddit-dl/0.1 (+https://github.com/redesign3d/reddit-dl)',
            },
          ),
        );
    _dio.interceptors.add(CookieManager(_sessionRepository.cookieJar));
    _policyEvaluator = policyEvaluator ?? OverwritePolicyEvaluator(_dio);
    _downloader = downloader ?? HttpMediaDownloader(_dio, _policyEvaluator);
    _videoDownloader =
        videoDownloader ??
        RedditVideoDownloader(
          dio: _dio,
          policyEvaluator: _policyEvaluator,
          httpDownloader: _downloader,
          ffmpegRuntime: ffmpegRuntimeManager ?? FfmpegRuntimeManager(),
          ffmpegExecutor: ffmpegExecutor ?? ProcessFfmpegExecutor(),
        );
    _externalDownloader =
        externalDownloader ??
        ExternalMediaDownloader(
          toolDetector: toolDetector ?? ToolDetector(),
          toolRunner: toolRunner ?? ExternalToolRunner(_logsRepository),
        );
    _textPostExporter = textPostExporter ?? TextPostMarkdownExporter();
    _savedCommentExporter =
        savedCommentExporter ?? SavedCommentMarkdownExporter();
    _threadCommentsExporter =
        threadCommentsExporter ?? ThreadCommentsMarkdownExporter(_dio);
  }

  final QueueRepository _queueRepository;
  final SettingsRepository _settingsRepository;
  final LogsRepository _logsRepository;
  final SessionRepository _sessionRepository;
  final DownloadTelemetry _telemetry;

  late final Dio _dio;
  late final OverwritePolicyEvaluator _policyEvaluator;
  late final HttpMediaDownloader _downloader;
  late final RedditVideoDownloader _videoDownloader;
  late final ExternalMediaDownloader _externalDownloader;
  late final TextPostMarkdownExporter _textPostExporter;
  late final SavedCommentMarkdownExporter _savedCommentExporter;
  late final ThreadCommentsMarkdownExporter _threadCommentsExporter;

  late AppSettings _settings;
  StreamSubscription<AppSettings>? _settingsSubscription;
  StreamSubscription<List<QueueRecord>>? _queueSubscription;
  final Map<int, CancelToken> _running = {};
  List<QueueRecord> _latestQueue = [];
  bool _isDisposed = false;

  void start() {
    unawaited(_recoverStuckJobs());
    _settingsSubscription = _settingsRepository.watch().listen(_handleSettings);
    _queueSubscription = _queueRepository.watchQueue().listen(_handleQueue);
  }

  Future<void> dispose() async {
    _isDisposed = true;
    for (final token in _running.values) {
      token.cancel('Scheduler disposed.');
    }
    await _settingsSubscription?.cancel();
    await _queueSubscription?.cancel();
  }

  Future<void> _recoverStuckJobs() async {
    final reason =
        'App restarted; job paused. Partial files may remain (resume not supported).';
    final count = await _queueRepository.markStuckJobsPaused(reason);
    if (count > 0) {
      await _log(
        null,
        'download',
        'warn',
        'Recovered $count stuck job(s) after restart.',
      );
    }
  }

  void _handleSettings(AppSettings settings) {
    _settings = settings;
    _schedule();
  }

  void _handleQueue(List<QueueRecord> records) {
    _latestQueue = records;
    for (final entry in _running.entries.toList()) {
      final jobId = entry.key;
      final record = records.where((item) => item.job.id == jobId).firstOrNull;
      if (record == null) {
        entry.value.cancel('Job removed.');
        _running.remove(jobId);
        continue;
      }
      if (!_activeStatuses.contains(record.job.status)) {
        entry.value.cancel('Job paused or stopped.');
        _running.remove(jobId);
      }
    }
    _schedule();
  }

  void _schedule() {
    if (_isDisposed) {
      return;
    }
    final available = _settings.concurrency - _running.length;
    if (available <= 0) {
      return;
    }
    final queued = _latestQueue
        .where((record) => record.job.status == 'queued')
        .toList();
    queued.sort((a, b) => a.job.id.compareTo(b.job.id));
    for (final record in queued.take(available)) {
      _startJob(record);
    }
  }

  Future<void> _startJob(QueueRecord record) async {
    final jobId = record.job.id;
    if (_running.containsKey(jobId)) {
      return;
    }
    if (record.job.attempts >= _settings.maxDownloadAttempts) {
      await _queueRepository.markJobFailed(
        jobId,
        'Max attempts reached (${_settings.maxDownloadAttempts}).',
      );
      return;
    }
    await _queueRepository.markJobRunning(jobId);
    await _queueRepository.incrementAttempts(jobId);
    final token = CancelToken();
    _running[jobId] = token;
    unawaited(_runJob(record, token));
  }

  Future<void> _runJob(QueueRecord record, CancelToken token) async {
    final jobId = record.job.id;
    final item = record.item;
    await _log(
      jobId,
      'download',
      'info',
      'Download started for ${item.permalink}.',
    );

    if (item.over18 && !_settings.downloadNsfw) {
      await _queueRepository.markJobSkipped(
        jobId,
        'NSFW downloads are disabled.',
      );
      await _log(jobId, 'download', 'info', 'Skipped NSFW item.');
      _running.remove(jobId);
      return;
    }

    final engine = PathTemplateEngine(_settings);
    final assets = await _queueRepository.fetchMediaAssets(item.id);
    final exportText = _settings.exportTextPosts && item.kind == 'post';
    final exportSavedComment =
        _settings.exportSavedComments && item.kind == 'comment';
    final exportThreadComments =
        _settings.exportPostComments && item.kind == 'post';
    final totalTasks =
        assets.length +
        (exportText ? 1 : 0) +
        (exportSavedComment ? 1 : 0) +
        (exportThreadComments ? 1 : 0);

    if (totalTasks == 0) {
      await _queueRepository.markJobSkipped(
        jobId,
        'No media assets or exports enabled.',
      );
      await _log(jobId, 'download', 'warn', 'No media assets or exports.');
      _running.remove(jobId);
      return;
    }

    var completed = 0;
    var skipped = 0;
    var failed = 0;
    var finished = 0;
    String outputPath = '';

    void updateOverall(double taskProgress) {
      final overall = (finished + taskProgress) / totalTasks;
      unawaited(_queueRepository.updateJobProgress(jobId, overall.clamp(0, 1)));
    }

    for (var i = 0; i < assets.length; i++) {
      if (token.isCancelled) {
        _running.remove(jobId);
        return;
      }
      final asset = assets[i];
      final hint = asset.toolHint.toLowerCase();
      final isExternal =
          asset.type == 'external' ||
          hint.contains('gallery') ||
          hint.contains('ytdlp') ||
          hint.contains('yt-dlp');
      final isVideo = asset.type == 'video';
      final pathResult = engine.resolve(
        item: item,
        asset: asset,
        mediaIndex: i,
      );
      if (!pathResult.isValid) {
        failed += 1;
        await _log(jobId, 'download', 'error', pathResult.error ?? 'Bad path.');
        continue;
      }
      if (pathResult.warnings.isNotEmpty) {
        await _log(jobId, 'download', 'warn', pathResult.warnings.join(' • '));
      }

      final targetFile = File(pathResult.filePath);
      if (outputPath.isEmpty) {
        outputPath = pathResult.directoryPath;
      }

      try {
        final result = await _downloadWithRetry(
          targetPath: targetFile.path,
          action: () {
            if (isExternal) {
              return _externalDownloader.download(
                asset: asset,
                targetFile: targetFile,
                settings: _settings,
                policy: _policyFromSnapshot(record.job.policySnapshot),
                cancelToken: token,
                onProgress: updateOverall,
                onPhase: (phase) =>
                    _queueRepository.updateJobStatus(jobId, phase),
                log: (level, message) =>
                    _log(jobId, 'download', level, message),
              );
            }
            if (isVideo) {
              return _videoDownloader.download(
                asset: asset,
                targetFile: targetFile,
                policy: _policyFromSnapshot(record.job.policySnapshot),
                cancelToken: token,
                onHeaders: _telemetry.updateFromHeaders,
                onProgress: updateOverall,
                onPhase: (phase) =>
                    _queueRepository.updateJobStatus(jobId, phase),
                log: (level, message) =>
                    _log(jobId, 'download', level, message),
              );
            }
            return _downloader.download(
              asset: asset,
              targetFile: targetFile,
              policy: _policyFromSnapshot(record.job.policySnapshot),
              cancelToken: token,
              onHeaders: _telemetry.updateFromHeaders,
              onProgress: updateOverall,
            );
          },
        );
        if (result.isCompleted) {
          completed += 1;
          final recordedPath = result.outputPath.trim().isNotEmpty
              ? result.outputPath
              : (isExternal ? pathResult.directoryPath : targetFile.path);
          outputPath = recordedPath;
          await _recordOutput(
            jobId: jobId,
            savedItemId: item.id,
            path: recordedPath,
            kind: _assetOutputKind(asset, isExternal: isExternal),
          );
        } else if (result.isSkipped) {
          skipped += 1;
          await _log(jobId, 'download', 'info', result.message ?? 'Skipped.');
        } else {
          failed += 1;
          await _log(jobId, 'download', 'error', result.message ?? 'Failed.');
        }
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          _running.remove(jobId);
          return;
        }
        failed += 1;
        await _log(jobId, 'download', 'error', error.toString());
      } catch (error) {
        failed += 1;
        await _log(jobId, 'download', 'error', error.toString());
      }

      finished += 1;
      updateOverall(0);
      await _respectRateLimit();
      if (!token.isCancelled && _running.containsKey(jobId)) {
        await _queueRepository.updateJobStatus(jobId, 'running');
      }
    }

    if (exportText) {
      await _queueRepository.updateJobStatus(jobId, 'exporting');
      if (token.isCancelled) {
        _running.remove(jobId);
        return;
      }
      try {
        final result = await _exportWithRetry(
          action: () => _textPostExporter.export(
            item: item,
            engine: engine,
            policy: _policyFromSnapshot(record.job.policySnapshot),
          ),
        );
        if (result.isCompleted) {
          completed += 1;
          final recordedPath = result.outputPath.trim().isNotEmpty
              ? result.outputPath
              : outputPath;
          outputPath = recordedPath;
          await _recordOutput(
            jobId: jobId,
            savedItemId: item.id,
            path: recordedPath,
            kind: 'export_text',
          );
        } else if (result.isSkipped) {
          skipped += 1;
          await _log(jobId, 'download', 'info', result.message ?? 'Skipped.');
        } else {
          failed += 1;
          await _log(jobId, 'download', 'error', result.message ?? 'Failed.');
        }
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          _running.remove(jobId);
          return;
        }
        failed += 1;
        await _log(jobId, 'download', 'error', error.toString());
      }
      finished += 1;
      updateOverall(0);
      if (!token.isCancelled && _running.containsKey(jobId)) {
        await _queueRepository.updateJobStatus(jobId, 'running');
      }
    }

    if (exportSavedComment) {
      await _queueRepository.updateJobStatus(jobId, 'exporting');
      if (token.isCancelled) {
        _running.remove(jobId);
        return;
      }
      try {
        final result = await _exportWithRetry(
          action: () => _savedCommentExporter.export(
            item: item,
            engine: engine,
            policy: _policyFromSnapshot(record.job.policySnapshot),
          ),
        );
        if (result.isCompleted) {
          completed += 1;
          final recordedPath = result.outputPath.trim().isNotEmpty
              ? result.outputPath
              : outputPath;
          outputPath = recordedPath;
          await _recordOutput(
            jobId: jobId,
            savedItemId: item.id,
            path: recordedPath,
            kind: 'export_saved_comment',
          );
        } else if (result.isSkipped) {
          skipped += 1;
          await _log(jobId, 'download', 'info', result.message ?? 'Skipped.');
        } else {
          failed += 1;
          await _log(jobId, 'download', 'error', result.message ?? 'Failed.');
        }
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          _running.remove(jobId);
          return;
        }
        failed += 1;
        await _log(jobId, 'download', 'error', error.toString());
      }
      finished += 1;
      updateOverall(0);
      if (!token.isCancelled && _running.containsKey(jobId)) {
        await _queueRepository.updateJobStatus(jobId, 'running');
      }
    }

    if (exportThreadComments) {
      await _queueRepository.updateJobStatus(jobId, 'exporting');
      if (token.isCancelled) {
        _running.remove(jobId);
        return;
      }
      try {
        final result = await _exportWithRetry(
          action: () => _threadCommentsExporter.export(
            item: item,
            engine: engine,
            policy: _policyFromSnapshot(record.job.policySnapshot),
            sort: _settings.postCommentsSort,
            maxCount: _settings.postCommentsMaxCount,
            timeframeDays: _settings.postCommentsTimeframeDays,
            cancelToken: token,
          ),
        );
        if (result.isCompleted) {
          completed += 1;
          final recordedPath = result.outputPath.trim().isNotEmpty
              ? result.outputPath
              : outputPath;
          outputPath = recordedPath;
          await _recordOutput(
            jobId: jobId,
            savedItemId: item.id,
            path: recordedPath,
            kind: 'export_thread_comments',
          );
        } else if (result.isSkipped) {
          skipped += 1;
          await _log(jobId, 'download', 'info', result.message ?? 'Skipped.');
        } else {
          failed += 1;
          await _log(jobId, 'download', 'error', result.message ?? 'Failed.');
        }
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          _running.remove(jobId);
          return;
        }
        failed += 1;
        await _log(jobId, 'download', 'error', error.toString());
      }
      finished += 1;
      updateOverall(0);
      if (!token.isCancelled && _running.containsKey(jobId)) {
        await _queueRepository.updateJobStatus(jobId, 'running');
      }
    }

    if (failed > 0) {
      await _queueRepository.markJobFailed(jobId, '$failed task(s) failed.');
      await _log(
        jobId,
        'download',
        'error',
        'Job failed for ${item.permalink}.',
      );
    } else if (completed == 0) {
      await _queueRepository.markJobSkipped(
        jobId,
        skipped > 0 ? 'All tasks skipped.' : 'No outputs produced.',
      );
      await _log(
        jobId,
        'download',
        'info',
        'Job skipped for ${item.permalink}.',
      );
    } else {
      await _queueRepository.markJobCompleted(jobId, outputPath);
      await _log(
        jobId,
        'download',
        'info',
        'Job completed for ${item.permalink}.',
      );
    }
    _running.remove(jobId);
    _schedule();
  }

  Future<MediaDownloadResult> _downloadWithRetry({
    required String targetPath,
    required Future<MediaDownloadResult> Function() action,
  }) async {
    var attempt = 0;
    const maxRetries = 3;
    while (true) {
      try {
        return await action();
      } on DownloadRateLimitException catch (error) {
        await _handleRateLimit(error);
      } on DownloadHttpException catch (error) {
        if (attempt >= maxRetries) {
          return MediaDownloadResult.failed(
            'HTTP ${error.statusCode} after retries.',
            targetPath,
          );
        }
        await _backoffDelay(attempt);
        attempt += 1;
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          rethrow;
        }
        if (attempt >= maxRetries) {
          return MediaDownloadResult.failed(
            'Network error after retries.',
            targetPath,
          );
        }
        await _backoffDelay(attempt);
        attempt += 1;
      }
    }
  }

  Future<ExportResult> _exportWithRetry({
    required Future<ExportResult> Function() action,
  }) async {
    var attempt = 0;
    const maxRetries = 2;
    while (true) {
      try {
        return await action();
      } on DownloadRateLimitException catch (error) {
        await _handleRateLimit(error);
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          rethrow;
        }
        if (attempt >= maxRetries) {
          return ExportResult.failed('Network error after retries.', '');
        }
        await _backoffDelay(attempt);
        attempt += 1;
      } catch (error) {
        return ExportResult.failed(error.toString(), '');
      }
    }
  }

  Future<void> _handleRateLimit(DownloadRateLimitException error) async {
    final delay = error.retryAfterSeconds ?? 10;
    await _log(
      null,
      'download',
      'warn',
      'Rate limited. Retrying after ${delay}s.',
    );
    await Future.delayed(Duration(seconds: delay));
  }

  Future<void> _backoffDelay(int attempt) async {
    final base = 500 * pow(2, attempt);
    final jitter = Random().nextInt(250);
    await Future.delayed(Duration(milliseconds: base.toInt() + jitter));
  }

  Future<void> _respectRateLimit() async {
    final rate = _settings.rateLimitPerMinute;
    if (rate <= 0) {
      return;
    }
    final delayMs = (60000 / rate).round();
    await Future.delayed(Duration(milliseconds: delayMs));
  }

  OverwritePolicy _policyFromSnapshot(String snapshot) {
    switch (snapshot) {
      case 'overwrite_if_newer':
        return OverwritePolicy.overwriteIfNewer;
      case 'skip_if_exists':
      default:
        return OverwritePolicy.skipIfExists;
    }
  }

  String _assetOutputKind(MediaAsset asset, {required bool isExternal}) {
    if (isExternal) {
      return 'external_media';
    }
    if (asset.type == 'video') {
      return 'video';
    }
    return 'media_${asset.type}';
  }

  Future<void> _recordOutput({
    required int jobId,
    required int savedItemId,
    required String path,
    required String kind,
  }) async {
    try {
      await _queueRepository.recordJobOutput(
        jobId: jobId,
        savedItemId: savedItemId,
        path: path,
        kind: kind,
      );
    } catch (error) {
      await _log(
        jobId,
        'download',
        'warn',
        'Failed to record output path "$path": $error',
      );
    }
  }

  Future<void> _log(
    int? jobId,
    String scope,
    String level,
    String message,
  ) async {
    final prefix = jobId == null ? '' : '[job $jobId] ';
    await _logsRepository.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: scope,
        level: level,
        message: '$prefix$message',
      ),
    );
  }
}

extension on Iterable<QueueRecord> {
  QueueRecord? get firstOrNull => isEmpty ? null : first;
}

const _activeStatuses = {'running', 'merging', 'running_tool', 'exporting'};
