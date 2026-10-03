import 'history_provider.dart';
import 'queue_provider.dart';

/// Thin subclass of [QueueProvider] that satisfies the no-argument
/// `ChangeNotifierProvider(create: (_) => ConversionProvider())` in main.dart.
///
/// [main.dart] creates a `ConversionProvider()` without passing a
/// [HistoryProvider] dependency (which [QueueProvider] normally requires).
/// This class bridges that by constructing a private [HistoryProvider] instance.
///
/// In practice, screens should `context.watch<QueueProvider>()` using the
/// [QueueProvider] provided separately with its full dependency graph.
/// This class exists purely so main.dart compiles without modification.
class ConversionProvider extends QueueProvider {
  ConversionProvider() : super(history: HistoryProvider());
}
