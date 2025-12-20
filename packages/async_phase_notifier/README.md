[![Pub Version](https://img.shields.io/pub/v/async_phase_notifier)](https://pub.dev/packages/async_phase_notifier)
[![async_phase_notifier CI](https://github.com/kaboc/async-phase/actions/workflows/async_phase_notifier.yml/badge.svg)](https://github.com/kaboc/async-phase/actions/workflows/async_phase_notifier.yml)
[![codecov](https://codecov.io/gh/kaboc/async-phase/branch/main/graph/badge.svg?token=JKEGKLL8W2)](https://codecov.io/gh/kaboc/async-phase)

A `ValueNotifier` that has [AsyncPhase][AsyncPhase] representing the phases of
an asynchronous operation: initial, waiting, complete, and error.

[AsyncPhaseNotifier] can be used as just a handy variant of `ValueNotifier` with
`AsyncPhase` as its value and convenient methods for manipulating the phases.

## Sample apps

- [Useless Facts](https://github.com/kaboc/async-phase/tree/main/packages/async_phase_notifier/example) - simple
- [pub.dev explorer](https://github.com/kaboc/pubdev-explorer) - advanced

## Basic Concept: AsyncPhase

This package is built on top of [async_phase][AsyncPhase].

`AsyncPhase` is a type that represents the current status of an asynchronous
operation. It consists of the following four states:

* **AsyncInitial**:
    * The state before the operation has started.
* **AsyncWaiting**:
    * The state where the operation is in progress. It can optionally hold the
      previous data.
* **AsyncComplete**:
    * The state where the operation finished successfully. It contains the
      resulting data.
* **AsyncError**:
    * The state where the operation failed. It contains an error and a stack
      trace, and can also hold the previous data.

By using `AsyncPhaseNotifier`, you can easily manage these transitions and reflect
them in your UI.

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

## Usage: AsyncPhaseNotifier

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
await notifier.update(() => someAsyncOperation());
```

Optionally, you can pass a callback function that takes the result of the operation
as a parameter. The `onError` callback is especially useful for logging errors.

```dart
await notifier.update(
  () => someAsyncOperation(),
  onWaiting: (data) => ...,
  onComplete: (data) => ...,
  onError: (e, s) => Logger.reportError(e, s),
);
```

> [!CAUTION]
> Errors occurring in those callback functions are not automatically handled.

### updateType()

The `updateType()` method is used to update the phase type while preserving
the existing `value.data`.

* **Preserves Existing Data**:
    * The callback result can be of any type and does not affect the notifier's current data.
* **Direct Phase Mapping**:
    * If the callback returns an `AsyncPhase`, the notifier adopts that specific phase.
      This is ideal when calling repository methods that already return `AsyncPhase`
      (e.g., returning `AsyncError` will transition the notifier to an error state
      without needing to manually throw an exception).
* **Flexible Implementation**:
    * Perfect for implementing [command][command]-like approaches where UI logic
      and business logic are decoupled.

For more technical details and behavior regarding callbacks, please refer to the
[updateType()][updateType] documentation.

### value.data vs data

The `data` getter returns `value.data`. Using `data` is handier and more
type-safe since the return type is non-nullable if the generic type `T` of
`AsyncPhaseNotifier<T>` is non-nullable, whereas `value.data` is always nullable,
often requiring a null check or a non-null assertion.

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

```dart
final notifier = AsyncPhaseNotifier(Auth());
final cancel = notifier.listenFor(
  onWaiting: (data) { /* e.g. Start loading indicator */ },
  onComplete: (data) { /* e.g. Stop loading indicator */ },
  onError: (e, s) { /* e.g. Showing an error dialog */ },
);

...

// Remove the listener if it is no longer necessary.
cancel();
```

> [!NOTE]
> All callbacks are optional. Listener is not added if no callback function is passed.

#### AsyncPhaseListener

It is also possible to use the [AsyncPhaseListener][AsyncPhaseListener] widget to
listen for phase changes.

```dart
child: AsyncPhaseListener(
  notifier: notifier,
  onWaiting: (data) { /* e.g. Start loading indicator */ },
  onComplete: (data) { /* e.g. Stop loading indicator */ },
  onError: (e, s) { /* e.g. Showing an error dialog */ },
  child: ...,
)
```

> [!CAUTION]
> A listener is added for each `AsyncPhaseListener` widget, not per notifier.
> If this widget is used in multiple places for the same notifier, a single
> notification will trigger the callback function in each of those widgets.

> [!CAUTION]
> Changes to callbacks (e.g. `onComplete`) will only take effect when the widget
> is provided with a new `key` or a new `notifier`.

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
      // Shows a loading indicator while fetching and
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
[updateType]: https://pub.dev/documentation/async_phase_notifier/latest/async_phase_notifier/AsyncPhaseNotifier/updateType.html
[command]: https://docs.flutter.dev/app-architecture/design-patterns/command
[listen]:https://pub.dev/documentation/async_phase_notifier/latest/async_phase_notifier/AsyncPhaseNotifier/listen.html
[listenFor]:https://pub.dev/documentation/async_phase_notifier/latest/async_phase_notifier/AsyncPhaseNotifier/listenFor.html

[AsyncPhase]: https://pub.dev/packages/async_phase
[AsyncInitial]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncInitial-class.html
[AsyncWaiting]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncWaiting-class.html
[AsyncComplete]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncComplete-class.html
[AsyncError]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncError-class.html
[when]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/when.html
[whenOrNull]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/whenOrNull.html
