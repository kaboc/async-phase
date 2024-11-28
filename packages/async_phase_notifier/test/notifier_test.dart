// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:async_phase_notifier/async_phase_notifier.dart';

bool isNullable<T>(T value) => null is T;

void main() {
  group('update()', () {
    test('Phase is AsyncInitial when notifier is created', () {
      final notifier = AsyncPhaseNotifier(10);
      expect(notifier.value, isA<AsyncInitial<int>>());
    });

    test('Callback function is given existing data', () async {
      final notifier = AsyncPhaseNotifier(10);
      int? d;
      await notifier.update((data) {
        d = data;
        return Future.value(data);
      });
      expect(d, 10);
    });

    test('data is initially null when none is passed', () {
      final notifier = AsyncPhaseNotifier();
      expect(notifier.value.data, isNull);
    });

    test('passed data is nullable even if generic type is non-null', () async {
      final notifier = AsyncPhaseNotifier<int>(10);
      expect(notifier.value, isA<AsyncPhase<int>>());

      bool? nullable;
      await notifier.update((data) {
        nullable = isNullable(data);
        return Future.value(data);
      });
      expect(nullable, isTrue);
    });

    test('Phase turns into AsyncWaiting immediately', () async {
      final notifier = AsyncPhaseNotifier(10);
      unawaited(
        notifier.update((_) async {
          await pumpEventQueue();
          return Future.value(20);
        }),
      );
      expect(notifier.value.data, 10);
      expect(notifier.value, isA<AsyncWaiting<int>>());
    });

    test('Result is AsyncComplete with correct data if successful', () async {
      final notifier = AsyncPhaseNotifier(10);
      final phase = await notifier.update((_) => Future.value(20));
      expect(phase, isA<AsyncComplete<int>>());
      expect(notifier.value, isA<AsyncComplete<int>>());
      expect(phase.data, 20);
    });

    test('Result is AsyncError with previous data if not successful', () async {
      final notifier1 = AsyncPhaseNotifier(10);
      final phase1 = await notifier1.update((_) => throw Exception());
      expect(phase1, isA<AsyncError<int>>());
      expect(notifier1.value, isA<AsyncError<int>>());
      expect(phase1.data, 10);

      final notifier2 = AsyncPhaseNotifier<int?>(10);
      final phase2 = await notifier2.update((_) => throw Exception());
      expect(phase2, isNot(isA<AsyncError<int>>()));
      expect(notifier2.value, isNot(isA<AsyncError<int>>()));
      expect(phase2.data, 10);
    });

    test('AsyncError has error info', () async {
      final notifier = AsyncPhaseNotifier(10);
      final exception = Exception();
      final phase =
          await notifier.update((_) => throw exception) as AsyncError<int>;
      expect(phase.error, exception);
      expect(phase.stackTrace.toString(), startsWith('#0 '));
    });

    test(
      'Resulting AsyncError has latest value in `data` if `value.data` '
      'is updated externally while callback is executed',
      () async {
        final called = <String>[];
        final notifier = AsyncPhaseNotifier(10);

        await Future.wait([
          notifier.update((_) async {
            called.add('a1');
            await Future<void>.delayed(const Duration(milliseconds: 10));
            called.add('a2');
            throw Exception();
          }),
          notifier.update((_) async {
            called.add('b');
            return 20;
          }),
        ]);

        expect(called, ['a1', 'b', 'a2']);
        expect(notifier.value, isA<AsyncError>());
        expect(notifier.value.data, 20);
      },
    );
  });

  group('updateOnlyPhase()', () {
    test(
      'Phase is AsyncInitial initially and then AsyncWaiting until '
      'updateOnlyPhase() ends',
      () async {
        final notifier = AsyncPhaseNotifier(10);
        expect(notifier.value, isA<AsyncInitial<int>>());

        final completer = Completer<void>();
        unawaited(
          notifier.updateOnlyPhase((_) async {
            await pumpEventQueue();
            completer.complete();
          }),
        );
        expect(notifier.value, isA<AsyncWaiting<int>>());

        await completer.future;
        expect(notifier.value, isA<AsyncComplete<int>>());
      },
    );

    test('Phase changes to AsyncComplete and keeps previous data', () async {
      final notifier = AsyncPhaseNotifier(10);
      final phase = await notifier.updateOnlyPhase((_) async => 20);
      expect(phase, isA<AsyncComplete<int>>());
      expect(notifier.value, isA<AsyncComplete<int>>());
      expect(phase.data, 10);
    });
  });

  group('data getter', () {
    test(
      'data getter returns non-null value when generic type is non nullable',
      () {
        final notifier1 = AsyncPhaseNotifier<int?>();
        final notifier2 = AsyncPhaseNotifier(10);

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
        final notifier = AsyncPhaseNotifier('abc');
        final phases = <AsyncPhase<String>>[];

        final cancel = notifier.listen(phases.add);
        addTearDown(cancel);

        notifier
          ..value = const AsyncInitial('abc')
          ..value = const AsyncComplete('abc')
          ..value = const AsyncComplete('abc')
          ..value = const AsyncComplete('def')
          ..value = const AsyncWaiting('def')
          ..value = const AsyncWaiting('def')
          ..value = const AsyncWaiting('ghi')
          ..value = const AsyncComplete('ghi')
          ..value = const AsyncError(data: 'ghi', error: 'err')
          ..value = const AsyncError(data: 'ghi', error: 'err')
          ..value = const AsyncError(data: 'jkl', error: 'err')
          ..value = const AsyncWaiting('jkl')
          ..value = const AsyncError(data: 'jkl', error: 'err');

        await pumpEventQueue();

        expect(
          phases,
          orderedEquals(const [
            AsyncComplete('abc'),
            AsyncComplete('def'),
            AsyncWaiting('def'),
            AsyncWaiting('ghi'),
            AsyncComplete('ghi'),
            AsyncError(data: 'ghi', error: 'err'),
            AsyncError(data: 'jkl', error: 'err'),
            AsyncWaiting('jkl'),
            AsyncError(data: 'jkl', error: 'err'),
          ]),
        );
      },
    );

    test('Callback is not called after subscription is cancelled', () async {
      final notifier = AsyncPhaseNotifier<void>();
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
        final notifier = AsyncPhaseNotifier('abc');
        final phases = <AsyncPhase<String>>[];

        final cancel = notifier.listenFor(
          onWaiting: (waiting) => phases.add(AsyncWaiting('$waiting')),
          onComplete: (v) => phases.add(AsyncComplete(v)),
          onError: (e, _) => phases.add(AsyncError(data: '', error: e)),
        );
        addTearDown(cancel);

        notifier
          ..value = const AsyncInitial('abc')
          ..value = const AsyncComplete('abc')
          ..value = const AsyncComplete('abc')
          ..value = const AsyncComplete('def')
          ..value = const AsyncWaiting('def')
          ..value = const AsyncWaiting('def')
          ..value = const AsyncWaiting('ghi')
          ..value = const AsyncComplete('ghi')
          ..value = const AsyncError(data: 'ghi', error: 'err')
          ..value = const AsyncError(data: 'ghi', error: 'err')
          ..value = const AsyncError(data: 'jkl', error: 'err')
          ..value = const AsyncWaiting('jkl')
          ..value = const AsyncError(data: 'jkl', error: 'err');

        await pumpEventQueue();

        expect(
          phases,
          orderedEquals(const [
            AsyncComplete('abc'),
            AsyncComplete('def'),
            AsyncWaiting('true'),
            AsyncWaiting('true'),
            AsyncWaiting('false'),
            AsyncComplete('ghi'),
            AsyncError(data: '', error: 'err'),
            AsyncError(data: '', error: 'err'),
            AsyncWaiting('true'),
            AsyncWaiting('false'),
            AsyncError(data: '', error: 'err'),
          ]),
        );
      },
    );

    test('onError is called with error and stack trace', () async {
      final notifier = AsyncPhaseNotifier(10);
      final exception = Exception();

      Object? error;
      StackTrace? stackTrace;

      final cancel = notifier.listenFor(
        onError: (e, s) {
          error = e;
          stackTrace = s;
        },
      );
      addTearDown(cancel);

      await notifier.update((_) => throw exception);
      await pumpEventQueue();
      expect(error, exception);
      expect(stackTrace.toString(), startsWith('#0 '));
    });

    test('No callback is called after subscription is cancelled', () async {
      final notifier = AsyncPhaseNotifier<void>();
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
      // ignore: unused_result
      final notifier = AsyncPhaseNotifier<void>()..listenFor();
      expect(notifier.isListening, isFalse);
    });
  });

  group('dispose()', () {
    test('StreamController for events is closed when notifier is disposed', () {
      // ignore: unused_result
      final notifier = AsyncPhaseNotifier<void>()..listen((_) {});
      expect(notifier.isListening, isTrue);
      expect(notifier.isClosed, isFalse);

      notifier.dispose();
      expect(notifier.isClosed, isTrue);
    });

    test('Using notifier after dispose() throws', () {
      final notifier = AsyncPhaseNotifier<void>()..dispose();
      expect(
        notifier.listenFor,
        throwsA(predicate((e) => e.toString().contains('dispose'))),
      );
    });
  });
}
