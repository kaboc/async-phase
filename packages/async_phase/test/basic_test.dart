// ignore_for_file: prefer_const_constructors

import 'package:test/test.dart';

import 'package:async_phase/async_phase.dart';

Matcher isNotEqual(Object? valueOrMatcher) => isNot(equals(valueOrMatcher));

void main() {
  group('Equality', () {
    test('Objects of same type with same values are equal', () {
      expect(AsyncInitial(10), AsyncInitial(10));
      expect(AsyncWaiting(10), AsyncWaiting(10));
      expect(AsyncComplete(10), AsyncComplete(10));

      final stackTrace = StackTrace.current;
      expect(
        AsyncError(data: 10, error: 20, stackTrace: stackTrace),
        AsyncError(data: 10, error: 20, stackTrace: stackTrace),
      );
    });

    test('Objects of same type with same values have same hashCode', () {
      expect(AsyncInitial(10).hashCode, AsyncInitial(10).hashCode);
      expect(AsyncWaiting(10).hashCode, AsyncWaiting(10).hashCode);
      expect(AsyncComplete(10).hashCode, AsyncComplete(10).hashCode);

      final stackTrace = StackTrace.current;
      expect(
        AsyncError(data: 10, error: 20, stackTrace: stackTrace).hashCode,
        AsyncError(data: 10, error: 20, stackTrace: stackTrace).hashCode,
      );
    });

    test('Objects of different types with same values are not equal', () {
      expect(AsyncInitial(10), isNotEqual(AsyncComplete(10)));
      expect(AsyncWaiting(10), isNotEqual(AsyncComplete(10)));
      expect(AsyncComplete(10), isNotEqual(AsyncInitial(10)));
      expect(AsyncError(data: 10), isNotEqual(AsyncComplete(10)));
    });

    test(
      'Objects of different types with same values have different hashCode',
      () {
        expect(
          AsyncInitial(10).hashCode,
          isNotEqual(AsyncComplete(10).hashCode),
        );
        expect(
          AsyncWaiting(10).hashCode,
          isNotEqual(AsyncComplete(10).hashCode),
        );
        expect(
          AsyncComplete(10).hashCode,
          isNotEqual(AsyncInitial(10).hashCode),
        );
        expect(
          AsyncError(data: 10).hashCode,
          isNotEqual(AsyncComplete(10).hashCode),
        );
      },
    );

    test('Objects of same type with different values are not equal', () {
      expect(AsyncInitial(10), isNotEqual(AsyncInitial(11)));
      expect(AsyncWaiting(10), isNotEqual(AsyncWaiting(11)));
      expect(AsyncComplete(10), isNotEqual(AsyncComplete(11)));
      expect(AsyncError(data: 10), isNotEqual(AsyncError(data: 11)));
      expect(
        AsyncError(data: 10, error: 20),
        isNotEqual(AsyncError(data: 10, error: 21)),
      );
      expect(
        AsyncError(data: 10, error: 20, stackTrace: StackTrace.current),
        isNotEqual(
          AsyncError(data: 10, error: 20, stackTrace: StackTrace.current),
        ),
      );
    });

    test(
      'Objects of same type with different values have different hashCode',
      () {
        expect(
          AsyncInitial(10).hashCode,
          isNotEqual(AsyncInitial(11).hashCode),
        );
        expect(
          AsyncWaiting(10).hashCode,
          isNotEqual(AsyncWaiting(11).hashCode),
        );
        expect(
          AsyncComplete(10).hashCode,
          isNotEqual(AsyncComplete(11).hashCode),
        );
        expect(
          AsyncError(data: 10).hashCode,
          isNotEqual(AsyncError(data: 11).hashCode),
        );
        expect(
          AsyncError(data: 10, error: 20).hashCode,
          isNotEqual(AsyncError(data: 10, error: 21).hashCode),
        );
        expect(
          AsyncError(
            data: 10,
            error: 20,
            stackTrace: StackTrace.current,
          ).hashCode,
          isNotEqual(
            AsyncError(
              data: 10,
              error: 20,
              stackTrace: StackTrace.current,
            ).hashCode,
          ),
        );
      },
    );
  });

  group('toString()', () {
    test('Only AsyncError contains error in string', () {
      final initial = AsyncInitial(10).toString();
      final waiting = AsyncWaiting(10).toString();
      final complete = AsyncComplete(10).toString();
      final error =
          AsyncError(data: 10, error: 20, stackTrace: StackTrace.current)
              .toString();

      expect(initial, startsWith('AsyncInitial<int>#'));
      expect(waiting, startsWith('AsyncWaiting<int>#'));
      expect(complete, startsWith('AsyncComplete<int>#'));
      expect(error, startsWith('AsyncError<int>#'));

      expect(initial, endsWith('(data: 10)'));
      expect(waiting, endsWith('(data: 10)'));
      expect(complete, endsWith('(data: 10)'));
      expect(error, endsWith('(data: 10, error: 20)'));
    });
  });

  group('Getters for type check', () {
    test('isInitial', () {
      const phase = AsyncInitial(10);
      expect(phase.isInitial, isTrue);
      expect(phase.isWaiting, isFalse);
      expect(phase.isComplete, isFalse);
      expect(phase.isError, isFalse);
    });

    test('isWaiting', () {
      const phase = AsyncWaiting(10);
      expect(phase.isInitial, isFalse);
      expect(phase.isWaiting, isTrue);
      expect(phase.isComplete, isFalse);
      expect(phase.isError, isFalse);
    });

    test('isComplete', () {
      const phase = AsyncComplete(10);
      expect(phase.isInitial, isFalse);
      expect(phase.isWaiting, isFalse);
      expect(phase.isComplete, isTrue);
      expect(phase.isError, isFalse);
    });

    test('isError', () {
      const phase = AsyncError(data: 10);
      expect(phase.isInitial, isFalse);
      expect(phase.isWaiting, isFalse);
      expect(phase.isComplete, isFalse);
      expect(phase.isError, isTrue);
    });
  });
}
