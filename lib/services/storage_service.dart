import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// Manages the output directory and file operations for converted MP3s.
///
/// Uses the singleton pattern so every part of the app shares the same
/// output-path state.
class StorageService {
  factory StorageService() => _instance;
  StorageService._internal();
  static final StorageService _instance = StorageService._internal();

  static const _prefCustomOutputPath = 'custom_output_path';

  String? _outputDirectoryPath;
  bool _initialized = false;

  /// Loads the persisted custom output path from [SharedPreferences].
  ///
  /// Call once at app startup before any conversion.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final custom = prefs.getString(_prefCustomOutputPath);
      if (custom != null && Directory(custom).existsSync()) {
        _outputDirectoryPath = custom;
        Logger.info('Restored custom output path: $custom', 'Storage');
      }
    } on Exception catch (e) {
      Logger.warning('Could not load custom output path: $e', 'Storage');
    }
    _initialized = true;
  }

  /// Returns the app's output directory, creating it if necessary.
  ///
  /// If the user has set a custom path in Settings it is used; otherwise
  /// the app-specific external storage directory is used (no permission
  /// required on Android 11+).
  Future<String> outputDirectory() async {
    if (_outputDirectoryPath != null) return _outputDirectoryPath!;

    final externalDir = await getExternalStorageDirectory();
    if (externalDir == null) {
      throw const FileSystemException(
        'External storage is not available on this device.',
      );
    }

    final outputDir = Directory(
      p.join(externalDir.path, AppConstants.outputDirectoryName),
    );

    if (!outputDir.existsSync()) {
      await outputDir.create(recursive: true);
      Logger.info('Created output directory: ${outputDir.path}', 'Storage');
    }

    _outputDirectoryPath = outputDir.path;
    return _outputDirectoryPath!;
  }

  /// Whether the device has enough free disk space to begin a conversion.
  ///
  /// Returns `true` when at least [AppConstants.minimumFreeSpaceBytes]
  /// are available on the output partition, or if the check cannot be
  /// performed (we err on the side of allowing the conversion).
  Future<bool> hasEnoughSpace() async {
    try {
      final dir = await outputDirectory();
      // Run `df` on the output directory to check available space.
      final result = await Process.run('df', ['-P', dir]);
      if (result.exitCode != 0) return true;

      final lines = (result.stdout as String).trim().split('\n');
      if (lines.length < 2) return true;

      // The fourth column of `df -P` output is "Available" (in 1K blocks).
      final columns = lines.last.split(RegExp(r'\s+'));
      if (columns.length < 4) return true;

      final availableKb = int.tryParse(columns[3]) ?? 0;
      final availableBytes = availableKb * 1024;

      if (availableBytes < AppConstants.minimumFreeSpaceBytes) {
        Logger.warning(
          'Low disk space: ${availableBytes ~/ (1024 * 1024)} MB remaining',
          'Storage',
        );
        return false;
      }
      return true;
    } on Exception catch (e) {
      Logger.warning('Could not check disk space: $e', 'Storage');
      // Allow the conversion to proceed — FFmpeg will fail gracefully.
      return true;
    }
  }

  /// Returns the full output path for a new MP3 file, ensuring uniqueness.
  Future<String> uniqueOutputPath(String fileName) async {
    final dir = await outputDirectory();
    final sanitised = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    var candidate = p.join(dir, '$sanitised.mp3');
    var counter = 1;

    while (File(candidate).existsSync()) {
      candidate = p.join(dir, '$sanitised ($counter).mp3');
      counter++;
    }
    return candidate;
  }

  /// Returns the file size in bytes, or `0` if the file doesn't exist.
  int fileSize(String path) {
    final file = File(path);
    return file.existsSync() ? file.lengthSync() : 0;
  }

  /// Deletes a file at [path]. Returns `true` on success, `false` otherwise.
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        Logger.debug('Deleted file: $path', 'Storage');
        return true;
      }
      return false;
    } on FileSystemException catch (e) {
      Logger.error('Failed to delete file: $path', error: e, tag: 'Storage');
      return false;
    }
  }

  /// Checks whether [path] exists on disk.
  Future<bool> fileExists(String path) => File(path).exists();

  /// Returns the total cache size in bytes for temporary files.
  Future<int> cacheSize() async {
    final tempDir = await getTemporaryDirectory();
    if (!tempDir.existsSync()) return 0;

    var total = 0;
    await for (final entity in tempDir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Deletes all files in the app's temporary directory.
  Future<void> clearCache() async {
    final tempDir = await getTemporaryDirectory();
    if (!tempDir.existsSync()) return;

    await for (final entity in tempDir.list()) {
      try {
        await entity.delete(recursive: true);
      } on FileSystemException catch (e) {
        Logger.warning('Could not delete cache entry: $e', 'Storage');
      }
    }
    Logger.info('Cache cleared', 'Storage');
  }

  /// Overrides the output directory to [path] and persists the choice.
  Future<void> setOutputDirectory(String path) async {
    _outputDirectoryPath = path;
    Logger.info('Output directory changed to: $path', 'Storage');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefCustomOutputPath, path);
    } on Exception catch (e) {
      Logger.warning('Could not persist output path: $e', 'Storage');
    }
  }
}
