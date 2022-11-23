A class and its subclasses representing phases of an asynchronous operation.

## About this package

This package is mainly for use with [AsyncPhaseNotifier][AsyncPhaseNotifier]
in Flutter apps, but has been made public as a separate package so that it
can be used for pure Dart apps too.

For details on `AsyncPhaseNotifier`, see [its document][AsyncPhaseNotifier].

## AsyncPhase

`AsyncPhase` is similar to `AsyncValue` of Riverpod. Unlike AsyncValue, which
is part of package:riverpod, `AsyncPhase` is an independent package, so you
can use it without unnecessary dependency.

## Subclasses (Phases)

`AsyncPhase` itself is an abstract class. Its four subclasses listed below are
used to represent phases of an asynchronous operation.

- AsyncInitial
- AsyncWaiting
- AsyncComplete
- AsyncError


## Properties

- **data**
    - The result of an asynchronous operation.
    - Nullable, but always non-null once a value is set by `runAsync()` of
      `AsyncPhaseNotifier<T>` if the `T` is a non-nullable type, even if the
      phase is of type `AsyncError`.
    - It is also non-null once a value is set and then `AsyncPhase.from<T>()`
      and `copyAsWaiting()` are used properly where the `T` is non-nullable.
- **error**
    - Information of the error that occurred during an asynchronous operation.
    - Always `null` in a phase other than `AsyncError`.
- **stackTrace**
    - StackTrace of the error that occurred during an asynchronous operation.
    - Always `null` in a phase other than `AsyncError`.

## Usage

This section explains usages without `AsyncPhaseNotifier`.

For use with `AsyncPhaseNotifier`, see the document of
[async_phase_notifier][AsyncPhaseNotifier].

### AsyncPhase.from()

Use `AsyncPhase.from()` to execute an asynchronous function and transform the result
into either an `AsyncComplete` or an `AsyncError`.

1. Use `AsyncInitial` first.
2. Switch it to `AsyncWaiting` when an asynchronous operation starts.
3. Use `AsyncPhase.from()` to run the operation.
4. The result of the operation is returned; either `AsyncComplete` or `AsyncError`.

#### Example

```dart
class WeatherForecast {
  WeatherForecast({required this.onPhaseChanged});

  final void Function(AsyncPhase<Weather>) onPhaseChanged;

  AsyncPhase<Weather> _phase = AsyncInitial(Weather());

  Future<void> fetch() async {
    _phase = _phase.copyAsWaiting();
    onPhaseChanged(_phase);

    _phase = await AsyncPhase.from(
      () => repository.fetchWeather(Cities.tokyo),
      fallbackData: _phase.data,
    );
    onPhaseChanged(_phase);
  }
}
```

`copyAsWaiting()` is a handy method to switch the phase to `AsyncWaiting` without
losing the previous data.

`fallbackData` is a parameter for specifying the data that should be used when the
asynchronous operation results in failure.

### when()

The `when()` method is useful for returning something that corresponds to the current
phase, like a message, or a widget in a Flutter app.

```dart
final message = phase.when(
  initial: (data) => 'phase: AsyncInitial ($data)', // Optional
  waiting: (data) => 'phase: AsyncWaiting ($data)',
  complete: (data) => 'phase: AsyncComplete ($data)',
  error: (data, error, stackTrace) => 'phase: AsyncError ($error)',
);
```

### whenOrNull()

`when()` requires all parameters except for `initial`. If you need only some of
them, use `whenOrNull()` instead.

Please note that `null` is returned as the name suggests if the current phase
does not match any of the specified parameter.

e.g. In the example below, the result is `null` if the current phase is `AsyncInitial`
or `AsyncWaiting` because `initial` and `waiting` have been omitted.

```dart
final message = phase.whenOrWhen(
  complete: (data) => 'phase: AsyncComplete ($data)',
  error: (data, error, stackTrace) => 'phase: AsyncError ($error)',
);
```

### Getters

For checking if the current phase matches only one of the four phases, you can
use a getter; `isInitial`, `isWaiting`, `isComplete` or `isError`.

```dart
if (phase.isError) {
  logError(...);
  return;
}
```

## TODO

- [ ] Add API documents
- [ ] Write tests

[AsyncPhaseNotifier]: https://github.com/kaboc/async-phase/tree/main/packages/async_phase_notifier
