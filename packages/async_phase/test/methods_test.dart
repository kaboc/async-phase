import 'package:test/test.dart';

import 'package:async_phase/async_phase.dart';

void main() {
  group('when()', () {
    test('`initial` is called if phase is AsyncInitial', () {
      final result = const AsyncInitial(10).when(
        initial: (d) => '[initial] $d',
        waiting: (d) => '[waiting] $d',
        complete: (d) => '[complete] $d',
        error: (d, e, _) => '[error] $d, $e',
      );
      expect(result, '[initial] 10');
    });

    test('`waiting` is called if phase is AsyncWaiting', () {
      final result = const AsyncWaiting(10).when(
        initial: (d) => '[initial] $d',
        waiting: (d) => '[waiting] $d',
        complete: (d) => '[complete] $d',
        error: (d, e, _) => '[error] $d, $e',
      );
      expect(result, '[waiting] 10');
    });

    test('`complete` is called if phase is AsyncComplete', () {
      final result = const AsyncComplete(10).when(
        initial: (d) => '[initial] $d',
        waiting: (d) => '[waiting] $d',
        complete: (d) => '[complete] $d',
        error: (d, e, _) => '[error] $d, $e',
      );
      expect(result, '[complete] 10');
    });

    test(
      'callback of `complete` can return null even if phase is '
      'AsyncComplete with non-nullable generic type',
      () {
        final result = const AsyncComplete<int>(10).when(
          initial: (d) => '[initial] $d',
          waiting: (d) => '[waiting] $d',
          complete: (d) => null,
          error: (d, e, __) => '[error] $d, $e',
        );
        expect(result, null);
      },
    );

    test('`error` is called if phase is AsyncError', () {
      final result = const AsyncError(data: 10, error: 20).when(
        initial: (d) => '[initial] $d',
        waiting: (d) => '[waiting] $d',
        complete: (d) => '[complete] $d',
        error: (d, e, _) => '[error] $d, $e',
      );
      expect(result, '[error] 10, 20');
    });

    test('`error` is given correct error and stack trace', () {
      final phase = AsyncError(
        data: 10,
        error: 20,
        stackTrace: StackTrace.fromString('stack trace'),
      );

      final result = phase.when(
        initial: (_) => '',
        waiting: (_) => '',
        complete: (_) => '',
        error: (d, e, s) => '$d, $e, $s',
      );
      expect(result, '10, 20, stack trace');
    });

    test(
      '`waiting` is called if phase is AsyncInitial but `initial` is omitted',
      () {
        final result = const AsyncInitial(10).when(
          waiting: (d) => '[waiting] $d',
          complete: (d) => '[complete] $d',
          error: (d, e, _) => '[error] $d, $e',
        );
        expect(result, '[waiting] 10');
      },
    );
  });

  group('whenOrNull()', () {
    test('Matching callback is called', () {
      expect(const AsyncInitial(10).whenOrNull(initial: (d) => d), 10);
      expect(const AsyncWaiting(10).whenOrNull(waiting: (d) => d), 10);
      expect(const AsyncComplete(10).whenOrNull(complete: (d) => d), 10);
      expect(
        AsyncError(
          data: 10,
          error: 20,
          stackTrace: StackTrace.fromString('stack trace'),
        ).whenOrNull(error: (d, e, s) => '$d, $e, $s'),
        '10, 20, stack trace',
      );
    });

    test('Returns null if no parameter is specified', () {
      expect(const AsyncComplete(10).whenOrNull<Object?>(), isNull);
    });

    test('Returns null if there is no matching callback', () {
      expect(const AsyncInitial(10).whenOrNull(complete: (d) => d), isNull);
      expect(const AsyncWaiting(10).whenOrNull(complete: (d) => d), isNull);
      expect(const AsyncComplete(10).whenOrNull(waiting: (d) => d), isNull);
      expect(
        const AsyncError(data: 10, error: 20).whenOrNull(complete: (d) => d),
        isNull,
      );
    });

    test(
      '`waiting` is called if phase is AsyncInitial but `initial` is omitted',
      () {
        expect(const AsyncInitial(10).whenOrNull(waiting: (d) => d), 10);
      },
    );
  });

  group('from()', () {
    test('Returns AsyncComplete if successful', () async {
      final phase = await AsyncPhase.from(() => Future.value(10));
      expect(phase, const AsyncComplete(10));
    });

    test('Returns AsyncError with fallbackData if not successful', () async {
      final stackTrace = StackTrace.current;
      final phase = await AsyncPhase.from(
        () => Future<int>.error('error', stackTrace),
        fallbackData: 20,
      );
      expect(phase, isA<AsyncError>());
      expect(phase.data, 20);
      expect((phase as AsyncError).error, 'error');
      expect((phase as AsyncError).stackTrace, stackTrace);
    });

    test('AsyncError has null data if there is no fallbackData', () async {
      final phase = await AsyncPhase.from(() => throw Exception());
      expect(phase, isA<AsyncError>());
      expect(phase.data, null);
    });

    test('onComplete is called with data on complete', () async {
      Object? data;
      final phase = await AsyncPhase.from(
        () => Future.value(10),
        onComplete: (d) => data = d,
      );
      expect(phase.data, 10);
      expect(data, 10);
    });

    test('onComplete is not called if callback throws', () async {
      Object? data;
      final phase = await AsyncPhase.from(
        () => throw Exception(),
        fallbackData: 20,
        onComplete: (d) => data = d,
      );
      expect(phase.data, 20);
      expect(data, null);
    });

    test('onError is called with error and stack trace on error', () async {
      Object? dataOnError;
      Object? error;
      StackTrace? stackTrace;
      final exception = Exception();

      final phase = await AsyncPhase.from(
        () => throw exception,
        fallbackData: 20,
        onError: (d, e, s) {
          dataOnError = d;
          error = e;
          stackTrace = s;
        },
      );
      expect(phase, isA<AsyncError>());
      expect(phase.data, 20);
      expect(dataOnError, 20);
      expect(error, exception);
      expect(stackTrace.toString(), startsWith('#0 '));
    });

    test('onError receives null data if there is no fallbackData', () async {
      Object? dataOnError;
      Object? error;
      final exception = Exception();

      await AsyncPhase.from(
        () => throw exception,
        onError: (d, e, s) {
          dataOnError = d;
          error = e;
        },
      );
      expect(dataOnError, null);
      expect(error, exception);
    });

    test('onError is not called if callback has no error', () async {
      Object? dataOnError;
      Object? error;
      StackTrace? stackTrace;

      final phase = await AsyncPhase.from(
        () => Future.value(10),
        onError: (d, e, s) {
          dataOnError = d;
          error = e;
          stackTrace = s;
        },
      );
      expect(phase.data, 10);
      expect(dataOnError, null);
      expect(error, null);
      expect(stackTrace, null);
    });

    test('Does not capture error thrown in onComplete callback', () async {
      expect(
        () => AsyncPhase.from(
          () => Future.value(10),
          onComplete: (_) => throw Exception(),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('Does not capture error thrown in onError callback', () async {
      expect(
        () => AsyncPhase.from(
          () => throw Exception('error1'),
          onError: (_, __, ___) => throw Exception('error2'),
        ),
        throwsA(predicate((e) => e.toString().contains('error2'))),
      );
    });
  });

  group('convert()', () {
    test('initial', () {
      expect(
        const AsyncInitial<int?>().convert((d) => '$d'),
        const AsyncInitial('null'),
      );
      expect(
        const AsyncInitial(10).convert((d) => '$d'),
        const AsyncInitial('10'),
      );
    });

    test('waiting', () {
      expect(
        const AsyncWaiting<int?>().convert((d) => '$d'),
        const AsyncWaiting('null'),
      );
      expect(
        const AsyncWaiting(10).convert((d) => '$d'),
        const AsyncWaiting('10'),
      );
    });

    test('complete', () {
      expect(
        const AsyncComplete<int?>(null).convert((d) => '$d'),
        const AsyncComplete('null'),
      );
      expect(
        const AsyncComplete(10).convert((d) => '$d'),
        const AsyncComplete('10'),
      );
      expect(
        const AsyncComplete(10).convert((d) => null),
        const AsyncComplete(null),
      );
    });

    test('error', () {
      const e = 'error';
      final s = StackTrace.current;

      expect(
        AsyncError<int?>(error: e, stackTrace: s).convert((d) => '$d'),
        AsyncError(data: 'null', error: e, stackTrace: s),
      );
      expect(
        AsyncError(data: 10, error: e, stackTrace: s).convert((d) => '$d'),
        AsyncError(data: '10', error: e, stackTrace: s),
      );
    });
  });

  group('Copy', () {
    test('copyWith()', () {
      expect(const AsyncInitial(10).copyWith(20), const AsyncInitial(20));
      expect(const AsyncWaiting(10).copyWith(20), const AsyncWaiting(20));
      expect(const AsyncComplete(10).copyWith(20), const AsyncComplete(20));

      final stack = StackTrace.current;
      expect(
        AsyncError(data: 10, error: 'error', stackTrace: stack).copyWith(20),
        AsyncError(data: 20, error: 'error', stackTrace: stack),
      );
    });

    test('AsyncWaiting created with copyAsWaiting() has preserved value', () {
      expect(const AsyncComplete(10).copyAsWaiting(), const AsyncWaiting(10));
    });
  });

  group('rethrowError()', () {
    test(
      'Error thrown with rethrowError() inherits error and stackTrace '
      'from AsyncError the method was called on',
      () {
        final phase =
            AsyncError(error: Exception(), stackTrace: StackTrace.current);

        Object? error;
        StackTrace? stackTrace;

        try {
          phase.rethrowError();
        } on Exception catch (e, s) {
          error = e;
          stackTrace = s;
        }
        expect((error, stackTrace), (phase.error, phase.stackTrace));
      },
    );
  });
}
