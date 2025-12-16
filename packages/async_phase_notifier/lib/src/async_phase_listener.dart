import 'package:flutter/widgets.dart';

import 'async_phase_notifier.dart';

class AsyncPhaseListener<T> extends StatefulWidget {
  const AsyncPhaseListener({
    super.key,
    // ignore: always_put_required_named_parameters_first
    required this.notifier,
    // ignore: always_put_required_named_parameters_first
    required this.child,
    this.onWaiting,
    this.onComplete,
    this.onError,
  });

  final AsyncPhaseNotifier<T> notifier;
  final Widget child;
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool isWaiting)? onWaiting;
  final void Function(T data)? onComplete;
  final void Function(Object e, StackTrace s)? onError;

  @override
  State<AsyncPhaseListener<T>> createState() => _AsyncPhaseListenerState<T>();
}

class _AsyncPhaseListenerState<T> extends State<AsyncPhaseListener<T>> {
  RemoveListener? _removeListener;

  @override
  void initState() {
    super.initState();
    _updateListener();
  }

  @override
  void didUpdateWidget(AsyncPhaseListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notifier != oldWidget.notifier) {
      _updateListener();
    }
  }

  @override
  void dispose() {
    _removeListener?.call();
    super.dispose();
  }

  void _updateListener() {
    _removeListener?.call();
    _removeListener = widget.notifier.listenFor(
      onWaiting: widget.onWaiting,
      onComplete: widget.onComplete,
      onError: widget.onError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
