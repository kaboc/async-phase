import 'dart:async';
import 'package:async_phase/async_phase.dart';
import 'utils.dart';

Future<void> main() async {
  final calc = Calculation(80.0, onPhaseChanged: _onPhaseChanged);
  await wait();

  for (final divisor in [2, 4, 0]) {
    print('Dividing by $divisor...');
    await wait();

    await calc.divideBy(divisor);
    await wait();
  }
}

void _onPhaseChanged(AsyncPhase<double> phase) {
  final message = phase.when(
    initial: (data) => 'Initial value\n  $data',
    waiting: (data) => '  $data (waiting)',
    complete: (data) => '  $data (complete)',
    error: (data, e, s) => '  $data ($e)',
  );
  print(message);
}

class Calculation {
  Calculation(double initial, {required this.onPhaseChanged}) {
    phase = AsyncInitial(initial);
    onPhaseChanged(phase);
  }

  late AsyncPhase<double> phase;
  late CalcCallback onPhaseChanged;

  Future<void> divideBy(num value) async {
    phase = phase.copyAsWaiting();
    onPhaseChanged(phase);

    phase = await AsyncPhase.from(
      () => phase.data!.divideBy(value),
      fallbackData: -1.0,
    );
    onPhaseChanged(phase);
  }
}
