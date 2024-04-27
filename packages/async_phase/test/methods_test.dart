import 'package:test/test.dart';

import 'package:async_phase/async_phase.dart';

void main() {
  group('when()', () {
    test('`initial` is called if phase is AsyncInitial', () {
      final result = const AsyncInitial(10).when(
        initial: (d) => '[initial] $d',
        waiting: (d) => '[waiting] $d',
        complete: (d) => '[complete] $d',
        error: (d, _, __) => '[error] $d',
      );
      expect(result, '[initial] 10');
    });

    test('`waiting` is called if phase is AsyncWaiting', () {
      final result = const AsyncWaiting(10).when(
        initial: (d) => '[initial] $d',
        waiting: (d) => '[waiting] $d',
        complete: (d) => '[complete] $d',
        error: (d, _, __) => '[error] $d',
      );
      expect(result, '[waiting] 10');
    });

    test('`complete` is called if phase is AsyncComplete', () {
      final result = const AsyncComplete(10).when(
        initial: (d) => '[initial] $d',
        waiting: (d) => '[waiting] $d',
        complete: (d) => '[complete] $d',
        error: (d, _, __) => '[error] $d',
      );
      expect(result, '[complete] 10');
    });

    test('`error` is called if phase is AsyncError', () {
      final result = const AsyncError(data: 10).when(
        initial: (d) => '[initial] $d',
        waiting: (d) => '[waiting] $d',
        complete: (d) => '[complete] $d',
        error: (d, _, __) => '[error] $d',
      );
      expect(result, '[error] 10');
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
          error: (d, _, __) => '[error] $d',
        );
        expect(result, '[waiting] 10');
      },
    );
  });

  group('whenOrNull()', () {
    test('Matching callback is called', () {
      final stackTrace = StackTrace.fromString('stack trace');

      expect(const AsyncInitial(10).whenOrNull(initial: (d) => d), 10);
      expect(const AsyncWaiting(10).whenOrNull(waiting: (d) => d), 10);
      expect(const AsyncComplete(10).whenOrNull(complete: (d) => d), 10);
      expect(
        AsyncError(data: 10, error: 20, stackTrace: stackTrace)
            .whenOrNull(error: (d, e, s) => '$d, $e, $s'),
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
      expect(const AsyncError(data: 10).whenOrNull(complete: (d) => d), isNull);
    });

    test(
      '`waiting` is called if phase is AsyncInitial but `initial` is omitted',
      () {
        expect(const AsyncInitial(10).whenOrNull(waiting: (d) => d), 10);
      },
    );
  });

  group('from()', () {
    test('Callback function can return non-Future', () async {
      final phase = await AsyncPhase.from(() => 10);
      expect(phase.data, 10);
    });

    test('Returns AsyncComplete if successful', () async {
      final phase = await AsyncPhase.from(() => Future.value(10));
      expect(phase, const AsyncComplete(10));
    });

    test('Returns AsyncError with fallbackValue if not successful', () async {
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

    test('onComplete is called with data on complete', () async {
      Object? data;
      final phase = await AsyncPhase.from<int, int>(
        () => 10,
        onComplete: (d) => data = d,
      );
      expect(phase.data, 10);
      expect(data, 10);
    });

    test('onComplete is not called if callback throws', () async {
      Object? data;
      final phase = await AsyncPhase.from<int, int>(
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

      final phase = await AsyncPhase.from<int, int>(
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

    test('onError is not called if callback has no error', () async {
      Object? dataOnError;
      Object? error;
      StackTrace? stackTrace;

      final phase = await AsyncPhase.from<int, int>(
        () => 10,
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
  });

  group('copyWith()', () {
    test('On AsyncInitial', () {
      expect(const AsyncInitial(10).copyWith(20), const AsyncInitial(20));
    });

    test('On AsyncWaiting', () {
      expect(const AsyncWaiting(10).copyWith(20), const AsyncWaiting(20));
    });

    test('On AsyncComplete', () {
      expect(const AsyncComplete(10).copyWith(20), const AsyncComplete(20));
    });

    test('On AsyncError', () {
      const error = 'error';
      const stack = StackTrace.empty;

      expect(
        const AsyncError(data: 10, error: error, stackTrace: stack)
            .copyWith(20),
        const AsyncError(data: 20, error: error, stackTrace: stack),
      );
    });
  });

  group('copyAsWaiting()', () {
    test('AsyncWaiting created with copyAsWaiting() has preserved value', () {
      expect(const AsyncComplete(10).copyAsWaiting(), const AsyncWaiting(10));
    });
  });
}
