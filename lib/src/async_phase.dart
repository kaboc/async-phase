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
          // Comparison of runtimeTypes is necessary because
          // otherwise different subtypes with the same properties
          // will be considered equal.
          other.runtimeType == runtimeType &&
          other.data == data &&
          other.error == error &&
          other.stackTrace == stackTrace;

  @override
  int get hashCode => Object.hashAll([data, error, stackTrace]);

  bool get isInitial => this is AsyncInitial;

  bool get isWaiting => this is AsyncWaiting;

  bool get isComplete => this is AsyncComplete;

  bool get isError => this is AsyncError;

  @override
  String toString() {
    final shortHash = hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
    return '$runtimeType#$shortHash(value: $data, error: $error)';
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

  static Future<AsyncPhase<T>> from<T>(
    Future<T> Function() func, {
    T? fallbackData,
  }) async {
    try {
      final data = await func();
      return AsyncComplete(data: data);
    } on Exception catch (e, s) {
      return AsyncError<T>(data: fallbackData, error: e, stackTrace: s);
    }
  }
}

class AsyncInitial<T> extends AsyncPhase<T> {
  const AsyncInitial({T? data}) : super(data);
}

class AsyncWaiting<T> extends AsyncPhase<T> {
  const AsyncWaiting({T? data}) : super(data);
}

class AsyncComplete<T> extends AsyncPhase<T> {
  const AsyncComplete({required T data}) : super(data);
}

class AsyncError<T> extends AsyncPhase<T> {
  const AsyncError({Object? error, T? data, StackTrace? stackTrace})
      : super(data, error: error, stackTrace: stackTrace);
}
