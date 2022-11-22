import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:async_phase/async_phase.dart';

typedef ErrorListener = void Function(Object?, StackTrace?);
typedef RemoveErrorListener = void Function();

class AsyncPhaseNotifier<T> extends ValueNotifier<AsyncPhase<T>> {
  AsyncPhaseNotifier([T? data]) : super(AsyncInitial(data));

  StreamController<AsyncError<T>>? _errorStreamController;
  AsyncPhase<T>? _prevPhase;

  @override
  void dispose() {
    _errorStreamController?.close();
    super.dispose();
  }

  @override
  @protected
  set value(AsyncPhase<T> newValue) {
    if (newValue.data != null || newValue is AsyncComplete) {
      super.value = newValue;
    }
    if (newValue.isWaiting) {
      super.value =
          newValue.data == value.data ? newValue : value.copyAsWaiting();
    }
    if (newValue.isError) {
      super.value = newValue.data == value.data
          ? newValue
          : AsyncError(
              data: value.data,
              error: newValue.error,
              stackTrace: newValue.stackTrace,
            );
    }

    _notifyErrorListeners();
  }

  Future<AsyncPhase<T>> runAsync(FutureOr<T> Function(T?) func) async {
    value = value.copyAsWaiting();

    final phase = await AsyncPhase.from<T>(
      () => func(value.data),
      fallbackData: value.data,
    );
    value = phase;

    return phase;
  }

  RemoveErrorListener listenError(ErrorListener listener) {
    // ignore: prefer_asserts_with_message
    assert(ChangeNotifier.debugAssertNotDisposed(this));

    _errorStreamController ??= StreamController<AsyncError<T>>.broadcast();
    final subscription = _errorStreamController?.stream.listen((event) {
      listener(event.error, event.stackTrace);
    });

    return () => subscription?.cancel();
  }

  void _notifyErrorListeners() {
    final phase = value;
    if (phase != _prevPhase && phase is AsyncError<T>) {
      _errorStreamController?.sink.add(phase);
    }
    _prevPhase = phase;
  }
}
