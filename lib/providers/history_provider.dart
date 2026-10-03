import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/audio_file.dart';
import '../services/database_service.dart';
import '../services/media_bridge.dart';
import '../utils/logger.dart';

/// Filter chips on the Library screen.
enum HistoryFilter {
  all('All'),
  mp3('MP3'),
  m4a('M4A'),
  lossless('Lossless'),
  thisWeek('This week');

  const HistoryFilter(this.label);
  final String label;
}

/// The Library: conversion history with search, filters, undoable deletes
/// and cleanup of files removed outside the app.
class HistoryProvider extends ChangeNotifier {
  HistoryProvider({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  List<AudioFile> _conversions = [];
  List<AudioFile> _recent = [];
  HistoryFilter _filter = HistoryFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _loadedOnce = false;
  final Set<int> _pendingDelete = {};

  /// Conversions matching the filter/search, minus rows awaiting deletion.
  List<AudioFile> get conversions => List.unmodifiable(
    _conversions.where((c) => !_pendingDelete.contains(c.id)),
  );

  /// Latest three for the home screen.
  List<AudioFile> get recent => List.unmodifiable(
    _recent.where((c) => !_pendingDelete.contains(c.id)).take(3),
  );

  HistoryFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get loadedOnce => _loadedOnce;
  bool get isEmpty => _loadedOnce && conversions.isEmpty;

  /// Reloads both the filtered list and the home "recent" strip.
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      _recent = await _databaseService.recentConversions(limit: 6);
      _conversions = _searchQuery.isNotEmpty
          ? await _databaseService.searchConversions(_searchQuery)
          : await _fetchByFilter(_filter);
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to load conversions',
        error: e,
        stackTrace: st,
        tag: 'HistoryProvider',
      );
    } finally {
      _isLoading = false;
      _loadedOnce = true;
      notifyListeners();
    }
  }

  /// Kept for older call sites.
  Future<void> loadConversions() => refresh();

  Future<void> applyFilter(HistoryFilter filter) async {
    _filter = filter;
    _searchQuery = '';
    await refresh();
  }

  Future<void> searchByName(String query) async {
    _searchQuery = query;
    await refresh();
  }

  /// Hides [file] immediately; call [commitDelete] or [undoDelete] later.
  void stageDelete(AudioFile file) {
    if (file.id == null) return;
    _pendingDelete.add(file.id!);
    notifyListeners();
  }

  void undoDelete(AudioFile file) {
    _pendingDelete.remove(file.id);
    notifyListeners();
  }

  /// Deletes the audio file from storage and its history row.
  Future<void> commitDelete(AudioFile file) async {
    if (file.id == null) return;
    await deleteFileOf(file);
    await _databaseService.deleteConversion(file.id!);
    _pendingDelete.remove(file.id);
    _conversions.removeWhere((c) => c.id == file.id);
    _recent.removeWhere((c) => c.id == file.id);
    notifyListeners();
  }

  /// Removes the underlying audio (MediaStore row or legacy file).
  static Future<void> deleteFileOf(AudioFile file) async {
    if (file.isContentUri) {
      await MediaBridge.delete(file.outputAudioPath);
    } else {
      try {
        final f = File(file.outputAudioPath);
        if (await f.exists()) await f.delete();
      } on FileSystemException catch (e) {
        Logger.warning('delete failed: $e', 'HistoryProvider');
      }
    }
  }

  Future<void> clearAll() async {
    try {
      await _databaseService.clearAllConversions();
      _conversions = [];
      _recent = [];
      notifyListeners();
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to clear all conversions',
        error: e,
        stackTrace: st,
        tag: 'HistoryProvider',
      );
    }
  }

  /// Drops history rows whose audio was deleted outside the app.
  Future<void> pruneMissing() async {
    try {
      final all = await _databaseService.allConversions();
      var removed = 0;
      for (final f in all) {
        final exists = f.isContentUri
            ? await MediaBridge.exists(f.outputAudioPath)
            : File(f.outputAudioPath).existsSync();
        if (!exists && f.id != null) {
          await _databaseService.deleteConversion(f.id!);
          removed++;
        }
      }
      if (removed > 0) await refresh();
    } on Exception catch (e) {
      Logger.warning('prune failed: $e', 'HistoryProvider');
    }
  }

  Future<List<AudioFile>> _fetchByFilter(HistoryFilter filter) {
    switch (filter) {
      case HistoryFilter.all:
        return _databaseService.allConversions();
      case HistoryFilter.mp3:
        return _databaseService.conversionsByFormats(['mp3']);
      case HistoryFilter.m4a:
        return _databaseService.conversionsByFormats(['m4a']);
      case HistoryFilter.lossless:
        return _databaseService.conversionsByFormats(['wav', 'flac']);
      case HistoryFilter.thisWeek:
        return _databaseService.last7DaysConversions();
    }
  }
}
