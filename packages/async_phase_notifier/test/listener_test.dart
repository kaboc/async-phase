// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:async_phase_notifier/async_phase_notifier.dart';

class TestApp<T extends Object?> extends StatefulWidget {
  const TestApp({
    required this.notifier,
    required this.onWaiting,
    required this.onComplete,
    required this.onError,
    this.onBuild,
    super.key,
  });

  final AsyncPhaseNotifier<T> notifier;
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool)? onWaiting;
  final void Function(T)? onComplete;
  final void Function(Object?, StackTrace?) onError;
  final VoidCallback? onBuild;

  @override
  State<TestApp<T>> createState() => _TestAppState<T>();
}

class _TestAppState<T> extends State<TestApp<T>> {
  @override
  Widget build(BuildContext context) {
    widget.onBuild?.call();

    return MaterialApp(
      home: Scaffold(
        body: AsyncPhaseListener(
          notifier: widget.notifier,
          onWaiting: widget.onWaiting,
          onComplete: widget.onComplete,
          onError: widget.onError,
          child: ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Rebuild'),
          ),
        ),
      ),
    );
  }
}

void main() {
  Object? data;
  bool? waiting;
  Object? error;
  StackTrace? stackTrace;

  var errorCount = 0;
  var buildCount = 0;

  tearDown(() {
    data = null;
    waiting = false;
    error = null;
    stackTrace = null;
    errorCount = 0;
    buildCount = 0;
  });

  Widget createWidget<T extends Object?>(AsyncPhaseNotifier<T> notifier) {
    return TestApp(
      notifier: notifier,
      onWaiting: (w) => waiting = w,
      onComplete: (d) => data = d,
      onError: (e, s) {
        error = e;
        stackTrace = s;
        errorCount++;
      },
      onBuild: () => buildCount++,
    );
  }

  group('AsyncErrorListener', () {
    testWidgets(
      'Appropriate callback is called when phase changes',
      (tester) async {
        final notifier = AsyncPhaseNotifier<int?>(10);
        addTearDown(notifier.dispose);

        await tester.pumpWidget(createWidget(notifier));
        await tester.pumpAndSettle();

        notifier.value = AsyncWaiting(notifier.value.data);
        await tester.pump();
        expect(waiting, isTrue);
        expect(data, isNull);
        expect(error, isNull);

        notifier.value = AsyncComplete(notifier.value.data);
        await tester.pump();
        expect(waiting, isFalse);
        expect(data, 10);
        expect(error, isNull);

        final e = Exception();
        final s = StackTrace.current;
        notifier.value = AsyncError(data: 20, error: e, stackTrace: s);
        await tester.pump();
        expect(waiting, isFalse);
        expect(data, 10);
        expect(error, e);
        expect(stackTrace, s);
      },
    );

    testWidgets(
      'Listener is removed from old notifier and added to new one '
      'when notifier is switched',
      (tester) async {
        final notifier1 = AsyncPhaseNotifier(10);
        final notifier2 = AsyncPhaseNotifier(20);
        addTearDown(notifier1.dispose);
        addTearDown(notifier2.dispose);

        var notifier = notifier1;
        int? value;
        void Function(void Function())? setStateFunc;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              setStateFunc = setState;
              return TestApp(
                notifier: notifier,
                onWaiting: (waiting) {},
                onComplete: (data) => value = data,
                onError: (e, s) {},
                onBuild: () => buildCount++,
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        notifier1.value = const AsyncComplete(11);
        notifier2.value = const AsyncComplete(21);
        await tester.pump();
        expect(notifier1.isListening, isTrue);
        expect(notifier2.isListening, isFalse);
        expect(buildCount, 1);
        expect(value, 11);

        setStateFunc!(() => notifier = notifier2);
        await tester.pump();

        notifier2.value = const AsyncComplete(22);
        notifier1.value = const AsyncComplete(12);
        await tester.pump();
        expect(notifier1.isListening, isFalse);
        expect(notifier2.isListening, isTrue);
        expect(buildCount, 2);
        expect(value, 22);
      },
    );

    testWidgets(
      'Callback is not called again when widget is rebuilt',
      (tester) async {
        final notifier = AsyncPhaseNotifier(null);
        addTearDown(notifier.dispose);

        await tester.pumpWidget(createWidget(notifier));
        await tester.pumpAndSettle();

        // It does not matter here whether to test using only one or
        // all callbacks, so only `onError` is used for simplicity.
        notifier.value = AsyncError(error: Exception());
        await tester.pump();
        expect(errorCount, 1);
        expect(buildCount, greaterThanOrEqualTo(1));

        final buttonFinder = find.byType(ElevatedButton).first;
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();
        expect(errorCount, 1);
        expect(buildCount, greaterThanOrEqualTo(2));

        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();
        expect(errorCount, 1);
        expect(buildCount, greaterThanOrEqualTo(3));
      },
    );

    testWidgets('Listener is removed if widget is discarded', (tester) async {
      final notifier = AsyncPhaseNotifier(null);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(createWidget(notifier));
      await tester.pumpAndSettle();
      expect(notifier.isListening, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(notifier.isListening, isFalse);
    });
  });
}
