import 'package:flutter/foundation.dart';

import 'async_phase.dart';

class AsyncPhaseNotifier<T> extends ValueNotifier<AsyncPhase<T>> {
  AsyncPhaseNotifier(T value) : super(AsyncComplete(value: value));

  @override
  @protected
  set value(AsyncPhase<T> newValue) {
    if (newValue.value != null || newValue is AsyncComplete) {
      super.value = newValue;
    }
    if (newValue.isWaiting) {
      super.value = AsyncWaiting(value: value.value);
    }
    if (newValue.isError) {
      super.value = AsyncError(
        value: value.value,
        error: newValue.error,
        stackTrace: newValue.stackTrace,
      );
    }
  }

  void runAsync(Future<T> Function(T?) func) {
    value = AsyncWaiting(value: value.value);

    AsyncPhase.from<T>(() => func(value.value))
        .then((result) => value = result);
  }
}
