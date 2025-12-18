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

    test(
      'Resulting AsyncError has latest  value in `data` if it was updated '
      'externally during execution of callback',
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

    test('Callbacks are called with correct values in correct order', () async {
      final notifier = AsyncPhaseNotifier(10);
      addTearDown(notifier.dispose);

      final called = <Object?>[];
      final error = Exception();

      await notifier.update(
        () async => 20,
        onWaiting: (waiting) => called.add('waiting: $waiting'),
        onComplete: (data) => called.add('complete: $data'),
        onError: (e, _) => called.add('error: $e'),
      );
      await notifier.update(
        () => throw error,
        onWaiting: (waiting) => called.add('waiting: $waiting'),
        onComplete: (data) => called.add('complete: $data'),
        onError: (e, _) => called.add('error: $e'),
      );
      expect(
        called,
        [
          'waiting: true',
          'waiting: false',
          'complete: 20',
          'waiting: true',
          'waiting: false',
          'error: $error',
        ],
      );
    });
  });

  group('updateOnlyPhase()', () {
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
          notifier.updateOnlyPhase(() async {
            completer.complete();
          }),
        );
        expect(notifier.value, const AsyncWaiting(10));
        await completer.future;
        await pumpEventQueue();
        expect(notifier.value, const AsyncComplete(10));

        completer = Completer<void>();
        unawaited(
          notifier.updateOnlyPhase(() async {
            completer.complete();
            Error.throwWithStackTrace(e, s);
          }),
        );
        expect(notifier.value, const AsyncWaiting(10));
        await completer.future;
        await pumpEventQueue();
        expect(notifier.value, AsyncError(data: 10, error: e, stackTrace: s));



      },
    );

    test('Callbacks are called with correct values in correct order', () async {
      final notifier = AsyncPhaseNotifier(10);
      addTearDown(notifier.dispose);

      final error = Exception();
      final called = <Object?>[];

      await notifier.updateOnlyPhase(
        () async => 20,
        onWaiting: (waiting) => called.add('waiting: $waiting'),
        onComplete: (data) => called.add('complete: $data'),
        onError: (e, _) => called.add('error: $e'),
      );
      await notifier.updateOnlyPhase(
        () => throw error,
        onWaiting: (waiting) => called.add('waiting: $waiting'),
        onComplete: (data) => called.add('complete: $data'),
        onError: (e, _) => called.add('error: $e'),
      );

      expect(called, [
        'waiting: true',
        'waiting: false',
        'complete: 10',
        'waiting: true',
        'waiting: false',
        'error: $error',
      ]);
    });
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
          onWaiting: (waiting) => phases.add(AsyncWaiting('$waiting')),
          onComplete: (v) => phases.add(AsyncComplete(v)),
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
            AsyncWaiting('true'),
            AsyncWaiting('true'),
            AsyncWaiting('false'),
            AsyncComplete('c'),
            AsyncError(data: '', error: 'err'),
            AsyncError(data: '', error: 'err'),
            AsyncWaiting('true'),
            AsyncWaiting('false'),
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
      expect(count2, 4);

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
