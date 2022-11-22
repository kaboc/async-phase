import 'package:async_phase/async_phase.dart';

typedef CalcCallback = void Function(AsyncPhase<double>);

extension DivideBy on double {
  Future<double> divideBy(num value) async {
    await wait();

    final result = this / value;
    if (result == double.infinity) {
      throw UnsupportedError('Cannot be divided by zero.');
    }

    return result;
  }
}

Future<void> wait() async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
}
