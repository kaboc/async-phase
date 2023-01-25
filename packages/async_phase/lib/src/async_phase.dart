import 'dart:async';
import 'package:meta/meta.dart';

/// The base class for the classes that represent phases of
/// an asynchronous operation.
@immutable
@sealed
abstract class AsyncPhase<T extends Object?> {
  // ignore: public_member_api_docs
  const AsyncPhase(
    this.data, {
    Object? error,
    StackTrace? stackTrace,
  })  : _error = error,
        _stackTrace = stackTrace;

  /// The result of an asynchronous operation.
  final T? data;

  final Object? _error;
  final StackTrace? _stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is AsyncPhase<T> &&
          // Comparison of runtimeTypes is necessary because otherwise
          // different subtypes with the same values will be considered equal.
          other.runtimeType == runtimeType &&
          other.data == data &&
          other._error == _error &&
          other._stackTrace == _stackTrace;

  @override
  int get hashCode => Object.hashAll([runtimeType, data, _error, _stackTrace]);

  /// Whether the phase is of type [AsyncInitial].
  bool get isInitial => this is AsyncInitial;

  /// Whether the phase is of type [AsyncWaiting].
  bool get isWaiting => this is AsyncWaiting;

  /// Whether the phase is of type [AsyncComplete].
  bool get isComplete => this is AsyncComplete;

  /// Whether the phase is of type [AsyncError].
  ///
  /// This conducts only a type check. If you want the flow analysis
  /// of Dart to work so that the type is promoted to [AsyncError],
  /// check the type with the `is` operator instead.
  ///
  /// ```dart
  /// if (phase is AsyncError) {
  ///   print(phase.error);
  /// }
  /// ```
  bool get isError => this is AsyncError;

  @override
  String toString() {
    final shortHash = hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');
    return this is AsyncError
        ? '$runtimeType#$shortHash(data: $data, error: $_error)'
        : '$runtimeType#$shortHash(data: $data)';
  }

  /// A method that returns a value returned from one of callback
  /// functions corresponding to the current phase of an asynchronous
  /// operation.
  ///
  /// This method calls one of the callbacks, [initial], [waiting],
  /// [complete] or [error], that matches the current phase.
  ///
  /// e.g. The [complete] callback is called if the current phase
  /// is [AsyncComplete].
  ///
  /// All parameters other than [initial] are required. If [initial]
  /// is omitted when the current phase is [AsyncInitial], the [waiting]
  /// callback is called instead.
  ///
  /// If only some of the properties is needed, use [whenOrNull].
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
    return error(data, _error, _stackTrace);
  }

  /// A method that returns a value returned from one of callback
  /// functions corresponding to the current phase of an asynchronous
  /// operation.
  ///
  /// This is identical to [when] except that all properties are
  /// optional. It returns `null` if the callback corresponding to
  /// the current phase has not been provided,
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

  /// A method that runs an asynchronous function and returns
  /// either [AsyncComplete] with the function result as [data]
  /// or [AsyncError] with the error information, depending on
  /// whether or not the function completed successfully.
  ///
  /// If the asynchronous function resulted in an error,
  /// the [fallbackData] value is used as the [data] of [AsyncError].
  ///
  /// The [onError] callback is called on error. This may be
  /// useful for logging.
  static Future<AsyncPhase<T>> from<T extends Object?>(
    FutureOr<T> Function() func, {
    // The type must not be `T` because it can't accept a value of type
    // `T?` although it accepts `null` if the generic type is nullable.
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

  /// A method that creates an [AsyncWaiting] object based on the
  /// phase that this method is called on.
  ///
  /// The phase is converted to a new [AsyncWaiting] object with
  /// the same [data] as that of the original phase, and the object
  /// is returned. This is handy for switching the phase to
  /// `AsyncWaiting` without losing the previous data.
  AsyncWaiting<T> copyAsWaiting() {
    return AsyncWaiting(data);
  }
}

/// A subclass of [AsyncPhase] representing the phase where
/// an asynchronous operation has not been executed yet.
class AsyncInitial<T extends Object?> extends AsyncPhase<T> {
  /// Creates an [AsyncInitial] object representing the phase
  /// where an asynchronous operation has not been executed yet.
  const AsyncInitial([super.data]);
}

/// A subclass of [AsyncPhase] representing the phase where
/// an asynchronous operation is in progress.
class AsyncWaiting<T extends Object?> extends AsyncPhase<T> {
  /// Creates an [AsyncWaiting] object representing the phase
  /// where an asynchronous operation is in progress.
  const AsyncWaiting([super.data]);
}

/// A subclass of [AsyncPhase] representing the phase where
/// an asynchronous operation has completed successfully.
class AsyncComplete<T extends Object?> extends AsyncPhase<T> {
  /// Creates an [AsyncComplete] object representing the phase
  /// where an asynchronous operation has completed successfully.
  const AsyncComplete(T super.data) : _data = data;

  final T _data;

  @override
  T get data => _data;
}

/// A subclass of [AsyncPhase] representing the phase where
/// an asynchronous operation has resulted in an error.
class AsyncError<T extends Object?> extends AsyncPhase<T> {
  /// Creates an [AsyncError] object representing the phase
  /// where an asynchronous operation has resulted in an error.
  const AsyncError({T? data, super.error, super.stackTrace}) : super(data);

  /// The error that occurred in an asynchronous operation.
  Object? get error => _error;

  /// The stack trace of the error that occurred in an
  /// asynchronous operation.
  StackTrace? get stackTrace => _stackTrace;
}
