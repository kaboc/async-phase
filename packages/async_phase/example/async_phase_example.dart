import 'dart:async';
import 'package:async_phase/async_phase.dart';
import 'utils.dart';

Future<void> main() async {
  final calc = Calculation(80.0, onCalc);
  await wait();

  for (final divisor in [2, 4, 0]) {
    print('Dividing by $divisor...');
    await wait();

    await calc.divideBy(divisor);
    await wait();
  }
}

void onCalc(AsyncPhase<double> phase) {
  final message = phase.when(
    initial: (data) => 'Initial value\n  $data',
    waiting: (data) => '  $data (waiting)',
    complete: (data) => '  $data (complete)',
    error: (data, e, s) => '  $data ($e)',
  );
  print(message);
}

class Calculation {
  Calculation(double initial, CalcCallback onCalc) {
    phase = AsyncInitial(initial);
    onCalc(phase);
  }

  late AsyncPhase<double> phase;

  Future<void> divideBy(num value) async {
    phase = phase.copyAsWaiting();
    onCalc(phase);

    phase = await AsyncPhase.from(
      () => phase.data!.divideBy(value),
      fallbackData: -1.0,
    );
    onCalc(phase);
  }
}
