import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import 'package:async_phase/async_phase.dart';

enum _EventType { start, end, success, error }

typedef _Event<T> = ({_EventType type, AsyncPhase<T> phase});
typedef RemoveListener = void Function();

class AsyncPhaseNotifier<T extends Object?>
    extends ValueNotifier<AsyncPhase<T>> {
  AsyncPhaseNotifier(T data) : super(AsyncInitial(data));

  StreamController<_Event<T>>? _eventStreamController;
  AsyncPhase<T> _prevPhase = const AsyncInitial();

  StreamSink<_Event<T>>? get _sink => _eventStreamController?.sink;

  /// A getter for the `data` of the [AsyncPhase] value that this
  /// [AsyncPhaseNotifier] holds.
  ///
  /// This getter returns a non-nullable value when the generic type of
  /// the notifier is non-nullable, while `value.data` is always nullable.
  T get data => value.data as T;

  @override
  void dispose() {
    _eventStreamController?.close();
    super.dispose();
  }

  @override
  @protected
  set value(AsyncPhase<T> newValue) {
    super.value = newValue;

    if (newValue != _prevPhase) {
      _notifyListeners(prevPhase: _prevPhase, newPhase: newValue);
    }
    _prevPhase = newValue;
  }

  @Deprecated(
    'Use update instead. '
    'This feature was deprecated after v0.4.0.',
  )
  Future<AsyncPhase<T>> runAsync(Future<T> Function() func) async {
    return update(func);
  }

  /// Runs the provided asynchronous function and updates the phase.
  ///
  /// {@template AsyncPhaseNotifier.update}
  /// The phase is updated to [AsyncWaiting] when the callback starts,
  /// and to [AsyncComplete] or [AsyncError] according to success or
  /// failure when the callback ends.
  /// {@endtemplate}
  Future<AsyncPhase<T>> update(Future<T> Function() func) async {
    value = value.copyAsWaiting();

    final phase = await AsyncPhase.from(
      func,
      // Avoids using data as of this moment as fallback because
      // it becomes stale if `value.data` is updated externally
      // while the callback is executed.
      fallbackData: null,
    );

    if (phase is AsyncError) {
      value = phase.copyWith(data);
    } else {
      value = phase;
    }
    return value;
  }

  /// Runs the provided asynchronous function and only updates the phase.
  ///
  /// {@macro AsyncPhaseNotifier.update}
  ///
  /// This is the same as [update] except that this method does not update
  /// `value.data`.
  ///
  /// This method is useful when it is necessary to update the phase during
  /// execution but the callback result should not affect the data.
  ///
  /// e.g. Indicating the waiting status on the UI or notifying the phase
  /// change to other parts of the code, with the existing data being kept
  /// unchanged.
  Future<AsyncPhase<T>> updateOnlyPhase(Future<void> Function() func) async {
    final phase = await update(() async {
      await func();
      return data;
    });
    value = phase;
    return value;
  }

  @useResult
  RemoveListener listen(void Function(AsyncPhase<T>) listener) {
    // ignore: prefer_asserts_with_message
    assert(ChangeNotifier.debugAssertNotDisposed(this));

    _eventStreamController ??= StreamController<_Event<T>>.broadcast();
    final subscription = _eventStreamController?.stream.listen((event) {
      if (event.type != _EventType.end) {
        listener(event.phase);
      }
    });

    return () => subscription?.cancel();
  }

  @useResult
  RemoveListener listenFor({
    // ignore: avoid_positional_boolean_parameters
    void Function(bool)? onWaiting,
    void Function(T)? onComplete,
    void Function(Object, StackTrace)? onError,
  }) {
    // ignore: prefer_asserts_with_message
    assert(ChangeNotifier.debugAssertNotDisposed(this));

    if (onComplete == null && onWaiting == null && onError == null) {
      return () {};
    }

    _eventStreamController ??= StreamController<_Event<T>>.broadcast();
    final subscription = _eventStreamController?.stream.listen((event) {
      switch (event.type) {
        case _EventType.start:
          onWaiting?.call(true);
        case _EventType.end:
          onWaiting?.call(false);
        case _EventType.success:
          final phase = event.phase as AsyncComplete<T>;
          onComplete?.call(phase.data);
        case _EventType.error:
          final phase = event.phase as AsyncError<T>;
          onError?.call(phase.error, phase.stackTrace);
      }
    });

    return () => subscription?.cancel();
  }

  void _notifyListeners({
    required AsyncPhase<T> prevPhase,
    required AsyncPhase<T> newPhase,
  }) {
    if (prevPhase.isWaiting && !newPhase.isWaiting) {
      _sink?.add((type: _EventType.end, phase: newPhase));
    }

    switch (newPhase) {
      case AsyncInitial():
        break;
      case AsyncWaiting():
        _sink?.add((type: _EventType.start, phase: newPhase));
      case AsyncComplete():
        _sink?.add((type: _EventType.success, phase: newPhase));
      case AsyncError():
        _sink?.add((type: _EventType.error, phase: newPhase));
    }
  }
}

@visibleForTesting
extension AsyncPhaseTest on AsyncPhaseNotifier {
  @visibleForTesting
  bool get isListening => _eventStreamController?.hasListener ?? false;

  @visibleForTesting
  bool get isClosed => _eventStreamController?.isClosed ?? false;
}
