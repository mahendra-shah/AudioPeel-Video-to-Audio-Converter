import 'dart:async';

import 'package:flutter/services.dart';

import '../models/media_item.dart';
import '../utils/logger.dart';

/// Result of saving a converted file into Music/AudioPeel.
class LibraryEntry {
  const LibraryEntry({
    required this.uri,
    required this.name,
    required this.displayPath,
    required this.sizeBytes,
  });

  final String uri;
  final String name;
  final String displayPath;
  final int sizeBytes;
}

/// Ringtone slots understood by Android's RingtoneManager.
enum RingtoneSlot {
  ringtone(1, 'ringtone'),
  notification(2, 'notification sound'),
  alarm(4, 'alarm');

  const RingtoneSlot(this.androidType, this.label);
  final int androidType;
  final String label;
}

/// Dart side of the native media bridge in `MainActivity.kt`.
abstract final class MediaBridge {
  static const _channel = MethodChannel('com.mcore.audiopeel/media');
  static final _shared = StreamController<List<String>>.broadcast();
  static bool _listening = false;
  static int? _sdkInt;

  /// Videos shared to the app while it is running ("Share → AudioPeel").
  static Stream<List<String>> get sharedUris {
    if (!_listening) {
      _listening = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onShared') {
          final uris = (call.arguments as List).cast<String>();
          if (uris.isNotEmpty) _shared.add(uris);
        }
      });
    }
    return _shared.stream;
  }

  /// Videos the app was launched with (cold-start share / open-with).
  static Future<List<String>> initialShared() async {
    try {
      final list = await _channel.invokeListMethod<String>('initialShared');
      return list ?? const [];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  static Future<int> sdkInt() async {
    if (_sdkInt != null) return _sdkInt!;
    try {
      _sdkInt = await _channel.invokeMethod<int>('sdkInt') ?? 33;
    } on MissingPluginException {
      _sdkInt = 33;
    }
    return _sdkInt!;
  }

  /// Opens the system photo picker. Returns `content://` URIs (empty if
  /// the user backed out). No copy is made.
  static Future<List<String>> pickVideos({bool multiple = true}) async {
    final list = await _channel.invokeListMethod<String>('pickVideos', {
      'multiple': multiple,
    });
    return list ?? const [];
  }

  static Future<MediaItem?> probe(String uri) async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>('probe', {
        'uri': uri,
      });
      return map == null ? null : MediaItem.fromMap(map);
    } on PlatformException catch (e) {
      Logger.warning('probe failed: ${e.message}', 'MediaBridge');
      return null;
    }
  }

  static Future<Uint8List?> thumbnail(
    String uri, {
    int ms = 0,
    int width = 480,
  }) async {
    try {
      return await _channel.invokeMethod<Uint8List>('thumbnail', {
        'uri': uri,
        'ms': ms,
        'width': width,
      });
    } on PlatformException {
      return null;
    }
  }

  static Future<List<Uint8List>> filmstrip(
    String uri, {
    int count = 10,
    int width = 120,
  }) async {
    try {
      final list = await _channel.invokeListMethod<Uint8List>('filmstrip', {
        'uri': uri,
        'count': count,
        'width': width,
      });
      return list ?? const [];
    } on PlatformException {
      return const [];
    }
  }

  static Future<LibraryEntry> saveToLibrary({
    required String tempPath,
    required String name,
    required String mime,
  }) async {
    final map = await _channel.invokeMapMethod<String, Object?>(
      'saveToLibrary',
      {'path': tempPath, 'name': name, 'mime': mime},
    );
    return LibraryEntry(
      uri: map!['uri']! as String,
      name: map['name']! as String,
      displayPath: map['displayPath']! as String,
      sizeBytes: (map['size']! as num).toInt(),
    );
  }

  static Future<bool> delete(String uri) async {
    try {
      return await _channel.invokeMethod<bool>('delete', {'uri': uri}) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> exists(String uri) async {
    try {
      return await _channel.invokeMethod<bool>('exists', {'uri': uri}) ??
          true;
    } on PlatformException {
      return true;
    }
  }

  static Future<void> share(List<String> uris, {String mime = 'audio/*'}) =>
      _channel.invokeMethod('share', {'uris': uris, 'mime': mime});

  static Future<bool> openWith(String uri, {String mime = 'audio/*'}) async =>
      await _channel.invokeMethod<bool>('openWith', {
        'uri': uri,
        'mime': mime,
      }) ??
      false;

  static Future<bool> openFolder() async =>
      await _channel.invokeMethod<bool>('openFolder') ?? false;

  static Future<bool> canWriteSettings() async =>
      await _channel.invokeMethod<bool>('canWriteSettings') ?? false;

  static Future<void> requestWriteSettings() =>
      _channel.invokeMethod('requestWriteSettings');

  static Future<bool> setRingtone(String uri, RingtoneSlot slot) async {
    try {
      return await _channel.invokeMethod<bool>('setRingtone', {
            'uri': uri,
            'type': slot.androidType,
          }) ??
          false;
    } on PlatformException catch (e) {
      Logger.warning('setRingtone failed: ${e.message}', 'MediaBridge');
      return false;
    }
  }
}
