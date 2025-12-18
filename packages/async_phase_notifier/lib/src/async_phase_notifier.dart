import 'dart:async' show StreamController, StreamSink;

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
  bool _isDisposed = false;

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
    _isDisposed = true;
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

  /// Runs the provided asynchronous function and updates the phase.
  ///
  /// The phase is updated to [AsyncWaiting] when the callback starts,
  /// and to [AsyncComplete] or [AsyncError] according to success or
  /// failure when the callback ends.
  ///
  /// {@template AsyncPhaseNotifier.update.callbacks}
  /// The [onWaiting], [onComplete], and [onError] callbacks are called
  /// when the asynchronous operation starts, completes successfully,
  /// or fails, respectively. However, note that errors occurring in
  /// those callbacks are not automatically handled.
  ///
  /// Also note that the `onWaiting` callback is called both when the
  /// phase changes to and from `AsyncWaiting`. A boolean parameter
  /// indicates the direction of this transition.
  /// {@endtemplate}
  Future<AsyncPhase<T>> update(
    Future<T> Function() func, {
    // ignore: avoid_positional_boolean_parameters
    void Function(bool isWaiting)? onWaiting,
    void Function(T data)? onComplete,
    void Function(Object e, StackTrace s)? onError,
  }) async {
    value = value.copyAsWaiting();
    onWaiting?.call(true);

    final phase = await AsyncPhase.from(
      func,
      // Avoids providing data as of this moment as fallback data
      // because it becomes stale if `value.data` is updated externally
      // while the callback is executed.
      fallbackData: null,
    );

    onWaiting?.call(false);

    if (!_isDisposed) {
      if (phase case AsyncError(:final error, :final stackTrace)) {
        value = phase.copyWith(data);
        onError?.call(error, stackTrace);
      } else {
        value = phase;
        onComplete?.call(data);
      }
    }
    return value;
  }

  /// Runs the provided asynchronous function and only updates the phase.
  ///
  /// The phase is updated to [AsyncWaiting] when the function starts,
  /// and to [AsyncComplete] or [AsyncError] according to success or
  /// failure when the function ends.
  ///
  /// This is the same as [update] except that this method does not update
  /// `value.data`.
  ///
  /// This method is useful when it is necessary to update the phase during
  /// execution but the function result should not affect the data.
  ///
  /// e.g. Indicating the waiting status on the UI or notifying the phase
  /// change to other parts of the code, with the existing data being kept
  /// unchanged.
  ///
  /// {@macro AsyncPhaseNotifier.update.callbacks}
  @Deprecated(
    'Use updateType instead. '
    'This feature was deprecated after v0.7.1.',
  )
  // coverage:ignore-line
  Future<AsyncPhase<T>> updateOnlyPhase(
    Future<void> Function() func, {
    // ignore: avoid_positional_boolean_parameters
    void Function(bool isWaiting)? onWaiting,
    void Function(T data)? onComplete,
    void Function(Object e, StackTrace s)? onError,
  }) async {
    return update(
      () async {
        await func();
        return data;
      },
      onWaiting: onWaiting,
      onComplete: onComplete,
      onError: onError,
    );
  }

  /// Updates the phase type while preserving the current [data].
  ///
  /// Transitions to [AsyncWaiting] at the start of the function,
  /// then transitions to the appropriate phase when the function finishes.
  ///
  /// ## Use cases
  ///
  /// * Running an asynchronous operation where the result data is not needed,
  ///   but tracking the phase (e.g., showing/hiding a loading indicator) is
  ///   necessary.
  /// * Using `AsyncPhaseNotifier` to implement a command-like approach,
  ///   as discussed in the official Flutter [architecture guide](https://docs.flutter.dev/app-architecture/design-patterns/command).
  ///     * Steps:
  ///         1. Create `AsyncPhaseNotifier` instances within a view model to
  ///            represent specific actions.
  ///         2. Use `updateType()` within a view model method to execute the
  ///            operation associated with that action.
  ///         3. Listen to the `AsyncPhaseNotifier` [value] in the UI to
  ///            reflect the current phase.
  ///     * While this doesn't follow the formal Command pattern, it serves
  ///       the same purpose of decoupling UI and business logic. This method
  ///       simplifies the implementation of this approach.
  ///
  /// ## Details
  ///
  /// * **Flexible return type**: The callback `func` can return any type
  ///   (`Object?`), not just [T].
  /// * **Phase-aware result**: If the function returns an [AsyncPhase],
  ///   the notifier's [value] is updated to match that specific phase.
  ///   * Example: If the notifier is `AsyncPhaseNotifier<int>` and the
  ///     function returns `AsyncError<String>`, the [value] becomes
  ///     `AsyncError<int>`, preserving the existing data but adopting
  ///     the error state.
  ///   * This allows the final phase to be [AsyncInitial] or [AsyncWaiting]
  ///     if returned by the function, giving you full control over the
  ///     resulting phase.
  /// * **Simplified callbacks**: The `onComplete` callback takes no
  ///   parameters since the [data] remains unchanged.
  ///
  /// ```dart
  /// final notifier = AsyncPhaseNotifier(123);
  ///
  /// // Returns a normal value (non-AsyncPhase)
  /// var phase = await notifier.updateType(() async => 'abc');
  /// expect(phase.data, 123);
  /// expect(phase, isA<AsyncComplete<int>>());
  ///
  /// // Throws an error
  /// phase = await notifier.updateType(() => throw Exception());
  /// expect(phase.data, 123);
  /// expect(phase, isA<AsyncError<int>>());
  ///
  /// // Returns an AsyncPhase (AsyncComplete)
  /// phase = await notifier.updateType(() async => AsyncComplete('abc'));
  /// expect(phase.data, 123);
  /// expect(phase, isA<AsyncComplete<int>>());
  ///
  /// // Returns an AsyncPhase (AsyncError)
  /// phase = await notifier.updateType(() async => AsyncError(error: ..));
  /// expect(phase.data, 123);
  /// expect(phase, isA<AsyncError<int>>());
  /// ```
  ///
  /// ## Callbacks upon phase changes
  ///
  /// {@macro AsyncPhaseNotifier.update.callbacks}
  ///
  /// If the function returns an [AsyncPhase], the subsequent callbacks are
  /// triggered based on that resulting phase:
  ///
  /// * **AsyncWaiting**:
  ///   * The `onWaiting` callback is **not** called at the conclusion of this
  ///     method because the phase remains [AsyncWaiting], which was already
  ///     set at the start of the operation.
  /// * **AsyncComplete**:
  ///   * The `onComplete` callback is called.
  /// * **AsyncError**:
  ///   * The `onError` callback is called. This occurs whether the function
  ///     explicitly returned an [AsyncError] or threw an exception.
  Future<AsyncPhase<T>> updateType(
    Future<Object?> Function() func, {
    // ignore: avoid_positional_boolean_parameters
    void Function(bool isWaiting)? onWaiting,
    void Function()? onComplete,
    void Function(Object e, StackTrace s)? onError,
  }) async {
    value = value.copyAsWaiting();
    onWaiting?.call(true);

    AsyncPhase<Object?> phase;
    try {
      phase = func is Future<AsyncPhase> Function()
          ? await func()
          : await AsyncPhase.from(func);
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e, s) {
      phase = AsyncError(error: e, stackTrace: s);
    }

    if (!_isDisposed) {
      value = phase.convert((_) => data);

      if (!phase.isWaiting) {
        onWaiting?.call(false);

        if (phase case AsyncError(:final error, :final stackTrace)) {
          onError?.call(error, stackTrace);
        } else {
          onComplete?.call();
        }
      }
    }
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
    void Function(bool isWaiting)? onWaiting,
    void Function(T data)? onComplete,
    void Function(Object e, StackTrace s)? onError,
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
