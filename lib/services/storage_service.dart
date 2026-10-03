import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Simple storage utilities for app cache management.
class StorageService {
  const StorageService();

  /// Human-readable path where converted audio is saved.
  String getOutputDirectoryDisplay() => 'Music/AudioPeel';

  /// Called at startup to sweep leftover temp files from any previous
  /// (possibly crashed) conversion session so stale artifacts do not
  /// accumulate between launches.
  Future<void> init() async {
    try {
      final base = await getTemporaryDirectory();
      final workDir = Directory(p.join(base.path, 'work'));
      if (!workDir.existsSync()) return;
      await for (final entity in workDir.list()) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {
          // Best-effort — ignore individual failures.
        }
      }
    } catch (_) {
      // Silently ignore if unavailable (e.g. in test environments).
    }
  }

  /// Removes temporary processing artifacts left by FFmpeg / the conversion
  /// pipeline. Does NOT touch anything in Music/AudioPeel — only the app's
  /// private temporary directory is cleaned.
  Future<void> clearCache() async {
    try {
      final dir = await getTemporaryDirectory();
      if (dir.existsSync()) {
        await for (final entity in dir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {
            // Best-effort — ignore individual failures.
          }
        }
      }
    } catch (_) {
      // Silently ignore if unavailable (e.g. in test environments).
    }
  }
}

