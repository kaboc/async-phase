import 'package:test/test.dart';

import 'package:async_phase/async_phase.dart';

bool isNullable<T>(T value) => null is T;

void main() {
  group('Nullability of phases', () {
    test('data of AsyncComplete is nullable if generic type is nullable', () {
      final phase = AsyncComplete<int?>(10);
      expect(isNullable(phase.data), isTrue);
    });

    test('data of AsyncComplete is non-null if generic type is non-null', () {
      final phase = AsyncComplete<int>(10);
      expect(isNullable(phase.data), isFalse);
    });

    test('data of phases except AsyncComplete is always nullable', () {
      expect(isNullable(AsyncInitial<int>(10).data), isTrue);
      expect(isNullable(AsyncWaiting<int>(10).data), isTrue);
      expect(isNullable(AsyncError<int>(data: 10).data), isTrue);
    });

    test(
      'Phases except AsyncComplete accept null when generic type is non-null',
      () {
        final errorPhase = AsyncError<int>(
          // ignore: avoid_redundant_argument_values
          data: null,
          error: '',
          stackTrace: StackTrace.empty,
        );

        expect(AsyncInitial<int>(null).data, isNull);
        expect(AsyncWaiting<int>(null).data, isNull);
        expect(errorPhase.data, isNull);
      },
    );
  });

  group('Nullability of when() / whenOrNull()', () {
    test(
      '`complete` of when() is given a nullable if generic type is nullable',
      () {
        // It is tested in another file that whenOrNull() works similarly to
        // when(), so it is safe here to use whenOrNull() instead of when().
        final result = AsyncComplete<int?>(10).whenOrNull(
          complete: (data) {
            expect(isNullable(data), isTrue);
            return data;
          },
        );
        expect(result, equals(10));
      },
    );

    test(
      '`complete` of when() is given a non-null if generic type is non-null',
      () {
        final result = AsyncComplete<int>(10).whenOrNull(
          complete: (data) {
            expect(isNullable(data), isFalse);
            return data;
          },
        );
        expect(result, equals(10));
      },
    );

    test('callbacks of when() except `complete` is given a nullable', () {
      final result1 = AsyncInitial<int>(10).whenOrNull(
        initial: (data) {
          expect(isNullable(data), isTrue);
          return data;
        },
      );
      expect(result1, equals(10));

      final result2 = AsyncWaiting<int>(10).whenOrNull(
        waiting: (data) {
          expect(isNullable(data), isTrue);
          return data;
        },
      );
      expect(result2, equals(10));

      final result3 = AsyncError<int>(data: 10).whenOrNull(
        error: (data, _, __) {
          expect(isNullable(data), isTrue);
          return data;
        },
      );
      expect(result3, equals(10));
    });

    test('callbacks of when() can return null', () {
      var called1 = false;
      final result1 = AsyncInitial(10).whenOrNull(
        initial: (data) {
          called1 = true;
          return null;
        },
      );
      expect(called1, isTrue);
      expect(result1, isNull);

      var called2 = false;
      final result2 = AsyncWaiting(10).whenOrNull(
        waiting: (data) {
          called2 = true;
          return null;
        },
      );
      expect(called2, isTrue);
      expect(result2, isNull);

      var called3 = false;
      final result3 = AsyncComplete(10).whenOrNull(
        complete: (data) {
          called3 = true;
          return null;
        },
      );
      expect(called3, isTrue);
      expect(result3, isNull);

      var called4 = false;
      final result4 = AsyncError(data: 10).whenOrNull(
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
    test('Callback function can return null', () async {
      final result = await AsyncPhase.from<int?>(
        () => null,
        fallbackData: 10,
      );
      expect(result, isA<AsyncComplete>());
      expect(result.data, isNull);
    });

    test('fallbackData can be null', () async {
      final result = await AsyncPhase.from<int?>(
        () => throw Exception(),
        fallbackData: null,
      );
      expect(result, isA<AsyncError>());
      expect(result.data, isNull);
    });
  });
}
