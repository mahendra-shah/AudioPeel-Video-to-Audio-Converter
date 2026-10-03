import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../constants/app_constants.dart';
import '../models/audio_file.dart';
import '../models/convert_options.dart';
import '../models/job.dart';
import '../models/media_item.dart';
import '../services/database_service.dart';
import '../services/ffmpeg_service.dart';
import '../services/media_bridge.dart';
import '../services/notification_service.dart';
import '../utils/format_utils.dart';
import '../utils/logger.dart';
import 'history_provider.dart';

/// Runs conversion jobs one after another — a single Studio export is just a
/// queue of one.
class QueueProvider extends ChangeNotifier {
  QueueProvider({
    required HistoryProvider history,
    FFmpegService? ffmpeg,
    DatabaseService? database,
    NotificationService? notifications,
  }) : _history = history,
       _ffmpeg = ffmpeg ?? FFmpegService(),
       _db = database ?? DatabaseService.instance,
       _notifications = notifications ?? NotificationService.instance;

  final HistoryProvider _history;
  final FFmpegService _ffmpeg;
  final DatabaseService _db;
  final NotificationService _notifications;

  final List<Job> _jobs = [];
  int _nextId = 1;
  bool _running = false;
  bool _cancelRequested = false;

  List<Job> get jobs => List.unmodifiable(_jobs);
  bool get isRunning => _running;
  bool get isBatch => _jobs.length > 1;

  /// Whole-queue progress, 0–1, weighted by output duration.
  double get overallProgress {
    if (_jobs.isEmpty) return 0;
    var total = 0.0;
    var done = 0.0;
    for (final j in _jobs) {
      final w = j.options.outputDurationMs(j.media).clamp(1, 1 << 31).toDouble();
      total += w;
      done += w * (j.isFinished ? 1 : j.progress);
    }
    return done / total;
  }

  int get doneCount => _jobs.where((j) => j.status == JobStatus.done).length;
  int get failedCount => _jobs.where((j) => j.status == JobStatus.failed).length;
  bool get allFinished => _jobs.isNotEmpty && _jobs.every((j) => j.isFinished);

  /// Replaces the queue with [items] (sharing [options]) and starts it.
  ///
  /// [names] optionally overrides the output name per item.
  Future<void> start(
    List<MediaItem> items,
    ConvertOptions options, {
    List<String>? names,
  }) async {
    if (_running) return;
    _jobs
      ..clear()
      ..addAll([
        for (var i = 0; i < items.length; i++)
          Job(
            id: _nextId++,
            media: items[i],
            options: names != null && i < names.length
                ? options.copyWith(fileName: names[i])
                : options,
          ),
      ]);
    notifyListeners();
    await _runAll();
  }

  /// Re-runs one failed/cancelled job with (optionally) new options.
  Future<void> retry(Job job, {ConvertOptions? options}) async {
    if (_running) return;
    final index = _jobs.indexOf(job);
    if (index < 0) return;
    _jobs[index] = Job(
      id: _nextId++,
      media: job.media,
      options: options ?? job.options,
    );
    notifyListeners();
    await _runAll();
  }

  Future<void> cancelAll() async {
    _cancelRequested = true;
    for (final j in _jobs) {
      if (j.status == JobStatus.queued) j.status = JobStatus.cancelled;
      if (j.status == JobStatus.running && j.sessionId != null) {
        await _ffmpeg.cancel(j.sessionId!);
      }
    }
    await _notifications.cancelProgressNotification();
    notifyListeners();
  }

  /// Clears finished jobs (when leaving the Job screen).
  void clear() {
    if (_running) return;
    _jobs.clear();
    notifyListeners();
  }

  // ─── Engine ──────────────────────────────────────────────────────────

  Future<void> _runAll() async {
    _running = true;
    _cancelRequested = false;
    notifyListeners();
    unawaited(WakelockPlus.enable().catchError((_) {}));
    unawaited(_notifications.requestPermission());

    if (!await _ensureLegacyStorage()) {
      for (final j in _jobs.where((j) => !j.isFinished)) {
        j
          ..status = JobStatus.failed
          ..error = 'Storage permission is needed to save to Music.';
      }
      _finishQueue();
      return;
    }

    for (final job in _jobs) {
      if (_cancelRequested) break;
      if (job.status != JobStatus.queued) continue;
      await _run(job);
    }
    _finishQueue();
  }

  void _finishQueue() {
    _running = false;
    unawaited(WakelockPlus.disable().catchError((_) {}));
    notifyListeners();
    unawaited(_history.refresh());
  }

