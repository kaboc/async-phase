A variant of `ValueNotifier` that has `AsyncPhase` as its value representing one of
the waiting, complete or error phases in some async operation.

## What is this?

`AsyncPhaseNotifier` + `AsyncPhase` is similar to [AsyncNotifier][async_notifier] +
[AsyncValue][async_value] of Riverpod.

Unlike AsyncValue and AsyncNotifier, which are tied to Riverpod, `AsyncPhase` and
`AsyncPhaseNotifier` have no such binding. The notifier can be used as just a handy
variant of `ValueNotifier` with `AsyncPhase` as its value.

[async_notifier]: https://pub.dev/documentation/riverpod/latest/riverpod/AsyncNotifier-class.html
[async_value]: https://pub.dev/documentation/riverpod/latest/riverpod/AsyncValue-class.html

## Demo apps

- [Useless Facts](https://github.com/kaboc/async-phase-notifier/tree/main/example)
- [pub.dev explorer](https://github.com/kaboc/pubdev-explorer)

## AsyncPhaseNotifier

### Usage

#### runAsync()

The `runAsync()` method of `AsyncPhaseNotifier` executes an async function, updates
the `value` of `AsyncPhaseNotifier` automatically according to the phase of the
async operation, and notifies the listeners of those changes.

```dart
final notifier = AsyncPhaseNotifier<int>();
notifier.runAsync((data) => someAsyncOperation());
```

#### AsyncPhase

The value of `AsyncPhaseNotifier` is either `AsyncInitial`, `AsyncWaiting`, `AsyncComplete`
or `AsyncError`. They are subtypes of `AsyncPhase`.

`AsyncPhase` provides the `when()` method, which is useful for choosing an action
based on the current phase, like returning an appropriate widget.

```dart
child: phase.when(
  initial: (data) => Text('phase: AsyncInitial ($data)'), // Optional
  waiting: (data) => Text('phase: AsyncWaiting ($data)'),
  complete: (data) => Text('phase: AsyncComplete ($data)'),
  error: (data, error, stackTrace) => Text('phase: AsyncError ($error)'),
)
```

For checking that the current phase matches one of the four phases, you can use
a getter; `isInitial`, `isWaiting`, `isComplete` or `isError`.

```dart
if (phase.isError) {
  showErrorDialog();
  return;
}
```

#### Error listener

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

### Examples
The examples here illustrate how to show a particular UI component depending on the
phase of an async operation. 

```dart
class WeatherNotifier extends AsyncPhaseNotifier<Weather> {
  WeatherNotifier();

  final repository = WeatherRepository();

  void fetch() {
    runAsync((_) => repository.fetchWeather(Cities.tokyo));
  }
}
```

Above is an `AsyncPhaseNotifier` that fetches the weather info of a city and notifies
its listeners. We'll see in the examples below how the notifier is used in combination
with each of the several ways to rebuild a widget.

#### With [ValueListenableBuilder][value_listenable_builder]

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
        waiting: (_) => const CircularProgressIndicator(),
        complete: (data) => Text('$data'),
        error: (_, error, __) => Text('$error'),
      );
    },
  ); 
}
```

Or you can use `AnimatedBuilder` in a similar way.

#### With [Provider][provider]

[provider]: https://pub.dev/packages/provider

```dart
final notifier = WeatherNotifier();

...

ValueListenableProvider<AsyncPhase<Weather>>.value(
  value: notifier,
  child: MaterialApp(home: ...),
)

...

notifier.fetch();
```

```dart
@override
Widget build(BuildContext context) {
  final phase = context.watch<AsyncPhase<Weather>>();

  return phase.when(
    waiting: (_) => const CircularProgressIndicator(),
    complete: (data) => Text('$data'),
    error: (_, error, __) => Text('$error'),
  );
}
```

#### With [Grab][grab]

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
    waiting: (_) => const CircularProgressIndicator(),
    complete: (data) => Text('$data'),
    error: (_, error, __) => Text('$error'),
  );
}
```

## AsyncPhase

`AsyncPhase` itself is an abstract class. Its four subtypes, `AsyncInitial`, `AsyncWaiting`,
`AsyncComplete` and `AsyncError`, are used to represent each phase of an async operation.

### Properties

- **data**
    - Nullable, but always non-null once a value is set by `runAsync()` of `AsyncPhaseNotifier<T>`
      where the `T` is a non-nullable type. 
- **error**
    - Always `null` in a phase other than `AsyncError`.
    - `AsyncError` has error information in this property if any.
- **stackTrace**
    - Always `null` in a phase other than `AsyncError`.
    - `AsyncError` has stack trace information in this property if any.

### Usage

`AsyncPhase` is used in `AsyncPhaseNotifier` automatically, but it can also be
used separately.

It was already described above how `AsyncPhaseNotifier` is used, so below here is
how `AsyncPhase` is used with a different type of notifier like `ValueNotifier`. 

#### AsyncPhase.from()

Use `AsyncPhase.from()` to execute an async function and transform the result into
either an `AsyncComplete` or an `AsyncError`.

In this usage, the `value` of ValueNotifier is not automatically updated to the
waiting phase before the async operation starts. It is recommended that `copyAsWaiting()`
is used as shown below to switch the phase to `AsyncWaiting` without losing the
previous `data`.

It should also be noted that `fallbackData` is necessary to specify the data that
should be used when the async operation results in failure.

```dart
import 'package:async_phase_notifier/async_phase.dart';

class WeatherNotifier extends ValueNotifier<AsyncPhase<Weather>> {
  WeatherNotifier() : super(const AsyncInitial(data: Weather()));

  final repository = WeatherRepository();

  Future<void> fetch() async {
    value = value.copyAsWaiting();

    value = await AsyncPhase.from(
      () => repository.fetchWeather(Cities.tokyo),
      fallbackData: value.data,
    );
  }
}
```

## TODO

- [ ] Add API documents
- [ ] Write tests
