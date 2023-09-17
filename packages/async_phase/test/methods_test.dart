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
    test('Returns AsyncComplete if successful', () async {
      final result = await AsyncPhase.from(
        () => Future.value(10),
        fallbackData: 0,
      );
      expect(result, const AsyncComplete(10));
    });

    test('Returns AsyncError with fallbackValue if not successful', () async {
      final result = await AsyncPhase.from(
        () => Future<int>.error('error'),
        fallbackData: 0,
      );
      expect(result, isA<AsyncError>());
      expect(result.data, 0);
      expect((result as AsyncError).error, 'error');
    });

    test('onError is called with error and stack trace on error', () async {
      Object? error;
      StackTrace? stackTrace;
      final exception = Exception();

      final phase = await AsyncPhase.from(
        () => throw exception,
        fallbackData: 0,
        onError: (e, s) {
          error = e;
          stackTrace = s;
        },
      );
      expect(error, exception);
      expect(stackTrace.toString(), startsWith('#0 '));

      final errorPhase = phase as AsyncError<int>;
      expect(errorPhase.error, exception);
      expect(errorPhase.stackTrace, stackTrace);
    });

    test('Callback function can return non-Future', () async {
      final result = await AsyncPhase.from(
        () => 10,
        fallbackData: 20,
      );
      expect(result.data, 10);
    });
  });

  group('copyAsWaiting()', () {
    test('AsyncWaiting created with copyAsWaiting() has preserved value', () {
      expect(const AsyncComplete(10).copyAsWaiting(), const AsyncWaiting(10));
    });
  });
}
