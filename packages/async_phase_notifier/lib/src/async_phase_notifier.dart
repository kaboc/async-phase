import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import 'package:async_phase/async_phase.dart';

enum _EventType { start, end, success, error }

typedef _Event<T> = ({_EventType type, AsyncPhase<T> phase});
typedef RemoveListener = void Function();

class AsyncPhaseNotifier<T extends Object?>
    extends ValueNotifier<AsyncPhase<T>> {
  AsyncPhaseNotifier([T? data]) : super(AsyncInitial(data));

  StreamController<_Event<T>>? _streamController;
  AsyncPhase<T> _prevPhase = const AsyncInitial();

  StreamSink<_Event<T>>? get _sink => _streamController?.sink;

  @visibleForTesting
  bool get isListening => _streamController?.hasListener ?? false;

  @override
  void dispose() {
    _streamController?.close();
    super.dispose();
  }

  @override
  @protected
  set value(AsyncPhase<T> newValue) {
    super.value = newValue;

    final phase = value;
    if (phase != _prevPhase) {
      _notifyListeners(prevPhase: _prevPhase, newPhase: phase);
    }
    _prevPhase = phase;
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

  @useResult
  RemoveListener listen({
    // ignore: avoid_positional_boolean_parameters
    void Function(bool)? onWaiting,
    void Function(T)? onComplete,
    void Function(Object?, StackTrace?)? onError,
  }) {
    // ignore: prefer_asserts_with_message
    assert(ChangeNotifier.debugAssertNotDisposed(this));

    if (onComplete == null && onWaiting == null && onError == null) {
      return () {};
    }

    _streamController ??= StreamController<_Event<T>>.broadcast();
    final subscription = _streamController?.stream.listen((event) {
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
