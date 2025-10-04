## 0.6.1

- Add support for replacing notifier in `AsyncPhaseListener`.

## 0.6.0

- Remove deprecated `runAsync()`.
- Avoid the error that occurred when `update()` ended after `AsyncPhaseNotifier` was disposed.
- Refactor `update()` and remove unnecessary reassignment of new phase to `value`.
- Refactor and improve tests.

## 0.5.2

- Update async_phase to 0.5.2.

## 0.5.1

- Update async_phase to 0.5.1.

## 0.5.0

- **Breaking**:
    - Change parameter of `AsyncPhaseNotifier` constructor to be no longer optional.
    - Change callback of `runAsync()` to no longer receive current data.
    - Change return type of callback of `runAsync()` from `FutureOr` to `Future`.
        - This is an improvement to prevent misuse that leads to unhandled error.
    - Deprecate `runAsync()` in favour of new `update()`.
    ```dart
    // Before
    final notifier = AsyncPhaseNotifier<int>();
    // After
    final notifier = AsyncPhaseNotifier<int>(0);
    
    // Before
    class MyNotifier extends AsyncPhaseNotifier<int> {
      MyNotifier();
    }
    // After
    class MyNotifier extends AsyncPhaseNotifier<int> {
      MyNotifier() : super(0);
    }
    
    // Before
    await runAsync((data) => yourFunc(data));
    // After
    await update(() => yourFunc(data)); // `data` here is a new getter for `value.data`.
    ```
- Upgrade async_phase to 0.5.0.
    - The return type of callback of `AsyncPhase.from()` is now `Future` instead
      of `FutureOr`. 
    - `error` and `stackTrace` of `AsyncError` is now non-nullable.
    - See the [change log](https://pub.dev/packages/async_phase/changelog#050)
      of package:async_phase for details and non-breaking changes.
- Add `update()` to `AsyncPhaseNotifier` as a replacement of deprecated `runAsync()`.
- Add `updateOnlyPhase()` to `AsyncPhaseNotifier`,
- Add type-safe `data` getter for `value.data` to `AsyncPhaseNotifier`. 
- Fix `runAsync()`.
    - Resulting `AsyncError` had stale data if fallback data was not provided and
      `value.data` was updated while the callback was executed.
- Some minor improvements.

## 0.4.3

- Upgrade async_phase to 0.4.0.

## 0.4.2

- Improve comments and tests to reduce risk of nullability mistakes.
- Fix and simplify description on nullability of `data` in README.
- Update dependencies.

## 0.4.1

- Update dependencies.
    - `copyWith()` added to AsyncPhase at async_phase 0.3.2 is available.
- Add tests for `dispose()` of AsyncPhaseNotifier.
- Fix test for `listenFor()`.
- Small refactorings.

## 0.4.0

- Breaking changes:
    - Rename `listen()` to `listenFor()`.
    - Add the new `listen()` method.
        - This method takes a single listener function that receives the latest phase, whereas `listenFor()` takes several callback functions, each of which corresponds to a certain phase.

## 0.3.0

- Raise minimum Flutter SDK version to 3.10.0.
- Bump async_phase to 0.3.0.
- Related refactorings.

## 0.2.0+1

- Fix description on AsyncPhaseListener.

## 0.2.0

- Breaking changes:
    - Change listeners to listen to not only errors but also changes to waiting/complete phases.
        - Rename `listenError()` to `listen()` and add callbacks.
        - Rename `AsyncErrorListener` to `AsyncPhaseListener` and add callbacks.
            - `BuildContext` is not passed to `onError` any more.
    - Require Flutter 3.7.0 or above.
- Add dependency on meta.
- Warn if the result of `listen()` is not used.

## 0.1.0

- Update async_phase to 0.1.0.
    - There are [some breaking changes](https://pub.dev/packages/async_phase/changelog#010).
- Simplify the `value` setter that was needlessly complex and possibly led to wrong behaviours.

## 0.0.1

- Initial version.
