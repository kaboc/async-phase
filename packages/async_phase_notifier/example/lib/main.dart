import 'package:flutter/material.dart';

import 'package:async_phase_notifier/async_phase_notifier.dart';
import 'package:grab/grab.dart';

import 'package:async_phase_notifier_example/api.dart';
import 'package:async_phase_notifier_example/widgets.dart';

class FactNotifier extends AsyncPhaseNotifier<Fact> {
  final _api = RandomFactApi();

  void fetch() {
    final enabled = switchNotifier.value;
    runAsync((_) => _api.fetch(enabled: enabled));
  }
}

final factNotifier = FactNotifier()..fetch();
final switchNotifier = ValueNotifier(true);

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
    factNotifier.dispose();
    switchNotifier.dispose();
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
        body: const _Body(),
        floatingActionButton: const Fab(),
        bottomNavigationBar: const Footer(),
      ),
    );
  }
}

class _Body extends StatelessWidget with Grab {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final factPhase = context.grab<AsyncPhase<Fact>>(factNotifier);
    final enabled = context.grab<bool>(switchNotifier);

    return FilledList(
      children: [
        Expanded(
          child: Center(
            child: factPhase.when(
              waiting: (_) => const CircularProgressIndicator(),
              error: (fact, e, s) => ErrorText(message: '$e'),
              complete: (fact) => FactView(fact: fact),
            ),
          ),
        ),
        const SizedBox(height: 24.0),
        Switch(
          value: enabled,
          onChanged: (v) => switchNotifier.value = v,
        ),
        Text('Web API ${enabled ? 'enabled' : 'disabled'}'),
      ],
    );
  }
}
