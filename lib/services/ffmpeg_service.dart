import 'dart:async';
import 'dart:math' as math;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../models/convert_options.dart';
import '../models/media_item.dart';
import '../models/output_format.dart';
import '../utils/logger.dart';

/// Result of a completed FFmpeg conversion.
class ConversionResult {
  const ConversionResult({
    required this.success,
    this.cancelled = false,
    this.errorMessage,
  });

  final bool success;
  final bool cancelled;

  /// Human-readable error description (null on success).
  final String? errorMessage;
}

/// Turns [ConvertOptions] into FFmpeg arguments and runs them.
///
/// Input is read straight from the `content://` URI through SAF, so large
/// videos are never copied.
class FFmpegService {
  /// Builds the FFmpeg argument list. Exposed for unit tests.
  static List<String> buildArguments({
    required String input,
    required MediaItem media,
    required ConvertOptions options,
    required String outputPath,
    String? coverPath,
  }) {
    final args = <String>['-hide_banner', '-y'];

    // Fast input seek for trims.
    if (options.isTrimmed(media)) {
      args.addAll(['-ss', _seconds(options.trimStartMs)]);
      args.addAll(['-t', _seconds(options.outputDurationMs(media))]);
    }
    args.addAll(['-i', input]);

    final withCover = coverPath != null && options.embedsArt(media);
    if (withCover) args.addAll(['-i', coverPath]);

    args.addAll(['-map', '0:a:0']);
    if (withCover) {
      args.addAll([
        '-map', '1:0', //
        '-c:v', 'mjpeg',
        '-disposition:v:0', 'attached_pic',
        '-metadata:s:v', 'title=Album cover',
        '-metadata:s:v', 'comment=Cover (front)',
      ]);
    }
    args.addAll(['-sn', '-dn']);

    final filters = _filters(media, options);
    final copy = options.canStreamCopy(media);
    if (filters.isNotEmpty && !copy) args.addAll(['-af', filters.join(',')]);

    switch (options.format) {
      case OutputFormat.mp3:
        args.addAll([
          '-c:a', 'libmp3lame', //
          '-b:a', '${options.quality.kbps}k',
          '-ar', '44100',
          '-id3v2_version', '3',
        ]);
      case OutputFormat.m4a:
        if (copy) {
          args.addAll(['-c:a', 'copy']);
        } else {
          args.addAll(['-c:a', 'aac', '-b:a', '${options.quality.kbps}k']);
        }
        args.addAll(['-movflags', '+faststart']);
      case OutputFormat.wav:
        args.addAll(['-c:a', 'pcm_s16le', '-ar', '44100']);
      case OutputFormat.flac:
        args.addAll(['-c:a', 'flac', '-ar', '44100']);
    }

    if (options.title.trim().isNotEmpty) {
      args.addAll(['-metadata', 'title=${options.title.trim()}']);
    }
    if (options.artist.trim().isNotEmpty) {
      args.addAll(['-metadata', 'artist=${options.artist.trim()}']);
    }

    args.add(outputPath);
    return args;
  }

  static List<String> _filters(MediaItem media, ConvertOptions o) {
    final f = <String>[];
    if (o.normalize) f.add('loudnorm=I=-16:TP=-1.5:LRA=11');
    if (o.volume != 1.0) f.add('volume=${o.volume.toStringAsFixed(2)}');
    final dur = o.outputDurationMs(media) / 1000;
    final fade = math.min(ConvertOptions.fadeSeconds, dur / 3);
    if (o.fadeIn && fade > 0.1) f.add('afade=t=in:st=0:d=${fade.toStringAsFixed(2)}');
    if (o.fadeOut && fade > 0.1) {
      final st = (dur - fade).clamp(0, dur);
      f.add(
        'afade=t=out:st=${st.toStringAsFixed(2)}:d=${fade.toStringAsFixed(2)}',
      );
    }
    return f;
  }

  static String _seconds(int ms) => (ms / 1000).toStringAsFixed(3);

  /// Converts [media] to [outputPath]. [onSession] receives the session id
  /// so the caller can cancel.
  Future<ConversionResult> convert({
    required MediaItem media,
    required ConvertOptions options,
    required String outputPath,
    String? coverPath,
    void Function(double progress)? onProgress,
    void Function(int sessionId)? onSession,
  }) async {
    final input = media.isContentUri
        ? await FFmpegKitConfig.getSafParameterForRead(media.uri)
        : media.uri;
    if (input == null || input.isEmpty) {
      return const ConversionResult(
        success: false,
        errorMessage: 'This video can no longer be opened. Pick it again.',
      );
    }

    final args = buildArguments(
      input: input,
      media: media,
      options: options,
      outputPath: outputPath,
      coverPath: coverPath,
    );
    Logger.info('ffmpeg ${args.join(' ')}', 'FFmpegService');

    await FFmpegKitConfig.enableStatistics();
    final totalMs = options.outputDurationMs(media);
    final completer = Completer<ConversionResult>();

    // Generous, duration-aware safety net (never shorter than 10 minutes).
    final timeout = Duration(
      milliseconds: math.max(10 * 60 * 1000, totalMs * 3),
    );
    int? sessionId;
    final timer = Timer(timeout, () {
      if (!completer.isCompleted && sessionId != null) {
        Logger.warning('Conversion timed out — cancelling', 'FFmpegService');
        FFmpegKit.cancel(sessionId);
      }
    });

    final session = await FFmpegKit.executeWithArgumentsAsync(
      args,
      (session) async {
        timer.cancel();
        final rc = await session.getReturnCode();
        if (completer.isCompleted) return;
        if (ReturnCode.isSuccess(rc)) {
          completer.complete(const ConversionResult(success: true));
        } else if (ReturnCode.isCancel(rc)) {
          completer.complete(
            const ConversionResult(success: false, cancelled: true),
          );
        } else {
          final logs = await session.getAllLogsAsString() ?? '';
          Logger.error('Conversion failed: $logs', tag: 'FFmpegService');
          completer.complete(
            ConversionResult(success: false, errorMessage: friendlyError(logs)),
          );
        }
      },
      null,
      (stats) {
        if (totalMs <= 0) return;
        final t = stats.getTime();
        if (t > 0) onProgress?.call((t / totalMs).clamp(0.0, 1.0));
      },
    );
    sessionId = session.getSessionId();
    if (sessionId != null) onSession?.call(sessionId);

    return completer.future;
  }

  Future<void> cancel(int sessionId) => FFmpegKit.cancel(sessionId);

  /// Maps raw FFmpeg logs to a short, human message.
  static String friendlyError(String logs) {
    final lower = logs.toLowerCase();
    if (lower.contains('matches no streams') ||
        lower.contains('does not contain any stream') ||
        lower.contains('output file #0 does not contain')) {
      return "This video doesn't have a sound track.";
    }
    if (lower.contains('no such file') || lower.contains('does not exist')) {
      return 'The video could not be found. It may have been moved.';
    }
    if (lower.contains('invalid data') || lower.contains('moov atom')) {
      return 'The video looks damaged or incomplete.';
    }
    if (lower.contains('no space left')) {
      return 'Your phone is out of space. Free some up and try again.';
    }
    if (lower.contains('permission denied')) {
      return "AudioPeel couldn't read this video. Try picking it again.";
    }
    if (lower.contains('codec') || lower.contains('decoder')) {
      return "This video's audio format isn't supported. Try MP3 instead.";
    }
    return 'Something went wrong while converting. Please try again.';
  }
}
