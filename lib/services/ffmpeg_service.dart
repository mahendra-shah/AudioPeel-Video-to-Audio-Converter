import 'dart:async';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../constants/app_constants.dart';
import '../models/audio_format.dart';
import '../models/audio_quality.dart';
import '../utils/logger.dart';

/// Result of a completed FFmpeg conversion.
class ConversionResult {
  const ConversionResult({
    required this.success,
    this.outputPath,
    this.errorMessage,
  });

  /// Whether the conversion completed successfully.
  final bool success;

  /// The path to the generated MP3 file (null on failure).
  final String? outputPath;

  /// Human-readable error description (null on success).
  final String? errorMessage;
}

/// Metadata extracted from a video file.
class VideoMetadata {
  const VideoMetadata({required this.durationMs, required this.fileSize});

  /// Video duration in milliseconds.
  final int durationMs;

  /// File size in bytes.
  final int fileSize;
}

/// Wraps FFmpeg Kit to convert videos to MP3 files.
///
/// Provides progress callbacks, cancellation, and metadata extraction.
class FFmpegService {
  FFmpegSession? _activeSession;

  /// Whether a conversion is currently running.
  bool get isConverting => _activeSession != null;

  /// Converts the video at [inputPath] to MP3 at [outputPath] with the
  /// given [quality].
  ///
  /// [onProgress] receives values from `0.0` to `1.0`.
  /// [videoDurationMs] is required to calculate progress percentage.
  /// If [normalizeVolume] is `true`, the `loudnorm` filter is applied.
  ///
  /// The conversion is automatically cancelled if it exceeds
  /// [AppConstants.conversionTimeout].
  ///
  /// Returns a [ConversionResult] indicating success or failure.
  Future<ConversionResult> convertVideoToAudio({
    required String inputPath,
    required String outputPath,
    required AudioFormat format,
    required AudioQuality quality,
    required int videoDurationMs,
    bool normalizeVolume = false,
    void Function(double progress)? onProgress,
  }) async {
    if (_activeSession != null) {
      return const ConversionResult(
        success: false,
        errorMessage: 'A conversion is already in progress.',
      );
    }

    final audioFilter = normalizeVolume ? '-af loudnorm ' : '';

    // Build format-specific FFmpeg parameters
    // Using simpler codec names that are more widely supported
    String codecParams;
    String formatParam = '';

    switch (format) {
      case AudioFormat.mp3:
        codecParams = '-c:a libmp3lame -q:a 2 -b:a ${quality.kbps}k';
      case AudioFormat.aac:
        // Raw AAC file - using native aac encoder
        codecParams = '-c:a aac -b:a ${quality.kbps}k -strict experimental';
        formatParam = '-f adts'; // ADTS format for raw AAC
      case AudioFormat.opus:
        // Opus audio
        codecParams = '-c:a libopus -b:a ${quality.kbps}k -vbr on';
        formatParam = '-f opus';
      case AudioFormat.flac:
        // FLAC lossless
        codecParams = '-c:a flac -compression_level 8';
      case AudioFormat.wav:
        // WAV uncompressed
        codecParams = '-c:a pcm_s16le';
        formatParam = '-f wav';
      case AudioFormat.ogg:
        // OGG Vorbis
        codecParams = '-c:a libvorbis -q:a 6 -b:a ${quality.kbps}k';
        formatParam = '-f ogg';
      case AudioFormat.m4a:
        // M4A (AAC in MP4 container)
        codecParams = '-c:a aac -b:a ${quality.kbps}k -strict experimental';
        formatParam = '-f mp4';
      case AudioFormat.wma:
        // WMA - fallback to AAC in M4A if WMA not available
        codecParams = '-c:a aac -b:a ${quality.kbps}k -strict experimental';
        formatParam = '-f mp4';
        Logger.warning(
          'WMA codec may not be supported, using AAC fallback',
          'FFmpegService',
        );
    }

    final command =
        '-i "$inputPath" -vn '
        '$audioFilter'
        '-ar ${AppConstants.audioSampleRate} '
        '-ac ${AppConstants.audioChannels} '
        '$codecParams '
        '${formatParam.isNotEmpty ? "$formatParam " : ""}'
        '-y '
        '"$outputPath"';

    Logger.info(
      'Starting conversion to ${format.displayName}: $command',
      'FFmpegService',
    );

    // Enable statistics so progress callbacks fire.
    await FFmpegKitConfig.enableStatistics();

    final completer = Completer<ConversionResult>();

    // Safety timer — cancel FFmpeg if it runs too long.
    final timeoutTimer = Timer(AppConstants.conversionTimeout, () {
      if (!completer.isCompleted) {
        Logger.warning('Conversion timed out — cancelling', 'FFmpegService');
        cancelConversion();
      }
    });

    _activeSession = await FFmpegKit.executeAsync(
      command,
      // Completion callback.
      (session) async {
        timeoutTimer.cancel();
        _activeSession = null;
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          Logger.info('Conversion succeeded: $outputPath', 'FFmpegService');
          if (!completer.isCompleted) {
            completer.complete(
              ConversionResult(success: true, outputPath: outputPath),
            );
          }
        } else if (ReturnCode.isCancel(returnCode)) {
          Logger.info('Conversion cancelled', 'FFmpegService');
          if (!completer.isCompleted) {
            completer.complete(
              const ConversionResult(
                success: false,
                errorMessage: 'Conversion was cancelled.',
              ),
            );
          }
        } else {
          final logs = await session.getAllLogsAsString();
          Logger.error('Conversion failed: $logs', tag: 'FFmpegService');
          if (!completer.isCompleted) {
            completer.complete(
              ConversionResult(
                success: false,
                errorMessage: _userFriendlyError(logs),
              ),
            );
          }
        }
      },
      // Log callback.
      (log) {
        Logger.debug(log.getMessage(), 'FFmpegLog');
      },
      // Statistics callback (progress).
      (statistics) {
        if (videoDurationMs > 0) {
          final timeMs = statistics.getTime();
          if (timeMs > 0) {
            final progress = (timeMs / videoDurationMs).clamp(0.0, 1.0);
            onProgress?.call(progress);
          }
        }
      },
    );

