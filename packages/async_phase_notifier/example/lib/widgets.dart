import 'package:flutter/material.dart';

import 'package:grab/grab.dart';

import 'package:async_phase_notifier_example/api.dart';
import 'package:async_phase_notifier_example/main.dart';

class FilledList extends StatelessWidget {
  const FilledList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class Fab extends StatelessWidget {
  const Fab();

  @override
  Widget build(BuildContext context) {
    final factPhase = factNotifier.grab(context);

    return FloatingActionButton(
      backgroundColor: factPhase.isWaiting ? Colors.blueGrey.shade200 : null,
      onPressed: factPhase.isWaiting ? null : factNotifier.fetch,
      child: const Icon(Icons.refresh),
    );
  }
}

class FactView extends StatelessWidget {
  const FactView({required this.fact});

  final Fact fact;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(color: Colors.red),
    );
  }
}

class Footer extends StatelessWidget {
  const Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      color: Colors.grey.shade200,
      child: const Center(
        child: Text(
          'Thanks to:\n'
          'Random Useless Facts\n'
          'https://uselessfacts.jsph.pl/',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 11.0),
        ),
      ),
    );
  }
}
