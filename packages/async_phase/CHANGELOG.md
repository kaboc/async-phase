## 0.2.0

- Raise minimum Dart SDK version to 2.19.0.

## 0.1.0

- Breaking changes:
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
