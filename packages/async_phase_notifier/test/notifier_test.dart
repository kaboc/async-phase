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

  group('listenError()', () {
    test('void function is returned', () {
      final cancel = AsyncPhaseNotifier(10).listenError((_, __) {});
      expect(cancel, isA<void Function()>());
    });

    test('Called when value changes to AsyncError by runAsync()', () async {
      final notifier = AsyncPhaseNotifier(10);
      var called = false;

      notifier.listenError((_, __) => called = true);
      expect(called, isFalse);

      await notifier.runAsync((_) => throw Exception());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(called, isTrue);
    });

    test('Called when value is updated to AsyncError manually', () async {
      final notifier = AsyncPhaseNotifier(10);
      var called = false;

      notifier.listenError((_, __) => called = true);
      expect(called, isFalse);

      // ignore: invalid_use_of_protected_member
      notifier.value = const AsyncError(data: 10);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(called, isTrue);
    });

    test('Called with error and stack trace', () async {
      final notifier = AsyncPhaseNotifier(10);
      final exception = Exception();

      Object? error;
      StackTrace? stackTrace;

      notifier.listenError((e, s) {
        error = e;
        stackTrace = s;
      });

      await notifier.runAsync((_) => throw exception);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(error, equals(exception));
      expect(stackTrace.toString(), startsWith('#0 '));
    });

    test('Called twice if two different errors occur in a row', () async {
      final notifier = AsyncPhaseNotifier(10);
      final errors = <Object?>[];
      notifier.listenError((e, _) => errors.add(e));

      // ignore: cascade_invocations, invalid_use_of_protected_member
      notifier.value = const AsyncError(error: 'error1');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // ignore: invalid_use_of_protected_member
      notifier.value = const AsyncError(error: 'error2');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(errors, equals(['error1', 'error2']));
    });

    test('Not called after subscription is cancelled', () async {
      final notifier = AsyncPhaseNotifier(10);
      var called1 = false;
      var called2 = false;

      final cancel1 = notifier.listenError((_, __) => called1 = true);
      notifier.listenError((_, __) => called2 = true);

      await notifier.runAsync((_) => throw Exception());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(called1, isTrue);
      expect(called2, isTrue);

      called1 = false;
      called2 = false;
      cancel1();

      await notifier.runAsync((_) => throw Exception());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(called1, isFalse);
      expect(called2, isTrue);
    });
  });
}
