import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

@immutable
@sealed
abstract class AsyncPhase<T> {
  const AsyncPhase(
    this.value, {
    this.error,
    this.stackTrace,
  });

  final T? value;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      other is AsyncPhase<T> &&
          // Comparison of runtimeTypes is necessary because otherwise
          // AsyncWaiting and AsyncComplete will be considered identical
          // as all properties are equal.
          other.runtimeType == runtimeType &&
          other.value == value &&
          other.error == error &&
          other.stackTrace == stackTrace;

  @override
  int get hashCode => Object.hashAll([value, error, stackTrace]);

  bool get isWaiting => this is AsyncWaiting;

  bool get isComplete => this is AsyncComplete;

  bool get isError => this is AsyncError;

  @override
  String toString() {
    return '${describeIdentity(this)}(value: $value, error: $error)';
  }

  U when<U>({
    required U Function(T?) waiting,
    required U Function(T) complete,
    required U Function(T?, Object?, StackTrace?) error,
  }) {
    if (isWaiting) {
      return waiting(value);
    }
    if (isComplete) {
      return complete(value as T);
    }
    return error(value, this.error, stackTrace);
  }

  static Future<AsyncPhase<T>> from<T>(
    Future<T> Function() func, {
    T? fallbackValue,
  }) async {
    return func().then<AsyncPhase<T>>((v) {
      return AsyncComplete(value: v);
    }).onError((e, s) {
      return AsyncError<T>(value: fallbackValue, error: e, stackTrace: s);
    });
  }
}

class AsyncWaiting<T> extends AsyncPhase<T> {
  const AsyncWaiting({T? value}) : super(value);
}

class AsyncComplete<T> extends AsyncPhase<T> {
  const AsyncComplete({required T value}) : super(value);
}

class AsyncError<T> extends AsyncPhase<T> {
  const AsyncError({
    required Object? error,
    T? value,
    StackTrace? stackTrace,
  }) : super(value, error: error, stackTrace: stackTrace);
}
