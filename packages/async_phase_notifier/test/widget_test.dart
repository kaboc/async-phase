import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:async_phase_notifier/async_phase_notifier.dart';

class MyWidget<T extends Object?> extends StatefulWidget {
  const MyWidget({
    required this.notifier,
    required this.onError,
    this.onBuild,
    super.key,
  });

  final AsyncPhaseNotifier<T> notifier;
  final void Function(Object?, StackTrace?) onError;
  final VoidCallback? onBuild;

  @override
  State<MyWidget<T>> createState() => _MyWidgetState<T>();
}

class _MyWidgetState<T> extends State<MyWidget<T>> {
  @override
  Widget build(BuildContext context) {
    widget.onBuild?.call();

    return MaterialApp(
      home: Scaffold(
        body: AsyncErrorListener(
          notifier: widget.notifier,
          onError: (context, e, s) => widget.onError(e, s),
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
  Object? error;
  StackTrace? stackTrace;

  var errorCount = 0;
  var buildCount = 0;

  tearDown(() {
    error = null;
    stackTrace = null;
    errorCount = 0;
    buildCount = 0;
  });

  Widget createWidget<T extends Object?>(AsyncPhaseNotifier<T> notifier) {
    return MyWidget(
      notifier: notifier,
      onError: (e, s) {
        error = e;
        stackTrace = s;
        errorCount++;
      },
      onBuild: () => buildCount++,
    );
  }

  group('AsyncErrorListener', () {
    testWidgets('onError is called on error', (tester) async {
      final notifier = AsyncPhaseNotifier<int>();
      await tester.pumpWidget(createWidget(notifier));
      await tester.pumpAndSettle();

      // ignore: invalid_use_of_protected_member
      notifier.value = const AsyncError(
        error: 'error',
        stackTrace: StackTrace.empty,
      );
      await tester.pump();

      expect(error, equals('error'));
      expect(stackTrace, equals(StackTrace.empty));
    });

    testWidgets(
      'onError is called only once per error regardless of number of builds',
      (tester) async {
        final notifier = AsyncPhaseNotifier<int>();
        await tester.pumpWidget(createWidget(notifier));
        await tester.pumpAndSettle();

        // ignore: invalid_use_of_protected_member
        notifier.value = AsyncError(error: Exception());
        await tester.pump();

        expect(errorCount, equals(1));
        expect(buildCount, greaterThanOrEqualTo(1));

        final buttonFinder = find.byType(ElevatedButton).first;
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        expect(errorCount, equals(1));
        expect(buildCount, greaterThanOrEqualTo(2));

        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        expect(errorCount, equals(1));
        expect(buildCount, greaterThanOrEqualTo(3));
      },
    );

    testWidgets('Listener is removed if widget is discarded', (tester) async {
      final notifier = AsyncPhaseNotifier<int>();
      await tester.pumpWidget(createWidget(notifier));
      await tester.pumpAndSettle();

      expect(notifier.hasErrorListener, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      expect(notifier.hasErrorListener, isFalse);
    });
  });
}
