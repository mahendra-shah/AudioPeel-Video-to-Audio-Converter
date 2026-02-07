import 'package:flutter/foundation.dart';

import '../models/audio_file.dart';
import '../services/database_service.dart';
import '../utils/logger.dart';

/// Filter options for the conversion history list.
enum HistoryFilter { all, today, last7Days, highQuality }

/// Manages the conversion history list with filtering and search.
class HistoryProvider extends ChangeNotifier {
  HistoryProvider({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  // ─── State ──────────────────────────────────────────────────────────

  List<AudioFile> _conversions = [];
  HistoryFilter _filter = HistoryFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;

  // ─── Getters ────────────────────────────────────────────────────────

  /// The current list of conversions matching the active filter / search.
  List<AudioFile> get conversions => List.unmodifiable(_conversions);

  /// The active filter.
  HistoryFilter get filter => _filter;

  /// The active search query.
  String get searchQuery => _searchQuery;

  /// Whether the list is currently loading.
  bool get isLoading => _isLoading;

  /// Whether the list is empty (after loading).
  bool get isEmpty => !_isLoading && _conversions.isEmpty;

  // ─── Actions ────────────────────────────────────────────────────────

  /// Loads conversions from the database using the current filter.
  Future<void> loadConversions() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_searchQuery.isNotEmpty) {
        _conversions = await _databaseService.searchConversions(_searchQuery);
      } else {
        _conversions = await _fetchByFilter(_filter);
      }
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to load conversions',
        error: e,
        stackTrace: st,
        tag: 'HistoryProvider',
      );
      _conversions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the active filter and reloads.
  Future<void> applyFilter(HistoryFilter filter) async {
    _filter = filter;
    _searchQuery = '';
    await loadConversions();
  }

  /// Searches conversions by file name and reloads.
  Future<void> searchByName(String query) async {
    _searchQuery = query;
    await loadConversions();
  }

  /// Deletes a single conversion from the database and refreshes the list.
  Future<void> deleteConversion(int id) async {
    try {
      await _databaseService.deleteConversion(id);
      _conversions = _conversions.where((c) => c.id != id).toList();
      notifyListeners();
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to delete conversion $id',
        error: e,
        stackTrace: st,
        tag: 'HistoryProvider',
      );
    }
  }

  /// Deletes a conversion by its output audio file path and refreshes.
  Future<void> deleteConversionByPath(String outputAudioPath) async {
    try {
      await _databaseService.deleteConversionByPath(outputAudioPath);
      _conversions = _conversions
          .where((c) => c.outputAudioPath != outputAudioPath)
          .toList();
      notifyListeners();
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to delete conversion path=$outputAudioPath',
        error: e,
        stackTrace: st,
        tag: 'HistoryProvider',
      );
    }
  }

  /// Clears all conversion history.
  Future<void> clearAll() async {
    try {
      await _databaseService.clearAllConversions();
      _conversions = [];
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

  /// Returns the most recent [limit] conversions (for the home screen).
  Future<List<AudioFile>> recentConversions({int limit = 5}) async {
    return _databaseService.recentConversions(limit: limit);
  }

  // ─── Private ────────────────────────────────────────────────────────

  Future<List<AudioFile>> _fetchByFilter(HistoryFilter filter) {
    switch (filter) {
      case HistoryFilter.all:
        return _databaseService.allConversions();
      case HistoryFilter.today:
        return _databaseService.todayConversions();
      case HistoryFilter.last7Days:
        return _databaseService.last7DaysConversions();
      case HistoryFilter.highQuality:
        return _databaseService.highQualityConversions();
    }
  }
}
