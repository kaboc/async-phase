## 0.6.1

- Improve method signatures for better auto-completion of callback parameters.
- Improve documentation.

## 0.6.0

- Add `rethrowIfError()` to `AsyncPhase`.
- Add note about errors occurring in `onComplete` and `onError` callbacks.

## 0.5.2

- Improve `when()` and `whenOrNull()` so that the `data` parameter of each
  callback (except for the `error` callback) follows the nullability of the
  generic type.
- Minor refactorings.

## 0.5.1

- Add `convert()`.

## 0.5.0

- **Breaking**:
    - Change return type of callback of `AsyncPhase.from()` from `FutureOr` to `Future`.
        - This is an improvement to prevent misuse that leads to unhandled error. 
    - Make `error` of `AsyncError` required.
    - Change `error` and `stackTrace` of `AsyncError` to be non-nullable.
- Fix `AsyncComplete` having data redundantly in both `this._data` and `super.data`.
- Fix `AsyncPhase.from()` so that resulting phase is not affected by error thrown
  in `onComplete` or `onError` callback.
- Add `rethrowError()` to `AsyncError`.

## 0.4.0

- **Breaking**:
    - Change `onError` function of `AsyncPhase.from()` to receive data.
- Improve `AsyncPhase.from()`.
    - Change `fallbackData` to optional.
    - Add `onComplete`.
    - Refactor `when()` to use destructured fields.

## 0.3.2

- Add `copyWith()`.
- Minor refactorings.

## 0.3.1

- Update dependencies.

## 0.3.0

- Raise minimum Dart SDK version to 3.0.0.
- Change AsyncPhase class to `sealed`.
- Change subclasses of AsyncPhase to `final`.
- Related refactorings.

## 0.2.0

- Raise minimum Dart SDK version to 2.19.0.

## 0.1.0

- **Breaking**:
    - Improve `data` of `AsyncComplete<T>` to be non-null if `T` is not nullable.
    - Hide `error` and `stackTrace` in AsyncPhase and make them only available
      in AsyncError. 
- Make sure `data` is of type `Object?` instead of `dynamic` when the type is unknown.
- Add tests.
- Improve documentation.

## 0.0.1+1

- Update README.

## 0.0.1

- Initial version.
