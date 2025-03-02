import 'package:test/test.dart';

import 'package:async_phase/async_phase.dart';

bool isNullable<T>(T value) => null is T;

void main() {
  group('Nullability of phases', () {
    test('data of AsyncComplete is nullable if generic type is nullable', () {
      const phase = AsyncComplete<int?>(10);
      expect(isNullable(phase.data), isTrue);
    });

    test('data of AsyncComplete is non-null if generic type is non-null', () {
      const phase = AsyncComplete<int>(10);
      expect(isNullable(phase.data), isFalse);
    });

    test('data of phases except AsyncComplete is always nullable', () {
      expect(isNullable(const AsyncInitial<int>(10).data), isTrue);
      expect(isNullable(const AsyncWaiting<int>(10).data), isTrue);
      expect(
        isNullable(const AsyncError<int>(data: 10, error: 20).data),
        isTrue,
      );
    });

    test(
      'Phases except AsyncComplete accept null when generic type is non-null',
      () {
        expect(const AsyncInitial<int>(null).data, isNull);
        expect(const AsyncWaiting<int>(null).data, isNull);
        // ignore: avoid_redundant_argument_values
        expect(const AsyncError<int>(data: null, error: '').data, isNull);
      },
    );
  });

  group('Nullability of when()', () {
    test(
      'data param of callbacks other than `error` in when() follows the '
      'nullability of generic type',
      () {
        final result1 = const AsyncInitial<int>(10).when(
          initial: (data) {
            expect(isNullable(data), isFalse);
            return data;
          },
          waiting: (_) => null,
          complete: (_) => null,
          error: (_, __, ___) => null,
        );
        expect(result1, 10);

        final result2 = const AsyncInitial<int?>(10).when(
          initial: (data) {
            expect(isNullable(data), isTrue);
            return data;
          },
          waiting: (_) => null,
          complete: (_) => null,
          error: (_, __, ___) => null,
        );
        expect(result2, 10);

        final result3 = const AsyncWaiting<int>(10).when(
          waiting: (data) {
            expect(isNullable(data), isFalse);
            return data;
          },
          initial: (_) => null,
          complete: (_) => null,
          error: (_, __, ___) => null,
        );
        expect(result3, 10);

        final result4 = const AsyncWaiting<int?>(10).when(
          waiting: (data) {
            expect(isNullable(data), isTrue);
            return data;
          },
          initial: (_) => null,
          complete: (_) => null,
          error: (_, __, ___) => null,
        );
        expect(result4, 10);

        final result5 = const AsyncComplete<int>(10).when(
          complete: (data) {
            expect(isNullable(data), isFalse);
            return data;
          },
          initial: (_) => null,
          waiting: (_) => null,
          error: (_, __, ___) => null,
        );
        expect(result5, 10);

        final result6 = const AsyncComplete<int?>(10).when(
          complete: (data) {
            expect(isNullable(data), isTrue);
            return data;
          },
          initial: (_) => null,
          waiting: (_) => null,
          error: (_, __, ___) => null,
        );
        expect(result6, 10);
      },
    );

    test('data param of the error callback of when() is always nullable', () {
      final result1 = const AsyncError<int>(data: 10, error: 20).when(
        error: (data, _, __) {
          expect(isNullable(data), isTrue);
          return data;
        },
        initial: (_) => null,
        waiting: (_) => null,
        complete: (_) => null,
      );
      expect(result1, 10);

      final result2 = const AsyncError<int?>(data: 10, error: 20).when(
        error: (data, _, __) {
          expect(isNullable(data), isTrue);
          return data;
        },
        initial: (_) => null,
        waiting: (_) => null,
        complete: (_) => null,
      );
      expect(result2, 10);
    });
  });

  group('Nullability of whenOrNull()', () {
    test(
      'data param of callbacks other than `error` in whenOrNull() follows '
      'the nullability of generic type',
      () {
        final result1 = const AsyncInitial<int>(10).whenOrNull(
          initial: (data) {
            expect(isNullable(data), isFalse);
            return data;
          },
        );
        expect(result1, 10);

        final result2 = const AsyncInitial<int?>(10).whenOrNull(
          initial: (data) {
            expect(isNullable(data), isTrue);
            return data;
          },
        );
        expect(result2, 10);

        final result3 = const AsyncWaiting<int>(10).whenOrNull(
          waiting: (data) {
            expect(isNullable(data), isFalse);
            return data;
          },
        );
        expect(result3, 10);

        final result4 = const AsyncWaiting<int?>(10).whenOrNull(
          waiting: (data) {
            expect(isNullable(data), isTrue);
            return data;
          },
        );
        expect(result4, 10);

        final result5 = const AsyncComplete<int>(10).whenOrNull(
          complete: (data) {
            expect(isNullable(data), isFalse);
            return data;
          },
        );
        expect(result5, 10);

        final result6 = const AsyncComplete<int?>(10).whenOrNull(
          complete: (data) {
            expect(isNullable(data), isTrue);
            return data;
          },
        );
        expect(result6, 10);
      },
    );

    test(
      'data param of the error callback of whenOrNull() is always nullable',
      () {
        final result1 = const AsyncError<int>(data: 10, error: 20).whenOrNull(
          error: (data, _, __) {
            expect(isNullable(data), isTrue);
            return data;
          },
        );
        expect(result1, 10);

        final result2 = const AsyncError<int?>(data: 10, error: 20).whenOrNull(
          error: (data, _, __) {
            expect(isNullable(data), isTrue);
            return data;
          },
        );
        expect(result2, 10);
      },
    );

    test('callbacks of when() can return null', () {
      var called1 = false;
      final result1 = const AsyncInitial(10).when(
        initial: (data) {
          called1 = true;
          return null;
        },
        waiting: (_) => null,
        complete: (_) => null,
        error: (_, __, ___) => null,
      );
      expect(called1, isTrue);
      expect(result1, isNull);

      var called2 = false;
      final result2 = const AsyncWaiting(10).when(
        waiting: (data) {
          called2 = true;
          return null;
        },
        initial: (_) => null,
        complete: (_) => null,
        error: (_, __, ___) => null,
      );
      expect(called2, isTrue);
      expect(result2, isNull);

      var called3 = false;
      final result3 = const AsyncComplete(10).when(
        complete: (data) {
          called3 = true;
          return null;
        },
        initial: (_) => null,
        waiting: (_) => null,
        error: (_, __, ___) => null,
      );
      expect(called3, isTrue);
      expect(result3, isNull);

      var called4 = false;
      final result4 = const AsyncError(data: 10, error: 20).when(
        error: (data, _, __) {
          called4 = true;
          return null;
        },
        initial: (_) => null,
        waiting: (_) => null,
        complete: (_) => null,
      );
      expect(called4, isTrue);
      expect(result4, isNull);
    });

    test('callbacks of whenOrNull() can return null', () {
      var called1 = false;
      final result1 = const AsyncInitial(10).whenOrNull(
        initial: (data) {
          called1 = true;
          return null;
        },
      );
      expect(called1, isTrue);
      expect(result1, isNull);

      var called2 = false;
      final result2 = const AsyncWaiting(10).whenOrNull(
        waiting: (data) {
          called2 = true;
          return null;
        },
      );
      expect(called2, isTrue);
      expect(result2, isNull);

      var called3 = false;
      final result3 = const AsyncComplete(10).whenOrNull(
        complete: (data) {
          called3 = true;
          return null;
        },
      );
      expect(called3, isTrue);
      expect(result3, isNull);

      var called4 = false;
      final result4 = const AsyncError(data: 10, error: 20).whenOrNull(
        error: (data, _, __) {
          called4 = true;
          return null;
        },
      );
      expect(called4, isTrue);
      expect(result4, isNull);
    });
  });

  group('Nullability of from()', () {
    test(
      'Callback can return null if first generic type parameter is nullable',
      () async {
        final phase = await AsyncPhase.from<int?, int>(() async => null);
        expect(phase, isA<AsyncComplete>());
        expect(phase.data, isNull);
      },
    );

    test(
      'Non-nullability of callback result is not affected by nullability '
      'of fallbackData',
      () async {
        // Makes sure `isA<AsyncComplete<T>>` passes only if T is non-nullable.
        expect(const AsyncComplete(null), isNot(isA<AsyncComplete<int>>()));

        final phase = await AsyncPhase.from(
          () => Future.value(10),
          fallbackData: null,
        );
        expect(phase, isA<AsyncComplete<int>>());
      },
    );
  });

  group('Nullability related to null data in non-nullable AsyncError', () {
    test(
      'Using when() does not throw when the generic type of an AsyncPhase '
      'object is non-nullable but its data is null',
      () async {
        final phase = await AsyncPhase.from<int, int>(() => throw Exception());
        expect(
          phase.when(
            error: (data, e, s) => 10,
            initial: (_) => 10,
            waiting: (_) => 10,
            complete: (_) => 10,
          ),
          isNot(throwsA(anything)),
        );
      },
    );

    test(
      'Using whenOrNull() does not throw when the generic type of an '
      'AsyncPhase object is non-nullable but its data is null',
      () async {
        final phase = await AsyncPhase.from<int, int>(() => throw Exception());
        expect(
          phase.whenOrNull(error: (data, e, s) => 10),
          isNot(throwsA(anything)),
        );
      },
    );

    test(
      'Using convert() does not throw when the generic type of an AsyncPhase '
      'object is non-nullable but its data is null',
      () async {
        final phase = await AsyncPhase.from<int, int>(() => throw Exception());
        expect(
          phase.whenOrNull(error: (data, e, s) => 10),
          isNot(throwsA(anything)),
        );
      },
    );
  });
}
