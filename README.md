A variant of `ValueNotifier` that has `AsyncPhase` as its value representing one of
the waiting, complete or error phases in some async operation.

## Usage

`AsyncPhaseNotifier` + `AsyncPhase` is similar to [StateNotifier][state_notifier] +
[AsyncValue][async_value] of Riverpod, but easier to use.

[state_notifier]: https://pub.dev/packages/state_notifier
[async_value]: https://pub.dev/documentation/riverpod/latest/riverpod/AsyncValue-class.html

### Basics

#### runAsync()

The `runAsync()` method of `AsyncPhaseNotifier` executes an async function, updates
the `value` of `AsyncPhaseNotifier` automatically according to the phase of the
async operation, and notifies the listeners of those changes.

```dart
final notifier = AsyncPhaseNotifier<int>();
notifier.runAsync((data) => someAsyncOperation());
```

#### AsyncPhase

The value of `AsyncPhaseNotifier` is either `AsyncWaiting`, `AsyncComplete` or
`AsyncError`. They are subtypes of `AsyncPhase`.

`AsyncPhase` provides the `when()` method, which is useful for choosing an action
based on the current phase, like returning an appropriate widget.

```dart
child: phase.when(
  waiting: (data) => Text('phase: AsyncWaiting'),
  complete: (data) => Text('phase: AsyncComplete ($data)'),
  error: (data, error, stackTrace) => Text('phase: AsyncError ($error)'),
)
```

For checking that the current phase matches one of the three phases, you can use
a getter; `isWaiting`, `isComplete` or `isError`.

```dart
if (phase.isError) {
  showErrorDialog();
  return;
}
```

### Examples

The examples here illustrate how to show a particular UI component depending on the
phase of an async operation. 

```dart
class WeatherNotifier extends AsyncPhaseNotifier<Weather> {
  WeatherNotifier() : super(const Weather());

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

`AsyncPhase` itself is an abstract class. Its three subtypes, `AsyncWaiting`, `AsyncComplete`
and `AsyncError`, are used to represent each phase of an async operation.

### Properties

- **data**
    - Nullable, but always non-null if this is set by `AsyncPhaseNotifier<T>`
      and the `T` is a non-nullable type.
- **error**
    - Always `null` in `AsyncWaiting` and `AsyncComplete`.
    - `AsyncError` has error information in this property.
- **stackTrace**
    - Always `null` in `AsyncWaiting` and `AsyncComplete`.
    - `AsyncError` has stack trace information in this property if any.

### Usage

You can use `AsyncPhase` alone, separately from `AsyncPhaseNotifier`.

Use `AsyncPhase.from()` to execute an async function and transform the result into
either an `AsyncComplete` or an `AsyncError`.

```dart
class WeatherNotifier extends ValueNotifier<AsyncPhase<Weather?>> {
  WeatherNotifier() : super(const AsyncComplete(data: null));

  final repository = WeatherRepository();

  Future<void> fetch() async {
    value = const AsyncWaiting();

    value = await AsyncPhase.from(
      () => repository.fetchWeather(Cities.tokyo),
    );
  }
}
```

Note that in this usage, unlike an `AsyncWaiting` / `AsyncError` set by `AsyncPhaseNotifier`,
the `data` is `null` unless you put something in it manually.

As for `AsyncError`, however, it is possible to make sure certain data is set on failure
using the `fallbackData` property of `AsyncPhase.from()`.

```dart
value = await AsyncPhase.from(
  () => repository.fetchWeather(Cities.tokyo),
  fallbackData: const Weather(),
)
```

## TODO

- [ ] Add API documents
- [ ] Write tests
