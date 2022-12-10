[![Pub Version](https://img.shields.io/pub/v/async_phase_notifier)](https://pub.dev/packages/async_phase_notifier)
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

The `runAsync()` method of `AsyncPhaseNotifier` executes an asynchronous function,
updates the `value` of `AsyncPhaseNotifier` automatically according to the phase of
the asynchronous operation, and notifies the listeners of those changes.

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

`async_phase` is a separate package, contained in this package. See
[its document][AsyncPhase] for details not covered here.

### Listening for errors

#### listenError()

You can listen for errors to imperatively trigger some action when the phase is
turned into `AsyncError` by `runAsync()`, like showing an AlertDialog or a SnackBar,
or to just log them.

```dart
final notifier = AsyncPhaseNotifier<Auth>();
final removeErrorListener = notifier.listenError((e, s) { ... });

...

// Remove the listener if it is no longer necessary.
removeErrorListener();
```

#### AsyncErrorListener

It is also possible to use `AsyncErrorListener` to listen for errors. The `onError`
callback is called when an asynchronous operation results in failure.

```dart
child: AsyncErrorListener(
  notifier: notifier,
  onError: (context, error, stackTrace) {
    ScaffoldMessenger.of(context).showMaterialBanner(...);
  },
  child: ...,
)
```

A listener is added per each `AsyncErrorListener`. Please note that if you use this
widget at multiple places for a single notifier, the callback functions of all those
widgets are called on error.

## Examples
The examples here illustrate how to show a particular UI component depending on the
phase of an asynchronous operation.

```dart
class WeatherNotifier extends AsyncPhaseNotifier<Weather> {
  WeatherNotifier();

  final repository = WeatherRepository();

  void fetch() {
    runAsync((weather) => repository.fetchWeather(Cities.tokyo));
  }
}
```

Above is an `AsyncPhaseNotifier` that fetches the weather info of a city and notifies
its listeners. We'll see in the examples below how the notifier is used in combination
with each of the several ways to rebuild a widget.

### With [ValueListenableBuilder][value_listenable_builder]

[value_listenable_builder]: https://api.flutter.dev/flutter/widgets/ValueListenableBuilder-class.html

```dart
final notifier = WeatherNotifier();
notifier.fetch();
```

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

Or you can use `AnimatedBuilder` in a similar way.

### With [Provider][provider]

[provider]: https://pub.dev/packages/provider

```dart
final notifier = WeatherNotifier();
notifier.fetch();
```

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
final notifier = WeatherNotifier();
notifier.fetch();
```

```dart
@override
Widget build(BuildContext context) {
  final phase = context.grab<AsyncPhase<Weather>>(notifier);

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

[AsyncPhase]: https://pub.dev/packages/async_phase
[AsyncInitial]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncInitial-class.html
[AsyncWaiting]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncWaiting-class.html
[AsyncComplete]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncComplete-class.html
[AsyncError]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncError-class.html
[when]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/when.html
[whenOrNull]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/whenOrNull.html
