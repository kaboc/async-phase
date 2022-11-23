import 'dart:async';
import 'package:meta/meta.dart';

@immutable
@sealed
abstract class AsyncPhase<T> {
  const AsyncPhase(
    this.data, {
    this.error,
    this.stackTrace,
  });

  final T? data;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is AsyncPhase<T> &&
          // Comparison of runtimeTypes is necessary because otherwise
          // different subtypes with the same values will be considered equal.
          other.runtimeType == runtimeType &&
          other.data == data &&
          other.error == error &&
          other.stackTrace == stackTrace;

  @override
  int get hashCode => Object.hashAll([runtimeType, data, error, stackTrace]);

  bool get isInitial => this is AsyncInitial;

  bool get isWaiting => this is AsyncWaiting;

  bool get isComplete => this is AsyncComplete;

  bool get isError => this is AsyncError;

  @override
  String toString() {
    final shortHash = hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
    return '$runtimeType#$shortHash(data: $data, error: $error)';
  }

  U when<U>({
    required U Function(T?) waiting,
    required U Function(T) complete,
    required U Function(T?, Object?, StackTrace?) error,
    U Function(T?)? initial,
  }) {
    if (isInitial) {
      return initial == null ? waiting(data) : initial(data);
    }
    if (isWaiting) {
      return waiting(data);
    }
    if (isComplete) {
      return complete(data as T);
    }
    return error(data, this.error, stackTrace);
  }

  U? whenOrNull<U>({
    U Function(T?)? initial,
    U Function(T?)? waiting,
    U Function(T)? complete,
    U Function(T?, Object?, StackTrace?)? error,
  }) {
    return when(
      initial: initial,
      waiting: (data) => waiting?.call(data),
      complete: (data) => complete?.call(data),
      error: (data, e, s) => error?.call(data, e, s),
    );
  }

  static Future<AsyncPhase<T>> from<T>(
    FutureOr<T> Function() func, {
    required T? fallbackData,
    void Function(Object, StackTrace)? onError,
  }) async {
    try {
      final data = await func();
      return AsyncComplete(data);
      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
      onError?.call(e, s);
      return AsyncError<T>(data: fallbackData, error: e, stackTrace: s);
    }
  }

  AsyncWaiting<T> copyAsWaiting() {
    return AsyncWaiting(data);
  }
}

class AsyncInitial<T> extends AsyncPhase<T> {
  const AsyncInitial([super.data]);
}

class AsyncWaiting<T> extends AsyncPhase<T> {
  const AsyncWaiting([super.data]);
}

class AsyncComplete<T> extends AsyncPhase<T> {
  const AsyncComplete(super.data);
}

class AsyncError<T> extends AsyncPhase<T> {
  const AsyncError({T? data, super.error, super.stackTrace}) : super(data);
}
