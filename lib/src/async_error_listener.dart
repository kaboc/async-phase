// ignore_for_file: always_put_required_named_parameters_first

import 'package:flutter/widgets.dart';

import 'async_phase_notifier.dart';

// TODO: Describe in document that this should not be used in many places because this adds a listener.
class AsyncErrorListener<T> extends StatefulWidget {
  const AsyncErrorListener({
    super.key,
    required this.notifier,
    required this.onError,
    required this.child,
  });

  final AsyncPhaseNotifier<T> notifier;
  final void Function(BuildContext, Object?, StackTrace?)? onError;
  final Widget child;

  @override
  State<AsyncErrorListener<T>> createState() => _AsyncErrorListenerState<T>();
}

class _AsyncErrorListenerState<T> extends State<AsyncErrorListener<T>> {
  RemoveErrorListener? _removeErrorListener;

  @override
  void initState() {
    super.initState();
    _removeErrorListener = widget.notifier.listenError((e, s) {
      widget.onError?.call(context, e, s);
    });
  }

  @override
  void dispose() {
    _removeErrorListener?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
