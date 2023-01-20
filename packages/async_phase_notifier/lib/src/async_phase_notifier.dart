import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import 'package:async_phase/async_phase.dart';

typedef RemoveListener = void Function();

enum _EventType { waitingStart, waitingEnd, complete, error }

class _Event<T extends Object?> {
  const _Event(this.type, this.phase);

  final _EventType type;
  final AsyncPhase<T> phase;
}

class AsyncPhaseNotifier<T extends Object?>
    extends ValueNotifier<AsyncPhase<T>> {
  AsyncPhaseNotifier([T? data]) : super(AsyncInitial(data));

  StreamController<_Event<T>>? _streamController;
  AsyncPhase<T>? _prevPhase;

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
      _notifyListeners(phase: phase, prevPhase: _prevPhase);
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
        case _EventType.waitingStart:
          onWaiting?.call(true);
          break;
        case _EventType.waitingEnd:
          onWaiting?.call(false);
          break;
        case _EventType.complete:
          final phase = event.phase as AsyncComplete<T>;
          onComplete?.call(phase.data);
          break;
        case _EventType.error:
          final phase = event.phase as AsyncError<T>;
          onError?.call(phase.error, phase.stackTrace);
          break;
      }
    });

    return () => subscription?.cancel();
  }

  void _notifyListeners({
    required AsyncPhase<T> phase,
    required AsyncPhase<T>? prevPhase,
  }) {
    if (phase is AsyncWaiting<T>) {
      _streamController?.sink.add(_Event(_EventType.waitingStart, phase));
    } else {
      if (prevPhase is AsyncWaiting<T>) {
        _streamController?.sink.add(_Event(_EventType.waitingEnd, phase));
      }

      if (phase is AsyncComplete<T>) {
        _streamController?.sink.add(_Event(_EventType.complete, phase));
      } else if (phase is AsyncError<T>) {
        _streamController?.sink.add(_Event(_EventType.error, phase));
      }
    }
  }
}
