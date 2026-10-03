import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../utils/logger.dart';

/// One shared audio player for the whole app — powers the result player,
/// the Library's inline players and the persistent mini-player.
class PlayerProvider extends ChangeNotifier {
  PlayerProvider() {
    _subs.add(
      _player.playerStateStream.listen((s) {
        if (s.processingState == ProcessingState.completed) {
          _player.pause();
          _player.seek(Duration.zero);
        }
        notifyListeners();
      }),
    );
    _subs.add(
      _player.durationStream.listen((_) => notifyListeners()),
    );
  }

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<Object?>> _subs = [];

  String? _uri;
  String _title = '';
  String _subtitle = '';

  /// URI of the loaded track, or null.
  String? get currentUri => _uri;
  String get title => _title;
  String get subtitle => _subtitle;
  bool get hasTrack => _uri != null;
  bool get isPlaying => _player.playing;
  Duration get duration => _player.duration ?? Duration.zero;

  Stream<Duration> get positionStream => _player.positionStream;
  Duration get position => _player.position;

  bool isCurrent(String uri) => _uri == uri;
  bool isPlayingUri(String uri) => _uri == uri && _player.playing;

  /// Plays [uri]; if it's already loaded, toggles play/pause.
  Future<void> toggle(String uri, {String title = '', String subtitle = ''}) async {
    if (_uri == uri) {
      _player.playing ? await _player.pause() : unawaited(_player.play());
      notifyListeners();
      return;
    }
    try {
      _uri = uri;
      _title = title;
      _subtitle = subtitle;
      notifyListeners();
      final source = uri.startsWith('content://') || uri.startsWith('file://')
          ? AudioSource.uri(Uri.parse(uri))
          : AudioSource.file(uri);
      await _player.setAudioSource(source);
      unawaited(_player.play());
    } on Exception catch (e) {
      Logger.warning('playback failed: $e', 'Player');
      _uri = null;
      notifyListeners();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  /// Stops and unloads (e.g. when the file is deleted).
  Future<void> stop() async {
    await _player.stop();
    _uri = null;
    notifyListeners();
  }

  /// Stops only if [uri] is the loaded track.
  Future<void> stopIf(String uri) async {
    if (_uri == uri) await stop();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}
