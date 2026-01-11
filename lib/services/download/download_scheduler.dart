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
import '../path_template_engine.dart';
import 'download_telemetry.dart';
import 'http_media_downloader.dart';
import 'overwrite_policy.dart';

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
  })  : _queueRepository = queueRepository,
        _settingsRepository = settingsRepository,
        _logsRepository = logsRepository,
        _sessionRepository = sessionRepository,
        _telemetry = telemetry {
    _settings = AppSettings.defaults();
    _dio = dio ??
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
  }

  final QueueRepository _queueRepository;
  final SettingsRepository _settingsRepository;
  final LogsRepository _logsRepository;
  final SessionRepository _sessionRepository;
  final DownloadTelemetry _telemetry;

  late final Dio _dio;
  late final OverwritePolicyEvaluator _policyEvaluator;
  late final HttpMediaDownloader _downloader;

  late AppSettings _settings;
  StreamSubscription<AppSettings>? _settingsSubscription;
  StreamSubscription<List<QueueRecord>>? _queueSubscription;
  final Map<int, CancelToken> _running = {};
  List<QueueRecord> _latestQueue = [];
  bool _isDisposed = false;

  void start() {
    _settingsSubscription =
        _settingsRepository.watch().listen(_handleSettings);
    _queueSubscription =
        _queueRepository.watchQueue().listen(_handleQueue);
  }

  Future<void> dispose() async {
    _isDisposed = true;
    for (final token in _running.values) {
      token.cancel('Scheduler disposed.');
    }
    await _settingsSubscription?.cancel();
    await _queueSubscription?.cancel();
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
      if (record.job.status != 'running') {
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
        .take(available)
        .toList();
    for (final record in queued) {
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
    await _log(jobId, 'download', 'info', 'Download started for ${item.permalink}.');

    if (item.over18 && !_settings.downloadNsfw) {
      await _queueRepository.markJobSkipped(
        jobId,
        'NSFW downloads are disabled.',
      );
      await _log(jobId, 'download', 'info', 'Skipped NSFW item.');
      _running.remove(jobId);
      return;
    }

    final assets = await _queueRepository.fetchMediaAssets(item.id);
    if (assets.isEmpty) {
      await _queueRepository.markJobSkipped(
        jobId,
        'No media assets available.',
      );
      await _log(jobId, 'download', 'warn', 'No media assets for job.');
      _running.remove(jobId);
      return;
    }

    final engine = PathTemplateEngine(_settings);
    var completed = 0;
    var skipped = 0;
    var failed = 0;
    String outputPath = '';

    for (var i = 0; i < assets.length; i++) {
      if (token.isCancelled) {
        _running.remove(jobId);
        return;
      }
      final asset = assets[i];
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
        await _log(
          jobId,
          'download',
          'warn',
          pathResult.warnings.join(' • '),
        );
      }

      final targetFile = File(pathResult.filePath);
      if (outputPath.isEmpty) {
        outputPath = pathResult.directoryPath;
      }

      try {
        final result = await _downloadWithRetry(
          asset: asset,
          targetFile: targetFile,
          policy: _policyFromSnapshot(record.job.policySnapshot),
          cancelToken: token,
          onProgress: (progress) async {
            final overall = (completed + progress) / assets.length;
            await _queueRepository.updateJobProgress(jobId, overall);
          },
        );
        if (result.isCompleted) {
          completed += 1;
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

      final overall = (completed + skipped + failed) / assets.length;
      await _queueRepository.updateJobProgress(jobId, overall.clamp(0, 1));
      await _respectRateLimit();
    }

    if (failed > 0) {
      await _queueRepository.markJobFailed(
        jobId,
        '$failed asset(s) failed.',
      );
      await _log(jobId, 'download', 'error', 'Job failed for ${item.permalink}.');
    } else if (completed == 0) {
      await _queueRepository.markJobSkipped(
        jobId,
        skipped > 0 ? 'All assets skipped.' : 'No assets downloaded.',
      );
      await _log(jobId, 'download', 'info', 'Job skipped for ${item.permalink}.');
    } else {
      await _queueRepository.markJobCompleted(jobId, outputPath);
      await _log(jobId, 'download', 'info', 'Job completed for ${item.permalink}.');
    }
    _running.remove(jobId);
    _schedule();
  }

  Future<MediaDownloadResult> _downloadWithRetry({
    required MediaAsset asset,
    required File targetFile,
    required OverwritePolicy policy,
    required CancelToken cancelToken,
    required void Function(double progress) onProgress,
  }) async {
    var attempt = 0;
    const maxRetries = 3;
    while (true) {
      try {
        return await _downloader.download(
          asset: asset,
          targetFile: targetFile,
          policy: policy,
          cancelToken: cancelToken,
          onHeaders: _telemetry.updateFromHeaders,
          onProgress: onProgress,
        );
      } on DownloadRateLimitException catch (error) {
        await _handleRateLimit(error);
      } on DownloadHttpException catch (error) {
        if (attempt >= maxRetries) {
          return MediaDownloadResult.failed(
            'HTTP ${error.statusCode} after retries.',
            targetFile.path,
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
            targetFile.path,
          );
        }
        await _backoffDelay(attempt);
        attempt += 1;
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

  Future<void> _log(
    int? jobId,
    String scope,
    String level,
    String message,
  ) async {
    await _logsRepository.add(
      LogRecord(
        timestamp: DateTime.now(),
        scope: scope,
        level: level,
        message: message,
        relatedJobId: jobId,
      ),
    );
  }
}

extension on Iterable<QueueRecord> {
  QueueRecord? get firstOrNull => isEmpty ? null : first;
}
