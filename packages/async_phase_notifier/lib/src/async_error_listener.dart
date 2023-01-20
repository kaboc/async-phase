// ignore_for_file: always_put_required_named_parameters_first

import 'package:flutter/widgets.dart';

import 'async_phase_notifier.dart';

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
  RemoveListener? _removeListener;

  @override
  void initState() {
    super.initState();
    _removeListener = widget.notifier.listen(
      onError: (e, s) => widget.onError?.call(context, e, s),
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
