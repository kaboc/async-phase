import 'package:flutter/material.dart';

import 'package:async_phase_notifier/async_phase_notifier.dart';
import 'package:grab/grab.dart';

import 'package:async_phase_notifier_example/api.dart';
import 'package:async_phase_notifier_example/theme.dart';
import 'package:async_phase_notifier_example/widgets.dart';

class FactNotifier extends AsyncPhaseNotifier<Fact> {
  FactNotifier() : super(const Fact()) {
    fetch();
  }

  final _api = RandomFactApi();

  void fetch() {
    final enabled = switchNotifier.value;
    update(() => _api.fetch(enabled: enabled));
  }
}

final factNotifier = FactNotifier();
final switchNotifier = ValueNotifier(true);

//======================================================================

void main() {
  runApp(
    const Grab(child: App()),
  );
}

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
      theme: AppTheme.data,
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

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final factPhase = factNotifier.grab(context);
    final enabled = switchNotifier.grab(context);

    return FilledList(
      children: [
        Expanded(
          child: Center(
            child: factPhase.when(
              waiting: (fact) => const CircularProgressIndicator(),
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
