[![Pub Version](https://img.shields.io/pub/v/async_phase_notifier)](https://pub.dev/packages/async_phase_notifier)
[![async_phase_notifier CI](https://github.com/kaboc/async-phase/actions/workflows/async_phase_notifier.yml/badge.svg)](https://github.com/kaboc/async-phase/actions/workflows/async_phase_notifier.yml)
[![codecov](https://codecov.io/gh/kaboc/async-phase/branch/main/graph/badge.svg?token=JKEGKLL8W2)](https://codecov.io/gh/kaboc/async-phase)

A variant of `ValueNotifier` that has [AsyncPhase][AsyncPhase] representing the initial /
waiting / complete / error phases of an asynchronous operation.

`AsyncPhaseNotifier` + `AsyncPhase` is similar to `AsyncNotifier` + `AsyncValue` of Riverpod.

Unlike AsyncNotifier and AsyncValue, which are tied to package:riverpod,
`AsyncPhaseNotifier` and `AsyncPhase` have no such binding. The notifier can be
used as just a handy variant of `ValueNotifier` with `AsyncPhase` as its value
and convenient methods for manipulating the phases.

## Sample apps

- [Useless Facts](https://github.com/kaboc/async-phase/tree/main/packages/async_phase_notifier/example) - simple
- [pub.dev explorer](https://github.com/kaboc/pubdev-explorer) - advanced

## Usage

### runAsync()

The [runAsync()][runAsync] method of [AsyncPhaseNotifier][AsyncPhaseNotifier] executes
an asynchronous function, updates the `value` of `AsyncPhaseNotifier` automatically
according to the phase of the asynchronous operation, and notifies the listeners of
those changes.

1. The value of the notifier is switched to `AsyncWaiting` when the operation starts.
2. The change is notified to listeners. 
3. The value is switched to either `AsyncComplete` or `AsyncError` depending on the
   result.
4. The change is notified to listeners. 

```dart
final notifier = AsyncPhaseNotifier<int>();
notifier.runAsync((data) => someAsyncOperation());
```

### AsyncPhase

The value of `AsyncPhaseNotifier` is either [AsyncInitial][AsyncInitial],
[AsyncWaiting][AsyncWaiting], [AsyncComplete][AsyncComplete] or [AsyncError][AsyncError].
They are subtypes of `AsyncPhase`.

`AsyncPhase` provides the [when()][when] and [whenOrNull()][whenOrNull] methods,
which are useful for choosing an action based on the current phase, like returning
an appropriate widget.

```dart
child: phase.when(
  initial: (data) => Text('phase: AsyncInitial($data)'), // Optional
  waiting: (data) => Text('phase: AsyncWaiting($data)'),
  complete: (data) => Text('phase: AsyncComplete($data)'),
  error: (data, error, stackTrace) => Text('phase: AsyncError($data, $error)'),
)
```

`async_phase` is a separate package, included in this package. See
[its document][AsyncPhase] for details not covered here.

### Listening for phase changes

#### listen()

With [listen()][listen], you can listen for phase changes to imperatively trigger
some action, like showing an indicator or a dialog / snack bar, or to just log errors.

Note:

- All callbacks are optional.
    - Listener is not added if no callback function is passed.
- The `onWaiting` callback gets a boolean value that indicates the start or end
  of an asynchronous operation.

```dart
final notifier = AsyncPhaseNotifier<Auth>();
final cancel = notifier.listen(
  onWaiting: (isWaiting) { /* e.g. Toggling an indicator */ },
  onComplete: (data) { /* e.g. Logging the result of an operation */ }, 
  onError: (e, s) { /* e.g. Showing an error dialog */ },
);

...

// Remove the listener if it is no longer necessary.
cancel();
```

#### AsyncPhaseListener

It is also possible to use the [AsyncPhaseListener][AsyncPhaseListener] widget to
listen for phase changes.

```dart
child: AsyncPhaseListener(
  notifier: notifier,
  onWaiting: (isWaiting) { /* e.g. Toggling an indicator */ },
  onComplete: (data) { /* e.g. Logging the result of an operation */ },
  onError: (e, s) { /* e.g. Showing an error dialog */ },
  child: ...,
)
```

Please note that a listener is added per each `AsyncPhaseListener`, not per
notifier. If this widget is used at various places for one certain notifier,
a single notification causes each of them to run its callback function. 

## Examples

Here is WeatherNotifier extending `AsyncPhaseNotifier`. It fetches the weather
info of a city and notifies its listeners.

```dart
class WeatherNotifier extends AsyncPhaseNotifier<Weather> {
  WeatherNotifier();

  final repository = WeatherRepository();

  void fetch() {
    runAsync((weather) => repository.fetchWeather(Cities.tokyo));
  }
}
```

```dart
final notifier = WeatherNotifier();
notifier.fetch();
```

The examples below use this notifier and show a particular UI component corresponding
to each phase of the fetch.

### With [ValueListenableBuilder][value_listenable_builder]

[value_listenable_builder]: https://api.flutter.dev/flutter/widgets/ValueListenableBuilder-class.html

```dart
@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<AsyncPhase<Weather>>(
    valueListenable: notifier,
    builder: (context, phase, _) {
      // Shows a progress indicator while fetching and
      // either the result or an error when finished.
      return phase.when(
        waiting: (weather) => const CircularProgressIndicator(),
        complete: (weather) => Text('$weather'),
        error: (weather, e, s) => Text('$e'),
      );
    },
  ); 
}
```

Or you can use `AnimatedBuilder` / `ListenableBuilder` in a similar way.

### With [Provider][provider]

[provider]: https://pub.dev/packages/provider

```dart
ValueListenableProvider<AsyncPhase<Weather>>.value(
  value: notifier,
  child: MaterialApp(home: ...),
)
```

```dart
@override
Widget build(BuildContext context) {
  final phase = context.watch<AsyncPhase<Weather>>();

  return phase.when(
    waiting: (weather) => const CircularProgressIndicator(),
    complete: (weather) => Text('$weather'),
    error: (weather, e, s) => Text('$e'),
  );
}
```

### With [Grab][grab]

[grab]: https://pub.dev/packages/grab

```dart
@override
Widget build(BuildContext context) {
  final phase = notifier.grab(context);

  return phase.when(
    waiting: (weather) => const CircularProgressIndicator(),
    complete: (weather) => Text('$weather'),
    error: (weather, e, s) => Text('$e'),
  );
}
```

## TODO

- [ ] Add API documents
- [x] ~~Write tests~~

[AsyncPhaseNotifier]: https://pub.dev/documentation/async_phase_notifier/latest/async_phase_notifier/AsyncPhaseNotifier-class.html
[AsyncPhaseListener]: https://pub.dev/documentation/async_phase_notifier/latest/async_phase_notifier/AsyncPhaseListener-class.html
[runAsync]: https://pub.dev/documentation/async_phase_notifier/latest/async_phase_notifier/AsyncPhaseNotifier/runAsync.html
[listen]:https://pub.dev/documentation/async_phase_notifier/latest/async_phase_notifier/AsyncPhaseNotifier/listen.html

[AsyncPhase]: https://pub.dev/packages/async_phase
[AsyncInitial]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncInitial-class.html
[AsyncWaiting]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncWaiting-class.html
[AsyncComplete]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncComplete-class.html
[AsyncError]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncError-class.html
[when]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/when.html
[whenOrNull]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/whenOrNull.html
