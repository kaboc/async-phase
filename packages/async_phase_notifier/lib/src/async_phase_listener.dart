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
  final void Function(bool)? onWaiting;
  final void Function(T)? onComplete;
  final void Function(Object, StackTrace)? onError;

  @override
  State<AsyncPhaseListener<T>> createState() => _AsyncPhaseListenerState<T>();
}

class _AsyncPhaseListenerState<T> extends State<AsyncPhaseListener<T>> {
  RemoveListener? _removeListener;

  @override
  void initState() {
    super.initState();
    _removeListener = widget.notifier.listenFor(
      onWaiting: widget.onWaiting,
      onComplete: widget.onComplete,
      onError: widget.onError,
    );
  }

  @override
  void dispose() {
    _removeListener?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
