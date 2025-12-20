[![Pub Version](https://img.shields.io/pub/v/async_phase)](https://pub.dev/packages/async_phase)
[![async_phase CI](https://github.com/kaboc/async-phase/actions/workflows/async_phase.yml/badge.svg)](https://github.com/kaboc/async-phase/actions/workflows/async_phase.yml)
[![codecov](https://codecov.io/gh/kaboc/async-phase/branch/main/graph/badge.svg?token=JKEGKLL8W2)](https://codecov.io/gh/kaboc/async-phase)

A sealed class and its subclasses representing phases of an asynchronous operation.

## Subclasses (Phases)

[AsyncPhase] itself is a sealed class. Its four subclasses listed below are
used to represent phases of an asynchronous operation.

- [AsyncInitial]
- [AsyncWaiting]
- [AsyncComplete]
- [AsyncError]

### Properties

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

This section covers usage in pure Dart.

> [!TIP]
> For Flutter apps, this package is best used alongside [AsyncPhaseNotifier].
> Please refer to the [async_phase_notifier][AsyncPhaseNotifier] documentation
> for more information.

### AsyncPhase.from()

Use `AsyncPhase.from()` to execute an asynchronous function and transform the result
into either an `AsyncComplete` or an `AsyncError`.

1. Use [AsyncInitial] first.
2. Switch it to [AsyncWaiting] when an asynchronous operation starts.
3. Use [AsyncPhase.from()][from] to run the operation.
4. The result of the operation is returned; either [AsyncComplete] or [AsyncError].

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

The [copyAsWaiting()][copyAsWaiting] method is a handy method to switch the
phase to `AsyncWaiting` without losing the previous data.

The `fallbackData` parameter specifies the data that should be used when the
asynchronous operation results in failure. If it is not specified, the `data`
field of the resulting `AsyncError` is set to null.

#### onComplete / onError

The `onComplete` and `onError` callbacks of [AsyncPhase.from()][from] are handy
if you want to do something depending on whether the asynchronous operation was
successful. (But note that errors occurring in those callback functions are not
automatically handled.)

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

Since [AsyncPhase] is a sealed class, it is possible to use pattern matching
instead of [when()][when] to handle the phases exhaustively. Which to use is
just a matter of preference.

```dart
final message = switch (phase) {
  AsyncInitial(:final data) => 'phase: AsyncInitial ($data)',
  AsyncWaiting(:final data) => 'phase: AsyncWaiting ($data)',
  AsyncComplete(:final data) => 'phase: AsyncComplete ($data)',
  AsyncError(:final error) => 'phase: AsyncError ($error)',
};
```

### whenOrNull()

The [when()][when] method requires all parameters except for `initial`. If you
need only some of them, use [whenOrNull()][whenOrNull] instead.

Please note that `null` is returned as the name suggests if the current phase
does not match any of the specified parameter.

e.g. In the example below, the result is `null` if the current phase is `AsyncInitial`
or `AsyncWaiting` because `initial` and `waiting` have been omitted.

```dart
final message = phase.whenOrNull(
  complete: (data) => 'phase: AsyncComplete ($data)',
  error: (data, error, stackTrace) => 'phase: AsyncError ($error)',
);
```

### Type checks

For checking if the current phase matches one of the four phases, you can use
a getter; [isInitial], [isWaiting], [isComplete] or [isError].

```dart
final phase = await AsyncPhase.from(...);

if (phase.isError) {
  return;
}
```

Using `isError` as shown above does not promote the type of the phase to `AsyncError`.
To make `error` and `stackTrace` available, check the type with the `is` operator
to get the flow analysis to work, or use pattern matching instead.

```dart
if (phase is AsyncError<Weather>) {
  print(phase.error);
  return;
}
```

or

```dart
if (phase case AsyncError(:final error)) {
  print(error);
  return;
}
```

#### rethrowError() / rethrowIfError()

[AsyncError] has the [rethrowError()][rethrowError] method. It rethrows the
error the `AsyncError` has with associated stack trace.

```dart
Future<AsyncPhase<Uint8List>> fetchImage({required Uri uri}) async {
  return AsyncPhase.from(() {
    final phase = await downloadFrom(uri: uri);
    if (phase case AsyncError(:final error)) {
      Logger.reportError(error);
      phase.rethrowError();
    }
    return resizeImage(phase.data, maxSize: ...);
  });
}
```

The [rethrowIfError()][rethrowIfError] method, on the other hand, is available
in all phases. It rethrows the error if the phase is an [AsyncError], and does
nothing otherwise.

```dart
Future<AsyncPhase<Uint8List>> fetchImage({required Uri uri}) async {
  return AsyncPhase.from(() {
    final phase = await downloadFrom(uri: uri);
    phase.rethrowIfError();
    return resizeImage(phase.data, maxSize: ...);
  });
}
```

### convert()

The [convert()][convert] method is useful if you already have a phase and want
to create a new phase of the same [AsyncPhase] subtype with a different generic
type based on the original phase.

```dart
final phase = await fetchData(); // AsyncPhase<Map<String, Object?>>
final newPhase = phase.convert(User.fromJson); // AsyncPhase<User>
```

[AsyncPhase]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase-class.html
[AsyncInitial]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncInitial-class.html
[AsyncWaiting]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncWaiting-class.html
[AsyncComplete]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncComplete-class.html
[AsyncError]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncError-class.html
[from]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/from.html
[convert]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/convert.html
[copyAsWaiting]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/copyAsWaiting.html
[when]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/when.html
[whenOrNull]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/whenOrNull.html
[rethrowError]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncError/rethrowError.html
[rethrowIfError]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncError/rethrowIfError.html
[isInitial]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/isInitial.html
[isWaiting]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/isWaiting.html
[isComplete]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/isComplete.html
[isError]: https://pub.dev/documentation/async_phase/latest/async_phase/AsyncPhase/isError.html
[AsyncPhaseNotifier]: https://pub.dev/packages/async_phase_notifier
