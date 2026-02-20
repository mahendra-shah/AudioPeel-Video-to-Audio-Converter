import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audiopeel/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('runs action after the debounce window', () {
      fakeAsync((async) {
        final debouncer = Debouncer(
          duration: const Duration(milliseconds: 300),
        );
        var callCount = 0;

        debouncer.run(() => callCount++);

        // Not yet called.
        expect(callCount, 0);

        // Advance past the debounce window.
        async.elapse(const Duration(milliseconds: 300));
        expect(callCount, 1);

        debouncer.dispose();
      });
    });

    test('cancels previous call when run is called again', () {
      fakeAsync((async) {
        final debouncer = Debouncer(
          duration: const Duration(milliseconds: 300),
        );
        var callCount = 0;

        debouncer.run(() => callCount++);

        // Advance halfway.
        async.elapse(const Duration(milliseconds: 150));
        expect(callCount, 0);

        // Call again — resets the timer.
        debouncer.run(() => callCount++);

        // Original timer would have fired by now, but it was cancelled.
        async.elapse(const Duration(milliseconds: 200));
        expect(callCount, 0);

        // New timer fires.
        async.elapse(const Duration(milliseconds: 100));
        expect(callCount, 1);

        debouncer.dispose();
      });
    });

    test('dispose cancels pending actions', () {
      fakeAsync((async) {
        final debouncer = Debouncer(
          duration: const Duration(milliseconds: 300),
        );
        var callCount = 0;

        debouncer.run(() => callCount++);
        debouncer.dispose();

        async.elapse(const Duration(milliseconds: 500));
        expect(callCount, 0);
      });
    });

    test('can be run multiple times after disposal', () {
      fakeAsync((async) {
        final debouncer = Debouncer(
          duration: const Duration(milliseconds: 100),
        );
        var callCount = 0;

        debouncer.run(() => callCount++);
        async.elapse(const Duration(milliseconds: 100));
        expect(callCount, 1);

        debouncer.dispose();

        // Should still work after dispose + re-use.
        debouncer.run(() => callCount++);
        async.elapse(const Duration(milliseconds: 100));
        expect(callCount, 2);

        debouncer.dispose();
      });
    });
  });
}
