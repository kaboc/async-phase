// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:async_phase_notifier/async_phase_notifier.dart';

bool isNullable<T>(T value) => null is T;

void main() {
  group('runAsync()', () {
    test('Phase is AsyncInitial when notifier is created', () {
      final notifier = AsyncPhaseNotifier(10);
      expect(notifier.value, isA<AsyncInitial<int>>());
    });

    test('Callback function is given existing data', () async {
      final notifier = AsyncPhaseNotifier(10);
      int? d;
      await notifier.runAsync((data) {
        d = data;
        return Future.value(data);
      });
      expect(d, equals(10));
    });

    test('data is initially null when none is passed', () {
      final notifier = AsyncPhaseNotifier();
      expect(notifier.value.data, isNull);
    });

    test('passed data is nullable even if generic type is non-null', () async {
      final notifier = AsyncPhaseNotifier<int>(10);
      expect(notifier.value, isA<AsyncPhase<int>>());

      bool? nullable;
      await notifier.runAsync((data) {
        nullable = isNullable(data);
        return Future.value(data);
      });
      expect(nullable, isTrue);
    });

    test('Callback can return non-Future', () async {
      final notifier = AsyncPhaseNotifier(10);
      final phase = await notifier.runAsync((_) => 20);
      expect(phase.data, equals(20));
    });

    test('Phase turns into AsyncWaiting immediately', () async {
      final notifier = AsyncPhaseNotifier(10);
      unawaited(
        notifier.runAsync((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return Future.value(20);
        }),
      );
      expect(notifier.value, isA<AsyncWaiting<int>>());
    });

    test('Phase is AsyncComplete and has correct data if successful', () async {
      final notifier = AsyncPhaseNotifier(10);
      final phase = await notifier.runAsync((_) => 20);
      expect(phase, isA<AsyncComplete<int>>());
      expect(notifier.value, isA<AsyncComplete<int>>());
      expect(phase.data, equals(20));
    });

    test('Phase is AsyncError and has prev data if not successful', () async {
      final notifier1 = AsyncPhaseNotifier(10);
      final phase1 = await notifier1.runAsync((_) => throw Exception());
      expect(phase1, isA<AsyncError<int>>());
      expect(notifier1.value, isA<AsyncError<int>>());
      expect(phase1.data, equals(10));

      final notifier2 = AsyncPhaseNotifier<int?>();
      final phase2 = await notifier2.runAsync((_) => throw Exception());
      expect(phase2, isA<AsyncError<int?>>());
      expect(notifier2.value, isA<AsyncError<int?>>());
      expect(phase2.data, isNull);
    });

    test('AsyncError has error info', () async {
      final notifier = AsyncPhaseNotifier(10);
      final exception = Exception();
      final phase =
          await notifier.runAsync((_) => throw exception) as AsyncError<int>;
      expect(phase.error, equals(exception));
      expect(phase.stackTrace.toString(), startsWith('#0 '));
    });
  });

  test(
    'Appropriate callbacks is called when phase changes or '
    'when content changes while phase stays the same',
    () async {
      final notifier = AsyncPhaseNotifier('abc');
      final phases = <AsyncPhase<String>>[];

      final cancel = notifier.listen(
        onWaiting: (waiting) => phases.add(AsyncWaiting('$waiting')),
        onComplete: (v) => phases.add(AsyncComplete(v)),
        onError: (e, _) => phases.add(AsyncError(data: '', error: '$e')),
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
        ..value = const AsyncError(data: 'ghi')
        ..value = const AsyncError(data: 'ghi')
        ..value = const AsyncError(data: 'jkl')
        ..value = const AsyncWaiting('jkl')
        ..value = const AsyncError(data: 'jkl');

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        phases,
        orderedEquals(const [
          AsyncComplete('abc'),
          AsyncComplete('def'),
          AsyncWaiting('true'),
          AsyncWaiting('true'),
          AsyncWaiting('false'),
          AsyncComplete('ghi'),
          AsyncError(data: '', error: 'null'),
          AsyncError(data: '', error: 'null'),
          AsyncWaiting('true'),
          AsyncWaiting('false'),
          AsyncError(data: '', error: 'null'),
        ]),
      );
    },
  );

  test('onError is called with error and stack trace', () async {
    final notifier = AsyncPhaseNotifier(10);
    final exception = Exception();

    Object? error;
    StackTrace? stackTrace;

    final cancel = notifier.listen(
      onError: (e, s) {
        error = e;
        stackTrace = s;
      },
    );
    addTearDown(cancel);

    await notifier.runAsync((_) => throw exception);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(error, equals(exception));
    expect(stackTrace.toString(), startsWith('#0 '));
  });

  test('No callback is called after subscription is cancelled', () async {
    final notifier = AsyncPhaseNotifier<void>();
    var count1 = 0;
    var count2 = 0;

    final cancel1 = notifier.listen(
      onWaiting: (_) => count1++,
      onComplete: (_) => count1++,
      onError: (_, __) => count1++,
    );
    final cancel2 = notifier.listen(
      onWaiting: (_) => count2++,
      onComplete: (_) => count2++,
      onError: (_, __) => count2++,
    );
    addTearDown(cancel2);

    notifier
      ..value = const AsyncComplete(null)
      ..value = const AsyncError();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(count1, equals(2));
    expect(count2, equals(2));

    count1 = 0;
    count2 = 0;
    cancel1();

    notifier
      ..value = const AsyncWaiting()
      ..value = const AsyncComplete(null)
      ..value = const AsyncError();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(count1, isZero);
    expect(count2, equals(4));

    expect(notifier.isListening, isTrue);
    cancel2();
    expect(notifier.isListening, isFalse);
  });

  test('Listener is not added if all callbacks are omitted', () {
    // ignore: unused_result
    final notifier = AsyncPhaseNotifier<void>()..listen();
    expect(notifier.hasListeners, isFalse);
  });
}