  Future<void> _run(Job job) async {
    job
      ..status = JobStatus.running
      ..startedAt = DateTime.now()
      ..progress = 0;
    notifyListeners();

    final work = await _workDir();
    final temp = p.join(work, 'job_${job.id}.${job.options.format.extension}');
    String? cover;

    try {
      if (!job.media.hasAudio) {
        throw const _JobError("This video doesn't have a sound track.");
      }

      if (job.options.embedsArt(job.media)) {
        cover = await _writeCover(job, work);
      }

      final result = await _ffmpeg.convert(
        media: job.media,
        options: job.options,
        outputPath: temp,
        coverPath: cover,
        onSession: (id) => job.sessionId = id,
        onProgress: (value) {
          job.progress = value;
          notifyListeners();
          _notifyProgress(job);
        },
      );

      if (result.cancelled) {
        job.status = JobStatus.cancelled;
      } else if (!result.success) {
        throw _JobError(result.errorMessage ?? 'Conversion failed.');
      } else {
        final entry = await MediaBridge.saveToLibrary(
          tempPath: temp,
          name: job.outputName,
          mime: job.options.format.mime,
        );
        final durationMs = job.options.outputDurationMs(job.media);
        job
          ..result = SavedAudio(
            uri: entry.uri,
            name: entry.name,
            displayPath: entry.displayPath,
            sizeBytes: entry.sizeBytes,
            durationMs: durationMs,
            format: job.options.format,
          )
          ..progress = 1
          ..status = JobStatus.done;

        await _db.insertConversion(
          AudioFile(
            inputVideoName: job.media.name,
            inputVideoPath: job.media.uri,
            outputAudioName: entry.name,
            outputAudioPath: entry.uri,
            quality: job.options.quality,
            fileSize: entry.sizeBytes,
            duration: (durationMs / 1000).round(),
            status: 'completed',
            createdAt: DateTime.now(),
            format: job.options.format,
            displayPath: entry.displayPath,
          ),
        );
        await _bumpSuccessCount();
        if (!isBatch) {
          await _notifications.showCompletionNotification(fileName: entry.name);
        }
      }
    } on _JobError catch (e) {
      job
        ..status = JobStatus.failed
        ..error = e.message;
    } on Exception catch (e, st) {
      Logger.error('Job failed', error: e, stackTrace: st, tag: 'Queue');
      job
        ..status = JobStatus.failed
        ..error = 'Could not save the audio. Please try again.';
    } finally {
      job
        ..finishedAt = DateTime.now()
        ..sessionId = null;
      _cleanup([temp, ?cover]);
      if (job.status == JobStatus.failed) {
        await _notifications.showErrorNotification(
          fileName: job.media.name,
          errorMessage: job.error,
        );
      } else if (job.status == JobStatus.cancelled) {
        await _notifications.cancelProgressNotification();
      }
      notifyListeners();
    }
  }

  void _notifyProgress(Job job) {
    final eta = job.eta;
    final label = isBatch
        ? '${_jobs.indexOf(job) + 1} of ${_jobs.length} · ${job.media.name}'
        : job.media.name;
    _notifications.showProgressNotification(
      fileName: label,
      progress: isBatch ? overallProgress : job.progress,
      estimatedTimeRemaining: eta == null
          ? 'Calculating…'
          : FormatUtils.duration(eta.inSeconds),
    );
  }

  Future<String?> _writeCover(Job job, String work) async {
    final media = job.media;
    final mid =
        job.options.trimStartMs + job.options.outputDurationMs(media) ~/ 3;
    final bytes = await MediaBridge.thumbnail(media.uri, ms: mid, width: 600);
    if (bytes == null || bytes.isEmpty) return null;
    final path = p.join(work, 'cover_${job.id}.jpg');
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<bool> _ensureLegacyStorage() async {
    if (!Platform.isAndroid) return true;
    if (await MediaBridge.sdkInt() >= 29) return true;
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _bumpSuccessCount() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getInt(AppConstants.prefTotalConversions) ?? 0;
    await prefs.setInt(AppConstants.prefTotalConversions, n + 1);
  }

  static Future<String> _workDir() async {
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'work'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir.path;
  }

  /// Removes leftovers from interrupted conversions (call at startup).
  static Future<void> sweepWorkDir() async {
    try {
      final dir = Directory(await _workDir());
      await for (final e in dir.list()) {
        await e.delete(recursive: true);
      }
    } on Exception catch (e) {
      Logger.warning('sweep failed: $e', 'Queue');
    }
  }

  void _cleanup(List<String> paths) {
    for (final path in paths) {
      final f = File(path);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } on FileSystemException catch (_) {}
      }
    }
  }
}

class _JobError implements Exception {
  const _JobError(this.message);
  final String message;
}
