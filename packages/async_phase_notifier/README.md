[![Pub Version](https://img.shields.io/pub/v/async_phase_notifier)](https://pub.dev/packages/async_phase_notifier)
[![async_phase_notifier CI](https://github.com/kaboc/async-phase/actions/workflows/async_phase_notifier.yml/badge.svg)](https://github.com/kaboc/async-phase/actions/workflows/async_phase_notifier.yml)
[![codecov](https://codecov.io/gh/kaboc/async-phase/branch/main/graph/badge.svg?token=JKEGKLL8W2)](https://codecov.io/gh/kaboc/async-phase)

A variant of `ValueNotifier` that has [AsyncPhase][AsyncPhase] representing the
phases of an asynchronous operation: initial, waiting, complete, and error.

`AsyncPhaseNotifier` + `AsyncPhase` is similar to `AsyncNotifier` + `AsyncValue` of Riverpod.

Unlike AsyncNotifier and AsyncValue, which are tied to package:riverpod,
`AsyncPhaseNotifier` and `AsyncPhase` have no such binding. The notifier can be
used as just a handy variant of `ValueNotifier` with `AsyncPhase` as its value
and convenient methods for manipulating the phases.

## Sample apps

- [Useless Facts](https://github.com/kaboc/async-phase/tree/main/packages/async_phase_notifier/example) - simple
- [pub.dev explorer](https://github.com/kaboc/pubdev-explorer) - advanced

## Usage

### update()

The [update()][update] method of [AsyncPhaseNotifier][AsyncPhaseNotifier] executes
an asynchronous function, updates the `value` of `AsyncPhaseNotifier` automatically
according to the phase of the asynchronous operation, and notifies the listeners of
those changes.

1. The value of the notifier is switched to `AsyncWaiting` when the operation starts.
2. The change is notified to listeners. 
3. The value is switched to either `AsyncComplete` or `AsyncError` depending on the
   result.
4. The change is notified to listeners. 

```dart
final notifier = AsyncPhaseNotifier(0);
notifier.update(() => someAsyncOperation());
```

### updateOnlyPhase()

This is the same as [update()][update] except that [updateOnlyPhase()][updateOnlyPhase]
only updates the phase itself without updating `value.data`, whereas `update()`
updates both the phase and `value.data`.

This method is useful when it is necessary to update the phase during execution
but the callback result should not affect the data.

e.g. Indicating the waiting status on the UI or notifying the phase change to
other parts of the code, with the existing data being kept unchanged.

### AsyncPhase

The value of `AsyncPhaseNotifier` is either [AsyncInitial][AsyncInitial],
[AsyncWaiting][AsyncWaiting], [AsyncComplete][AsyncComplete] or [AsyncError][AsyncError].
They are subtypes of [AsyncPhase].

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

### value.data vs data

`data` is a getter for `value.data`. The former is handy and more type-safe since
the return type is non-nullable if the generic type `T` of `AsyncPhaseNotifier<T>`
is non-nullable, whereas the latter is always nullable, often requiring a null
check or a non-null assertion.

### Listening for phase changes

#### listen()

With [listen()][listen], you can trigger some action when the phase or its data changes.

This is not much different from `addListener()`, except for the following points:

- Returns a function to easily stop listening.
- Takes a listener function that receives the phase at the time of the call.
- The listener is called asynchronously because this method uses `Stream` internally.

```dart
final notifier = AsyncPhaseNotifier(Auth());
final cancel = notifier.listen((phase) { /* Some action */ });

...

// Remove the listener if it is no longer necessary.
cancel();
```

#### listenFor()

With [listenFor()][listenFor], you can trigger some action in one of the callbacks
relevant to the latest phase when the phase or its data changes.

Note:

- All callbacks are optional.
    - Listener is not added if no callback function is passed.
- The `onWaiting` callback is called when the phase has changed to `AsyncWaiting` and
  also from `AsyncWaiting`. A boolean value is passed to the callback to indicate the
  start or end of an asynchronous operation.

```dart
final notifier = AsyncPhaseNotifier(Auth());
final cancel = notifier.listenFor(
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

Please note that a listener is added for each `AsyncPhaseListener` widget, not
per notifier. If this widget is used in multiple places for the same notifier,
a single notification will trigger the callback function in each of those widgets.

Please also note that changes to callbacks (e.g. `onComplete`) will only take
effect when the widget is provided with a new `key`.

## Examples

Here is WeatherNotifier extending `AsyncPhaseNotifier`. It fetches the weather
info of a city and notifies its listeners.

```dart
class WeatherNotifier extends AsyncPhaseNotifier<Weather> {
  WeatherNotifier() : super(const Weather());

  final repository = WeatherRepository();

  void fetch() {
    update(() => repository.fetchWeather(Cities.tokyo));
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
void main() {
  runApp(
    const Grab(child: App()),
  ); 
}
```

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
[update]: https://pub.dev/documentation/async_phase_notifier/latest/async_phase_notifier/AsyncPhaseNotifier/update.html
[updateOnlyPhase]: https://pub.dev/documentation/async_phase_notifier/latest/async_phase_notifier/AsyncPhaseNotifier/updateOnlyPhase.html
[listen]:https://pub.dev/documentation/async_phase_notifier/latest/async_phase_notifier/AsyncPhaseNotifier/listen.html
[listenFor]:https://pub.dev/documentation/async_phase_notifier/latest/async_phase_notifier/AsyncPhaseNotifier/listenFor.html

[AsyncPhase]: https://pub.dev/packages/async_phase
[AsyncInitial]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncInitial-class.html
[AsyncWaiting]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncWaiting-class.html
[AsyncComplete]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncComplete-class.html
[AsyncError]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncError-class.html
[when]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/when.html
[whenOrNull]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/whenOrNull.html
