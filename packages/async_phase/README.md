[![Pub Version](https://img.shields.io/pub/v/async_phase)](https://pub.dev/packages/async_phase)
[![async_phase CI](https://github.com/kaboc/async-phase/actions/workflows/async_phase.yml/badge.svg)](https://github.com/kaboc/async-phase/actions/workflows/async_phase.yml)
[![codecov](https://codecov.io/gh/kaboc/async-phase/branch/main/graph/badge.svg?token=JKEGKLL8W2)](https://codecov.io/gh/kaboc/async-phase)

A sealed class and its subclasses representing phases of an asynchronous operation.

## About this package

This package is mainly for use with [AsyncPhaseNotifier][AsyncPhaseNotifier]
in Flutter apps, but has been made public as a separate package so that it
can be used for pure Dart apps too.

For details on `AsyncPhaseNotifier`, see [its document][AsyncPhaseNotifier].

## AsyncPhase

[AsyncPhase][AsyncPhase] is similar to `AsyncValue`, which is part of package:riverpod.
Unlike it, this `AsyncPhase` is an independent package, so you can use it without
unnecessary dependencies, and is much simpler without surprising behaviours.

## Subclasses (Phases)

`AsyncPhase` itself is a sealed class. Its four subclasses listed below are
used to represent phases of an asynchronous operation.

- [AsyncInitial][AsyncInitial]
- [AsyncWaiting][AsyncWaiting]
- [AsyncComplete][AsyncComplete]
- [AsyncError][AsyncError]

## Properties

- **data**
    - The result of an asynchronous operation.
    - Nullable basically, but non-nullable in `AsyncComplete<T>` if the `T`
      is non-nullable.
- **error**
    - The error that occurred in an asynchronous operation.
    - This property only exists in `AsyncError`.
- **stackTrace**
    - The stack trace of the error that occurred in an asynchronous operation.
    - This property only exists in `AsyncError`.

## Usage

This section explains usages without `AsyncPhaseNotifier`.

For use with `AsyncPhaseNotifier`, see the document of
[async_phase_notifier][AsyncPhaseNotifier].

### AsyncPhase.from()

Use `AsyncPhase.from()` to execute an asynchronous function and transform the result
into either an `AsyncComplete` or an `AsyncError`.

1. Use [AsyncInitial][AsyncInitial] first.
2. Switch it to [AsyncWaiting][AsyncWaiting] when an asynchronous operation starts.
3. Use [AsyncPhase.from()][from] to run the operation.
4. The result of the operation is returned; either [AsyncComplete][AsyncComplete]
   or [AsyncError][AsyncError].

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

[copyAsWaiting()][copyAsWaiting] is a handy method to switch the phase to `AsyncWaiting`
without losing the previous data.

`fallbackData` is an argument for specifying the data that should be used when the
asynchronous operation results in failure. If it is not specified, the `data` field
of the resulting `AsyncError` is set to null.

### when()

The [when()][when] method is useful for returning something that corresponds to the
current phase, like a message, or a widget in a Flutter app.

If `initial` is not specified and the current phase is `AsyncInitial`, the callback
function passed to `waiting` is called instead.

```dart
final message = phase.when(
  initial: (data) => 'phase: AsyncInitial ($data)', // Optional
  waiting: (data) => 'phase: AsyncWaiting ($data)',
  complete: (data) => 'phase: AsyncComplete ($data)',
  error: (data, error, stackTrace) => 'phase: AsyncError ($error)',
);
```

#### Pattern matching as an alternative to when()

As [AsyncPhase] is a sealed class, it is possible to use pattern matching instead
instead of [when()][when]. Which to use is just a matter of preference.

```dart
final message = switch (phase) {
  AsyncInitial(:final data) => 'phase: AsyncInitial ($data)',
  AsyncWaiting(:final data) => 'phase: AsyncWaiting ($data)',
  AsyncComplete(:final data) => 'phase: AsyncComplete ($data)',
  AsyncError(:final error) => 'phase: AsyncError ($error)',
};
```

### whenOrNull()

[when()][when] requires all parameters except for `initial`. If you need only some
of them, use [whenOrNull()][whenOrNull] instead.

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

### Type checks

For checking if the current phase matches one of the four phases, you can use
a getter; [isInitial][isInitial], [isWaiting][isWaiting], [isComplete][isComplete]
or [isError][isError].

```dart
final phase = await AsyncPhase.from(...);

if (phase.isError) {
  return;
}
```

Using `isError` like above does not promote the type of the phase to `AsyncError`.
To make `error` and `stackTrace` available if it is `AsyncError`, check the type
with the `is` operator instead.

```dart
if (phase is AsyncError<Weather>) {
  print(phase.error);
  return;
}
```

### onComplete / onError

`onComplete` and `onError` of [AsyncPhase.from()][from] are handy if you just
want to do something depending on whether an operation was successful.

```dart
final phase = await AsyncPhase.from(
  () => someOperation(),
  onComplete: (data) {
    // Called when the operation completes successfully.
  },
  onError: (data, error, stackTrace) {
    // Called when the operation fails.
  },
);
```

[AsyncPhase]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase-class.html
[AsyncInitial]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncInitial-class.html
[AsyncWaiting]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncWaiting-class.html
[AsyncComplete]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncComplete-class.html
[AsyncError]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncError-class.html
[from]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/from.html
[copyAsWaiting]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/copyAsWaiting.html
[when]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/when.html
[whenOrNull]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/whenOrNull.html
[isInitial]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/isInitial.html
[isWaiting]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/isWaiting.html
[isComplete]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/isComplete.html
[isError]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/isError.html
[AsyncPhaseNotifier]: https://pub.dev/packages/async_phase_notifier
