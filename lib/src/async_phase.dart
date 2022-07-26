import 'dart:async';

import 'package:flutter/foundation.dart';
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
          // AsyncWaiting and AsyncComplete will be considered identical
          // as all properties are equal.
          other.runtimeType == runtimeType &&
          other.data == data &&
          other.error == error &&
          other.stackTrace == stackTrace;

  @override
  int get hashCode => Object.hashAll([data, error, stackTrace]);

  bool get isWaiting => this is AsyncWaiting;

  bool get isComplete => this is AsyncComplete;

  bool get isError => this is AsyncError;

  @override
  String toString() {
    return '${describeIdentity(this)}(value: $data, error: $error)';
  }

  U when<U>({
    required U Function(T?) waiting,
    required U Function(T) complete,
    required U Function(T?, Object?, StackTrace?) error,
  }) {
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
    return func().then<AsyncPhase<T>>((v) {
      return AsyncComplete(data: v);
    }).onError((e, s) {
      return AsyncError<T>(data: fallbackData, error: e, stackTrace: s);
    });
  }
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
