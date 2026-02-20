import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audiopeel/models/audio_file.dart';
import 'package:audiopeel/models/audio_quality.dart';
import 'package:audiopeel/providers/history_provider.dart';
import 'package:audiopeel/services/database_service.dart';

// ─── Mock ─────────────────────────────────────────────────────────────

class MockDatabaseService extends Mock implements DatabaseService {}

// ─── Helpers ──────────────────────────────────────────────────────────

AudioFile _sampleFile({
  int? id,
  String name = 'clip_audio.mp3',
  AudioQuality quality = AudioQuality.medium192,
}) {
  return AudioFile(
    id: id,
    inputVideoName: 'clip.mp4',
    inputVideoPath: '/storage/videos/clip.mp4',
    outputAudioName: name,
    outputAudioPath: '/storage/mp3/$name',
    quality: quality,
    fileSize: 3500000,
    duration: 180,
    status: 'completed',
    createdAt: DateTime(2026, 2, 6, 10, 0),
  );
}

void main() {
  late MockDatabaseService mockDb;
  late HistoryProvider provider;

  setUp(() {
    mockDb = MockDatabaseService();
    provider = HistoryProvider(databaseService: mockDb);
  });

  group('HistoryProvider', () {
    test('initial state is correct', () {
      expect(provider.conversions, isEmpty);
      expect(provider.filter, HistoryFilter.all);
      expect(provider.searchQuery, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.isEmpty, isTrue);
    });

    test('loadConversions fetches all by default', () async {
      final files = [_sampleFile(id: 1), _sampleFile(id: 2, name: 'b.mp3')];
      when(() => mockDb.allConversions()).thenAnswer((_) async => files);

      await provider.loadConversions();

      expect(provider.conversions, hasLength(2));
      expect(provider.isLoading, isFalse);
      expect(provider.isEmpty, isFalse);
      verify(() => mockDb.allConversions()).called(1);
    });

    test('loadConversions uses search when query is set', () async {
      when(
        () => mockDb.searchConversions('test'),
      ).thenAnswer((_) async => [_sampleFile(id: 1)]);

      await provider.searchByName('test');

      expect(provider.conversions, hasLength(1));
      expect(provider.searchQuery, 'test');
      verify(() => mockDb.searchConversions('test')).called(1);
    });

    test('applyFilter changes the filter and reloads', () async {
      when(
        () => mockDb.todayConversions(),
      ).thenAnswer((_) async => [_sampleFile(id: 1)]);

      await provider.applyFilter(HistoryFilter.today);

      expect(provider.filter, HistoryFilter.today);
      expect(provider.searchQuery, isEmpty);
      verify(() => mockDb.todayConversions()).called(1);
    });

    test('applyFilter.last7Days calls correct DB method', () async {
      when(() => mockDb.last7DaysConversions()).thenAnswer((_) async => []);

      await provider.applyFilter(HistoryFilter.last7Days);

      expect(provider.filter, HistoryFilter.last7Days);
      verify(() => mockDb.last7DaysConversions()).called(1);
    });

    test('applyFilter.highQuality calls correct DB method', () async {
      when(() => mockDb.highQualityConversions()).thenAnswer((_) async => []);

      await provider.applyFilter(HistoryFilter.highQuality);

      expect(provider.filter, HistoryFilter.highQuality);
      verify(() => mockDb.highQualityConversions()).called(1);
    });

    test('deleteConversion removes from list', () async {
      final files = [_sampleFile(id: 1), _sampleFile(id: 2, name: 'b.mp3')];
      when(() => mockDb.allConversions()).thenAnswer((_) async => files);
      when(() => mockDb.deleteConversion(1)).thenAnswer((_) async => 1);

      await provider.loadConversions();
      expect(provider.conversions, hasLength(2));

      await provider.deleteConversion(1);
      expect(provider.conversions, hasLength(1));
      expect(provider.conversions.first.id, 2);
      verify(() => mockDb.deleteConversion(1)).called(1);
    });

    test('clearAll empties the list', () async {
      when(
        () => mockDb.allConversions(),
      ).thenAnswer((_) async => [_sampleFile(id: 1)]);
      when(() => mockDb.clearAllConversions()).thenAnswer((_) async => 1);

      await provider.loadConversions();
      expect(provider.conversions, isNotEmpty);

      await provider.clearAll();
      expect(provider.conversions, isEmpty);
    });

    test('recentConversions delegates to database', () async {
      when(
        () => mockDb.recentConversions(limit: 5),
      ).thenAnswer((_) async => [_sampleFile(id: 1)]);

      final recent = await provider.recentConversions();
      expect(recent, hasLength(1));
    });

    test('loadConversions handles DB errors gracefully', () async {
      when(() => mockDb.allConversions()).thenThrow(Exception('DB crash'));

      await provider.loadConversions();

      // Should not throw, conversions set to empty.
      expect(provider.conversions, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('notifies listeners during load cycle', () async {
      when(() => mockDb.allConversions()).thenAnswer((_) async => []);

      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.loadConversions();

      // At least 2: one for isLoading=true, one for isLoading=false.
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });
}
