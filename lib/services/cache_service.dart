import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

/// Service for managing app cache and temporary files.
class CacheService {
  static const _tag = 'CacheService';

  /// Gets the total size of the app's cache directory in bytes.
  Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      return await _getDirectorySize(cacheDir);
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to calculate cache size',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
      return 0;
    }
  }

  /// Clears all files in the app's cache directory.
  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        final contents = cacheDir.listSync();
        for (final item in contents) {
          try {
            if (item is File) {
              await item.delete();
            } else if (item is Directory) {
              await item.delete(recursive: true);
            }
          } on Exception catch (e) {
            Logger.warning(
              'Failed to delete cache item: ${item.path} - $e',
              _tag,
            );
          }
        }
        Logger.info('Cache cleared successfully', _tag);
      }
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to clear cache',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
      rethrow;
    }
  }

  /// Recursively calculates the size of a directory.
  Future<int> _getDirectorySize(Directory directory) async {
    var size = 0;

    try {
      if (!directory.existsSync()) return 0;

      final contents = directory.listSync(recursive: true);
      for (final item in contents) {
        if (item is File) {
          try {
            size += await item.length();
          } on Exception catch (e) {
            Logger.warning('Failed to get file size: ${item.path} - $e', _tag);
          }
        }
      }
    } on Exception catch (e) {
      Logger.warning('Failed to calculate directory size - $e', _tag);
    }

    return size;
  }
}
