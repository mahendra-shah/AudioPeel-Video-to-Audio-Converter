import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../models/audio_file.dart';
import '../models/audio_quality.dart';
import '../models/conversion_task.dart';
import '../services/database_service.dart';
import '../services/ffmpeg_service.dart';
import '../services/storage_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';

/// Manages the full lifecycle of a single video-to-MP3 conversion.
///
/// Exposes read-only state via getters and mutation via public methods.
class ConversionProvider extends ChangeNotifier {
  ConversionProvider({
    FFmpegService? ffmpegService,
    StorageService? storageService,
    DatabaseService? databaseService,
  }) : _ffmpegService = ffmpegService ?? FFmpegService(),
       _storageService = storageService ?? StorageService(),
       _databaseService = databaseService ?? DatabaseService.instance;

  final FFmpegService _ffmpegService;
  final StorageService _storageService;
  final DatabaseService _databaseService;

  // ─── State ──────────────────────────────────────────────────────────

  ConversionTask? _task;
  File? _selectedVideo;
  String _outputName = '';
  AudioQuality _quality = AudioQuality.medium192;
  int _videoDurationMs = 0;
  int _videoSizeBytes = 0;

  // ─── Getters ────────────────────────────────────────────────────────

  /// The current conversion task, or `null` if none is active / set up.
  ConversionTask? get task => _task;

  /// The user-selected video file.
  File? get selectedVideo => _selectedVideo;

  /// The output file name (without extension).
  String get outputName => _outputName;

  /// The selected audio quality.
  AudioQuality get quality => _quality;

  /// Video duration in milliseconds.
  int get videoDurationMs => _videoDurationMs;

  /// Video file size in bytes.
  int get videoSizeBytes => _videoSizeBytes;

  /// Whether a conversion is currently in progress.
  bool get isConverting =>
      _task != null && _task!.status == ConversionStatus.converting;

  /// Current progress from `0.0` to `1.0`.
  double get progress => _task?.progress ?? 0.0;

  /// Error message from the last conversion attempt, if any.
  String? get error => _task?.errorMessage;

  /// Whether a video has been selected and is ready for conversion.
  bool get isReadyToConvert => _selectedVideo != null && _outputName.isNotEmpty;

  // ─── Actions ────────────────────────────────────────────────────────

  /// Opens the system file picker and selects a video file.
  Future<void> selectVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final path = result.files.single.path!;
      _selectedVideo = File(path);
      _outputName = FileUtils.defaultOutputName(path);

      // Fetch video metadata.
      final metadata = await _ffmpegService.getVideoMetadata(path);
      _videoDurationMs = metadata?.durationMs ?? 0;
      _videoSizeBytes = metadata?.fileSize ?? _selectedVideo!.lengthSync();

      // Reset any previous task.
      _task = null;

      Logger.info(
        'Selected video: ${result.files.single.name} '
            '(${_videoDurationMs}ms, ${_videoSizeBytes}B)',
        'ConversionProvider',
      );

      notifyListeners();
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to select video',
        error: e,
        stackTrace: st,
        tag: 'ConversionProvider',
      );
    }
  }

  /// Updates the output file name.
  void updateOutputName(String name) {
    _outputName = name;
    notifyListeners();
  }

  /// Changes the selected audio quality.
  void selectQuality(AudioQuality quality) {
    _quality = quality;
    notifyListeners();
  }

  /// Starts the conversion. Must have a selected video and output name.
  ///
  /// If [autoDeleteOriginal] is `true`, the source video file is
  /// deleted after a successful conversion. When [normalizeVolume] is
  /// `true` the FFmpeg `loudnorm` filter is applied.
  Future<void> startConversion({
    bool autoDeleteOriginal = false,
    bool normalizeVolume = false,
  }) async {
    if (_selectedVideo == null || _outputName.isEmpty) return;

    // Verify there is enough disk space before starting.
    final hasSpace = await _storageService.hasEnoughSpace();
    if (!hasSpace) {
      _task = ConversionTask(
        inputVideoPath: _selectedVideo!.path,
        inputVideoName: _selectedVideo!.uri.pathSegments.last,
        outputAudioPath: '',
        outputAudioName: '$_outputName.mp3',
        quality: _quality,
        videoDurationMs: _videoDurationMs,
        status: ConversionStatus.failed,
        errorMessage:
            'Not enough storage space. Free up at least 50 MB and try again.',
      );
      notifyListeners();
      return;
    }

    final outputPath = await _storageService.uniqueOutputPath(_outputName);

    _task = ConversionTask(
      inputVideoPath: _selectedVideo!.path,
      inputVideoName: _selectedVideo!.uri.pathSegments.last,
      outputAudioPath: outputPath,
      outputAudioName: '$_outputName.mp3',
      quality: _quality,
      videoDurationMs: _videoDurationMs,
      status: ConversionStatus.converting,
    );
    notifyListeners();

    try {
      final result = await _ffmpegService.convertVideoToMp3(
        inputPath: _selectedVideo!.path,
        outputPath: outputPath,
        quality: _quality,
        videoDurationMs: _videoDurationMs,
        normalizeVolume: normalizeVolume,
        onProgress: _onProgress,
      );

      if (result.success) {
        final fileSize = _storageService.fileSize(outputPath);
        final durationSec = (_videoDurationMs / 1000).round();

        // Persist to history.
        final audioFile = AudioFile(
          inputVideoName: _task!.inputVideoName,
          inputVideoPath: _task!.inputVideoPath,
          outputAudioName: _task!.outputAudioName,
          outputAudioPath: outputPath,
          quality: _quality,
          fileSize: fileSize,
          duration: durationSec,
          status: 'completed',
          createdAt: DateTime.now(),
        );
        await _databaseService.insertConversion(audioFile);

        // Delete the source video if requested.
        if (autoDeleteOriginal) {
          await _storageService.deleteFile(_selectedVideo!.path);
          Logger.info('Auto-deleted original video', 'ConversionProvider');
        }

        _task = _task!.copyWith(
          status: ConversionStatus.completed,
          progress: 1.0,
        );
      } else {
        // Clean up partial output file.
        await _storageService.deleteFile(outputPath);

        _task = _task!.copyWith(
          status: result.errorMessage?.contains('cancelled') == true
              ? ConversionStatus.cancelled
              : ConversionStatus.failed,
          errorMessage: result.errorMessage,
        );
      }
    } on Exception catch (e, st) {
      Logger.error(
        'Unexpected conversion error',
        error: e,
        stackTrace: st,
        tag: 'ConversionProvider',
      );
      await _storageService.deleteFile(outputPath);
      _task = _task!.copyWith(
        status: ConversionStatus.failed,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
    notifyListeners();
  }

  /// Cancels the active conversion.
  Future<void> cancelConversion() async {
    await _ffmpegService.cancelConversion();
  }

  /// Resets all state so the user can start a new conversion.
  void reset() {
    _task = null;
    _selectedVideo = null;
    _outputName = '';
    _videoDurationMs = 0;
    _videoSizeBytes = 0;
    notifyListeners();
  }

  // ─── Private ────────────────────────────────────────────────────────

  void _onProgress(double progress) {
    _task = _task?.copyWith(progress: progress);
    notifyListeners();
  }
}
