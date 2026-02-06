import 'dart:async';

import 'package:flutter/foundation.dart';

/// A simple debouncer that delays a callback until [duration] has elapsed
/// since the last invocation.
///
/// Useful for search fields where you want to avoid firing a query on
/// every keystroke.
///
/// ```dart
/// final _debounce = Debouncer();
/// _debounce.run(() => provider.searchByName(query));
/// ```
class Debouncer {
  /// Creates a debouncer with the given [duration].
  Debouncer({this.duration = const Duration(milliseconds: 300)});

  /// The debounce window.
  final Duration duration;

  Timer? _timer;

  /// Schedules [action] to run after the debounce window.  If called
  /// again before the window expires, the previous call is cancelled.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels any pending debounced call.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
