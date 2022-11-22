import 'package:flutter/material.dart';

import 'package:async_phase_notifier/async_phase_notifier.dart';
import 'package:grab/grab.dart';

import 'package:async_phase_notifier_example/api.dart';
import 'package:async_phase_notifier_example/footer.dart';

final _factNotifier = FactNotifier();
final _switchNotifier = ValueNotifier(true);

class FactNotifier extends AsyncPhaseNotifier<Fact> {
  FactNotifier() {
    fetch();
  }

  final _api = RandomFactApi();

  void fetch() {
    final enabled = _switchNotifier.value;
    runAsync((_) => _api.fetch(enabled: enabled));
  }
}

//======================================================================

void main() => runApp(const App());

class App extends StatefulWidget {
  const App();

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void dispose() {
    _factNotifier.dispose();
    _switchNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AsyncPhaseNotifier Demo',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Useless Facts'),
          centerTitle: true,
        ),
        body: const Center(
          child: _Body(),
        ),
        floatingActionButton: const _Fab(),
        bottomNavigationBar: const Footer(),
      ),
    );
  }
}

class _Body extends StatelessWidget with Grab {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final factPhase = context.grab<AsyncPhase<Fact>>(_factNotifier);
    final enabled = context.grab<bool>(_switchNotifier);

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: factPhase.when(
                waiting: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (v, e, s) => Text(
                  '$e',
                  style: const TextStyle(color: Colors.red),
                ),
                complete: (fact) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fact.text,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    Text(fact.sourceUrl),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          Switch(
            value: enabled,
            onChanged: (v) => _switchNotifier.value = v,
          ),
          Text('Web API ${enabled ? 'enabled' : 'disabled'}'),
        ],
      ),
    );
  }
}

class _Fab extends StatelessWidget with Grab {
  const _Fab();

  @override
  Widget build(BuildContext context) {
    final factPhase = context.grab<AsyncPhase<Fact>>(_factNotifier);

    return FloatingActionButton(
      backgroundColor: factPhase.isWaiting ? Colors.blueGrey.shade200 : null,
      onPressed: factPhase.isWaiting ? null : _factNotifier.fetch,
      child: const Icon(Icons.refresh),
    );
  }
}