    return completer.future;
  }

  /// Maps raw FFmpeg log output to a concise, user-friendly message.
  static String _userFriendlyError(String? logs) {
    if (logs == null || logs.isEmpty) {
      return 'Conversion failed. Please try again.';
    }

    final lower = logs.toLowerCase();

    if (lower.contains('no such file') || lower.contains('does not exist')) {
      return 'The selected video file could not be found.';
    }
    if (lower.contains('invalid data') || lower.contains('moov atom')) {
      return 'The video file appears to be corrupt or unsupported.';
    }
    if (lower.contains('encoder') && lower.contains('not found')) {
      return 'The selected audio format is not supported by your device. Please try MP3 or AAC.';
    }
    if (lower.contains('codec') || lower.contains('decoder')) {
      return 'This video or audio format is not supported. Please try MP3.';
    }
    if (lower.contains('permission denied')) {
      return 'Storage permission denied. Please grant access in settings.';
    }
    if (lower.contains('no space left')) {
      return 'Not enough storage space. Free up some space and try again.';
    }
    if (lower.contains('unknown encoder') ||
        lower.contains('encoder not found')) {
      return 'This audio format is not supported. Please try MP3 or M4A.';
    }

    // Include a snippet of the actual error for debugging
    final lines = logs.split('\n');
    final errorLines = lines
        .where(
          (line) =>
              line.toLowerCase().contains('error') ||
              line.toLowerCase().contains('failed') ||
              line.toLowerCase().contains('unable'),
        )
        .take(2);

    if (errorLines.isNotEmpty) {
      Logger.error(
        'FFmpeg error details: ${errorLines.join("; ")}',
        tag: 'FFmpegService',
      );
    }

    return 'Conversion failed. Please try a different format or contact support.';
  }

  /// Cancels the currently running conversion, if any.
  Future<void> cancelConversion() async {
    final session = _activeSession;
    if (session != null) {
      Logger.info('Cancelling active conversion', 'FFmpegService');
      await FFmpegKit.cancel(session.getSessionId());
      _activeSession = null;
    }
  }

  /// Extracts duration and file size metadata from a video file.
  ///
  /// Returns `null` if the file cannot be probed.
  Future<VideoMetadata?> getVideoMetadata(String videoPath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(videoPath);
      final info = session.getMediaInformation();

      if (info == null) {
        Logger.warning(
          'Could not read metadata for $videoPath',
          'FFmpegService',
        );
        return null;
      }

      final durationStr = info.getDuration();
      final durationMs = durationStr != null
          ? (double.tryParse(durationStr) ?? 0.0) * 1000
          : 0.0;

      final sizeStr = info.getSize();
      final fileSize = sizeStr != null ? int.tryParse(sizeStr) ?? 0 : 0;

      return VideoMetadata(durationMs: durationMs.round(), fileSize: fileSize);
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to get metadata',
        error: e,
        stackTrace: st,
        tag: 'FFmpegService',
      );
      return null;
    }
  }
}
