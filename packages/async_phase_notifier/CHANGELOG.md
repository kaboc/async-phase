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
