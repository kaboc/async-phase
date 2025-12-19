// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:async_phase_notifier/async_phase_notifier.dart';

bool isNullable<T>(T value) => null is T;

void main() {
  group('Generic type', () {
    test('Initial data affects nullability of generic type', () async {
      final notifier1 = AsyncPhaseNotifier(10);
      final notifier2 = AsyncPhaseNotifier(null);
      addTearDown(notifier1.dispose);
      addTearDown(notifier2.dispose);

      expect(notifier1, isA<AsyncPhaseNotifier<int>>());
      expect(notifier2, isNot(isA<AsyncPhaseNotifier<int>>()));
    });
  });

  group('update()', () {
    test(
      'Phase changes correctly as function runs, and data has correct value',
      () async {
        final notifier1 = AsyncPhaseNotifier(10);
        final notifier2 = AsyncPhaseNotifier(10);
        addTearDown(notifier1.dispose);
        addTearDown(notifier2.dispose);

        expect(notifier1.value, isA<AsyncInitial<int>>());
        expect(notifier2.value, isA<AsyncInitial<int>>());

        final e = Exception();
        final s = StackTrace.current;

        var completer = Completer<void>();
        unawaited(
          notifier1.update(() async {
            completer.complete();
            return 20;
          }),
        );
        expect(notifier1.value, const AsyncWaiting(10));
        await completer.future;
        await pumpEventQueue();
        expect(notifier1.value, const AsyncComplete(20));

        completer = Completer<void>();
        unawaited(
          notifier2.update(() async {
            completer.complete();
            Error.throwWithStackTrace(e, s);
          }),
        );
        expect(notifier2.value, const AsyncWaiting(10));
        await completer.future;
        await pumpEventQueue();
        expect(notifier2.value, AsyncError(data: 10, error: e, stackTrace: s));
      },
    );

    test('Callbacks are called with correct values in correct order', () async {
      final notifier1 = AsyncPhaseNotifier(10);
      final notifier2 = AsyncPhaseNotifier(10);
      addTearDown(notifier1.dispose);
      addTearDown(notifier2.dispose);

      final error = Exception();
      final called1 = <Object?>[];
      final called2 = <Object?>[];

      await notifier1.update(
        () async => 20,
        onWaiting: (data) => called1.add('waiting: $data'),
        onComplete: (data) => called1.add('complete: $data'),
        onError: (e, _) => called1.add('error: $e'),
      );
      expect(called1, ['waiting: 10', 'complete: 20']);

      await notifier2.update(
        () => throw error,
        onWaiting: (data) => called2.add('waiting: $data'),
        onComplete: (data) => called2.add('complete: $data'),
        onError: (e, _) => called2.add('error: $e'),
      );
      expect(called2, ['waiting: 10', 'error: $error']);
    });

    test(
      'If another operation modifies data while update() is running, '
      'resulting AsyncError reflects the change',
      () async {
        final notifier = AsyncPhaseNotifier(10);
        addTearDown(notifier.dispose);

        final e = Exception();
        final s = StackTrace.current;
        final called = <int>[];

        final results = await Future.wait([
          notifier.update(() async {
            called.add(1);
            await Future<void>.delayed(const Duration(milliseconds: 20));
            called.add(2);
            Error.throwWithStackTrace(e, s);
          }),
          notifier.update(() async {
            called.add(3);
            return 20;
          }),
        ]);

        expect(called, [1, 3, 2]);
        expect(results.first, AsyncError(data: 20, error: e, stackTrace: s));
        expect(notifier.value, AsyncError(data: 20, error: e, stackTrace: s));
      },
    );

    test(
      'Even if another operation modifies data while update() is running, '
      'resulting AsyncComplete and onComplete callback reflect own result',
      () async {
        final notifier = AsyncPhaseNotifier(10);
        addTearDown(notifier.dispose);

        final called = <int>[];

        final results = await Future.wait([
          notifier.update(
            () async {
              called.add(1);
              await Future<void>.delayed(const Duration(milliseconds: 20));
              called.add(2);
              return 20;
            },
            onComplete: called.add,
          ),
          notifier.update(() async {
            called.add(3);
            return 30;
          }),
        ]);

        expect(called, [1, 3, 2, 20]);
        expect(results.first, const AsyncComplete(20));
        expect(notifier.value, const AsyncComplete(20));
      },
    );
  });

  group('updateType()', () {
    test(
      'Phase changes correctly as the function runs, and data is not affected',
      () async {
        final notifier = AsyncPhaseNotifier(10);
        addTearDown(notifier.dispose);

        expect(notifier.value, isA<AsyncInitial<int>>());

        final e = Exception();
        final s = StackTrace.current;

        var completer = Completer<void>();
        unawaited(
          notifier.updateType(() async {
            completer.complete();
            return 20;
          }),
        );
        expect(notifier.value, const AsyncWaiting(10));
        await completer.future;
        await pumpEventQueue();
        expect(notifier.value, const AsyncComplete(10));

        completer = Completer<void>();
        unawaited(
          notifier.updateType(() async {
            completer.complete();
            Error.throwWithStackTrace(e, s);
          }),
        );
        expect(notifier.value, const AsyncWaiting(10));
        await completer.future;
        await pumpEventQueue();
        expect(notifier.value, AsyncError(data: 10, error: e, stackTrace: s));

        completer = Completer<void>();
        unawaited(
          notifier.updateType(() async {
            completer.complete();
            return const AsyncWaiting(20);
          }),
        );
        expect(notifier.value, const AsyncWaiting(10));
        await completer.future;
        await pumpEventQueue();
        expect(notifier.value, const AsyncWaiting(10));

        completer = Completer<void>();
        unawaited(
          notifier.updateType(() async {
            completer.complete();
            return const AsyncComplete(20);
          }),
        );
        expect(notifier.value, const AsyncWaiting(10));
        await completer.future;
        await pumpEventQueue();
        expect(notifier.value, const AsyncComplete(10));

        completer = Completer<void>();
        unawaited(
          notifier.updateType(() async {
            completer.complete();
            return AsyncError(data: 20, error: e, stackTrace: s);
          }),
        );
        expect(notifier.value, const AsyncWaiting(10));
        await completer.future;
        await pumpEventQueue();
        expect(notifier.value, AsyncError(data: 10, error: e, stackTrace: s));
      },
    );

    test('Callbacks are called with correct values in correct order', () async {
      final notifier1 = AsyncPhaseNotifier(10);
      final notifier2 = AsyncPhaseNotifier(10);
      final notifier3 = AsyncPhaseNotifier(10);
      final notifier4 = AsyncPhaseNotifier(10);
      final notifier5 = AsyncPhaseNotifier(10);
      addTearDown(notifier1.dispose);
      addTearDown(notifier2.dispose);
      addTearDown(notifier3.dispose);
      addTearDown(notifier4.dispose);
      addTearDown(notifier5.dispose);

      final error = Exception();
      final called1 = <Object?>[];
      final called2 = <Object?>[];
      final called3 = <Object?>[];
      final called4 = <Object?>[];
      final called5 = <Object?>[];

      await notifier1.updateType(
        () async => 20,
        onWaiting: (data) => called1.add('waiting: $data'),
        onComplete: (data) => called1.add('complete: $data'),
        onError: (e, _) => called1.add('error: $e'),
      );
      expect(called1, ['waiting: 10', 'complete: 10']);

      await notifier2.updateType(
        () => throw error,
        onWaiting: (data) => called2.add('waiting: $data'),
        onComplete: (data) => called2.add('complete: $data'),
        onError: (e, _) => called2.add('error: $e'),
      );
      expect(called2, ['waiting: 10', 'error: $error']);

      await notifier3.updateType(
        () async => const AsyncWaiting(20),
        // No callback should be called at the end
        // because both phase type and data won't change.
        onWaiting: (data) => called3.add('waiting: $data'),
        onComplete: (data) => called3.add('complete: $data'),
        onError: (e, _) => called3.add('error: $e'),
      );
      expect(called3, ['waiting: 10']);

      await notifier4.updateType(
        () async => const AsyncComplete(20),
        onWaiting: (data) => called4.add('waiting: $data'),
        onComplete: (data) => called4.add('complete: $data'),
        onError: (e, _) => called4.add('error: $e'),
      );
      expect(called4, ['waiting: 10', 'complete: 10']);

      await notifier5.updateType(
        () async => AsyncError(error: error),
        onWaiting: (data) => called5.add('waiting: $data'),
        onComplete: (data) => called5.add('complete: $data'),
        onError: (e, _) => called5.add('error: $e'),
      );
      expect(called5, ['waiting: 10', 'error: $error']);
    });

    test(
      'If another operation modifies data while updateType() is running, '
      'resulting AsyncPhase and onComplete callback reflect the change',
      () async {
        final notifier = AsyncPhaseNotifier(10);
        addTearDown(notifier.dispose);

        final called = <int>[];

        final results = await Future.wait([
          notifier.updateType(
            () async {
              called.add(1);
              await Future<void>.delayed(const Duration(milliseconds: 20));
              called.add(2);
              return 20;
            },
            onComplete: called.add,
          ),
          notifier.update(() async {
            called.add(3);
            return 30;
          }),
        ]);

        expect(called, [1, 3, 2, 30]);
        expect(results.first, const AsyncComplete(30));
        expect(notifier.value, const AsyncComplete(30));
      },
    );
  });

  group('data getter', () {
    test(
      'data getter returns non-null value when generic type is non nullable',
      () {
        final notifier1 = AsyncPhaseNotifier<int?>(null);
        final notifier2 = AsyncPhaseNotifier(10);
        addTearDown(notifier1.dispose);
        addTearDown(notifier2.dispose);

        expect(isNullable(notifier1.value.data), isTrue);
        expect(isNullable(notifier2.value.data), isTrue);

        expect(isNullable(notifier1.data), isTrue);
        expect(isNullable(notifier2.data), isFalse);
      },
    );
  });

  group('listen()', () {
    test(
      'Callback is called with phase when phase or its data changes',
      () async {
        final notifier = AsyncPhaseNotifier('a');
        addTearDown(notifier.dispose);

        final phases = <AsyncPhase<String>>[];

        final cancel = notifier.listen(phases.add);
        addTearDown(cancel);

        notifier
          ..value = const AsyncInitial('a')
          ..value = const AsyncComplete('a')
          ..value = const AsyncComplete('a')
          ..value = const AsyncComplete('b')
          ..value = const AsyncWaiting('b')
          ..value = const AsyncWaiting('b')
          ..value = const AsyncWaiting('c')
          ..value = const AsyncComplete('c')
          ..value = const AsyncError(data: 'c', error: 'err')
          ..value = const AsyncError(data: 'c', error: 'err')
          ..value = const AsyncError(data: 'd', error: 'err')
          ..value = const AsyncWaiting('d')
          ..value = const AsyncError(data: 'd', error: 'err');

        await pumpEventQueue();

        expect(
          phases,
          const [
            AsyncComplete('a'),
            AsyncComplete('b'),
            AsyncWaiting('b'),
            AsyncWaiting('c'),
            AsyncComplete('c'),
            AsyncError(data: 'c', error: 'err'),
            AsyncError(data: 'd', error: 'err'),
            AsyncWaiting('d'),
            AsyncError(data: 'd', error: 'err'),
          ],
        );
      },
    );

    test('Callback is not called after subscription is cancelled', () async {
      final notifier = AsyncPhaseNotifier(null);
      addTearDown(notifier.dispose);

      var count1 = 0;
      var count2 = 0;

      final cancel1 = notifier.listen((_) => count1++);
      final cancel2 = notifier.listen((_) => count2++);
      addTearDown(cancel2);

      notifier
        ..value = const AsyncComplete(null)
        ..value = const AsyncError(error: 'err');
      await pumpEventQueue();
      expect(count1, 2);
      expect(count2, 2);

      cancel1();
      count1 = 0;
      count2 = 0;

      notifier
        ..value = const AsyncWaiting()
        ..value = const AsyncComplete(null)
        ..value = const AsyncError(error: 'err');
      await pumpEventQueue();
      expect(count1, isZero);
      expect(count2, 3);

      expect(notifier.isListening, isTrue);
      cancel2();
      expect(notifier.isListening, isFalse);
    });
  });

  group('listenFor()', () {
    test(
      'Callback is called when phase or its data changes, and onWaiting '
      'is called also when phase changes _from_ AsyncWaiting',
      () async {
        final notifier = AsyncPhaseNotifier('a');
        addTearDown(notifier.dispose);

        final phases = <AsyncPhase<String>>[];

        final cancel = notifier.listenFor(
          onWaiting: (data) => phases.add(AsyncWaiting(data)),
          onComplete: (data) => phases.add(AsyncComplete(data)),
          onError: (e, _) => phases.add(AsyncError(data: '', error: e)),
        );
        addTearDown(cancel);

        notifier
          ..value = const AsyncInitial('a')
          ..value = const AsyncComplete('a')
          ..value = const AsyncComplete('a')
          ..value = const AsyncComplete('b')
          ..value = const AsyncWaiting('b')
          ..value = const AsyncWaiting('b')
          ..value = const AsyncWaiting('c')
          ..value = const AsyncComplete('c')
          ..value = const AsyncError(data: 'c', error: 'err')
          ..value = const AsyncError(data: 'c', error: 'err')
          ..value = const AsyncError(data: 'd', error: 'err')
          ..value = const AsyncWaiting('d')
          ..value = const AsyncError(data: 'd', error: 'err');

        await pumpEventQueue();

        expect(
          phases,
          const [
            AsyncComplete('a'),
            AsyncComplete('b'),
            AsyncWaiting('b'),
            AsyncWaiting('c'),
            AsyncComplete('c'),
            AsyncError(data: '', error: 'err'),
            AsyncError(data: '', error: 'err'),
            AsyncWaiting('d'),
            AsyncError(data: '', error: 'err'),
          ],
        );
      },
    );

    test('onError is called with error and stack trace', () async {
      final notifier = AsyncPhaseNotifier(10);
      addTearDown(notifier.dispose);

      final e = Exception();
      final s = StackTrace.current;

      Object? error;
      StackTrace? stackTrace;

      final cancel = notifier.listenFor(
        onError: (e, s) {
          error = e;
          stackTrace = s;
        },
      );
      addTearDown(cancel);

      await notifier.update(() => Error.throwWithStackTrace(e, s));
      await pumpEventQueue();
      expect(error, e);
      expect(stackTrace, s);
    });

    test('No callback is called after subscription is cancelled', () async {
      final notifier = AsyncPhaseNotifier(null);
      addTearDown(notifier.dispose);

      var count1 = 0;
      var count2 = 0;

      final cancel1 = notifier.listenFor(
        onWaiting: (_) => count1++,
        onComplete: (_) => count1++,
        onError: (_, __) => count1++,
      );
      final cancel2 = notifier.listenFor(
        onWaiting: (_) => count2++,
        onComplete: (_) => count2++,
        onError: (_, __) => count2++,
      );
      addTearDown(cancel2);

      notifier
        ..value = const AsyncComplete(null)
        ..value = const AsyncError(error: '');
      await pumpEventQueue();
      expect(count1, 2);
      expect(count2, 2);

      cancel1();
      count1 = 0;
      count2 = 0;

      notifier
        ..value = const AsyncWaiting()
        ..value = const AsyncComplete(null)
        ..value = const AsyncError(error: '');
      await pumpEventQueue();
      expect(count1, isZero);
      expect(count2, 3);

      expect(notifier.isListening, isTrue);
      cancel2();
      expect(notifier.isListening, isFalse);
    });

    test('Listener is not added if all callbacks are omitted', () {
      final notifier = AsyncPhaseNotifier(null);
      addTearDown(notifier.dispose);

      // ignore: unused_result
      notifier.listenFor();
      expect(notifier.isListening, isFalse);
    });
  });

  group('dispose()', () {
    test('StreamController for events is closed when notifier is disposed', () {
      // ignore: unused_result
      final notifier = AsyncPhaseNotifier(null)..listen((_) {});
      expect(notifier.isListening, isTrue);
      expect(notifier.isClosed, isFalse);

      notifier.dispose();
      expect(notifier.isClosed, isTrue);
    });

    test('Using notifier after dispose() throws', () {
      final notifier = AsyncPhaseNotifier(null)..dispose();
      expect(
        notifier.listenFor,
        throwsA(predicate((e) => e.toString().contains('dispose'))),
      );
    });

    test(
      'Disposing notifier during update() does not throw but leaves the '
      'phase as AsyncWaiting with original data unchanged',
      () async {
        final notifier = AsyncPhaseNotifier(10);

        unawaited(
          Future<void>.delayed(Duration.zero, notifier.dispose),
        );
        final phase = await notifier.update(
          () => Future.delayed(
            const Duration(milliseconds: 1),
            () => Future.value(20),
          ),
        );

        expect(phase, const AsyncWaiting(10));
      },
    );
  });
}
