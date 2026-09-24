# Extensible form state — design

Date: 2026-09-21
Target release: 1.1.0 (additive, no breaking changes)

## Goal

Let apps extend `MkFormState` with their own typed status fields, so one form
can track several independent API calls (avatar upload, username check, OTP
send, a multi-stage submit) and expose new statuses, without the package
prescribing a status model.

## Non-goals

- Making `MkFormBloc` generic (`MkFormBloc<S>`). The state type stays
  `MkFormState`; subclasses downcast, as `MkStepFormBloc` already does.
- A built-in status map, `runOperation`, or new status classes. Apps declare
  typed fields on their own state subclass and reuse `MkSubmissionStatus`.
- Per-call configuration such as debounce, retry or concurrency policy.

## Current problems

1. `MkFormBloc.reset()` emits a plain `MkFormState`, dropping any subclass
   state. `MkStepFormBloc` works around this by overriding `reset()` and
   rebuilding the whole state by hand.
2. `submit()` and `canSubmit` only consider `isSubmitting`. A subclass has no
   way to declare that another in-flight call should block submission.
3. `MkFormBuilder` is typed to the base `MkFormState`, so custom fields need
   manual casts.

## Design

### 1. `MkFormState.reset()`

New overridable method on `MkFormState` returning an idle, pristine copy that
preserves subclass fields:

```dart
MkFormState reset({
  required bool isValid,
  required bool isValidating,
  required Map<String, dynamic> values,
})
```

Base implementation: `copyWith` with `submissionStatus` idle, `isDirty`,
`isTouched`, `wasSubmitted` all false, `submissionError` cleared, and the given
`isValid`, `isValidating`, `values`.

`MkFormBloc.reset()` becomes `_rootGroup.reset(); emit(state.reset(...))`.
`MkStepFormState` overrides `reset()` to also set `currentStep: 0`,
`completedSteps: const {}`, `isLoadingInitialData: false` and clear
`redirectedFromStep` / `invalidStepIndex`. The `reset()` override in
`MkStepFormBloc` is deleted.

Custom subclasses that add fields override `reset()` to return their own
fields to defaults (calling `super.reset(...)` and re-applying `copyWith`).

### 2. `MkFormState.isBusy`

New overridable getter, `bool get isBusy => isSubmitting;`.

- `canSubmit` becomes `isValid && !isValidating && !isBusy`.
- `MkFormBloc.submit()` rejects the call when `state.isBusy` (in addition to the
  existing `_isSubmitInFlight` guard).

A subclass writes `isBusy => super.isBusy || avatarStatus.isSubmitting` to block
submission while an upload runs.

### 3. Typed builder: `MkFormStateBuilder<S>`

`MkFormBuilder` stays exactly as it is (non-generic). A generic `MkFormBuilder<S>`
was rejected: Dart infers a type parameter that appears only in closure parameter
positions as `Null`, so an untyped `MkFormBuilder(builder: (c, state, b) => ...)`
would stop compiling and break existing call sites.

Instead add a new widget `MkFormStateBuilder<S extends MkFormState>` (and
`typedef MkFormStateWidgetBuilder<S extends MkFormState>`) in `form_builder.dart`.
`builder` and `buildWhen` receive `S`; callers write the type argument
explicitly. `MkFormBuilder.build` delegates to `MkFormStateBuilder<MkFormState>`,
so there is one implementation. `MkFormListener` is unchanged; its callbacks
never receive the state.

Internally the widget keeps `BlocBuilder<MkFormBloc, MkFormState>` and downcasts;
when the bloc's state is not an `S`, throw a `StateError` naming both types.

### 4. Documented extension pattern

Reuse `MkSubmissionStatus` for custom fields. Worked example (README and doc
comments):

- `ProfileFormState extends MkFormState`, adding `avatarStatus`,
  `usernameStatus`, `otpStatus` with `copyWith`, `props`, `isBusy` and `reset`.
- `ProfileFormBloc extends MkFormBloc`, passing `initialState:` and overriding
  `state` with `super.state as ProfileFormState`.
- Bloc methods emit `state.copyWith(avatarStatus: const
  MkSubmissionStatus.submitting())`, await the API, then emit success or
  failure. `onSubmit` may chain several API calls the same way.
- `onUpdateFormState` stays; subclasses override it only when their `copyWith`
  is not enough to carry fields through control updates.

## Error handling and lifecycle

- All emits from subclass methods go through the existing `MkFormBloc.emit`
  guard, so results arriving after `close()` are silent no-ops.
- The typed builder's wrong-type `StateError` is a programmer error, not a
  runtime path.

## Testing (existing tests in `test/blocs` and `test/ui` must still pass)

- Reset preserves a user-defined state subclass and returns its custom fields to
  defaults; `MkStepFormBloc.reset()` still returns to step 0 with nothing
  completed.
- `isBusy` true blocks both `canSubmit` and `submit()`; `submit()` proceeds once
  it is false.
- A bloc tracking two concurrent calls emits independent status transitions.
- `MkFormStateBuilder<S>` delivers `S`; the wrong-type case throws `StateError`;
  untyped `MkFormBuilder(...)` still compiles and behaves as before.
- `dart analyze` and `flutter test` are clean before completion is claimed.

## Docs and example

- README "Extending form state" section and a CHANGELOG entry for 1.1.0.
- One example screen: profile form with avatar upload, username check, an OTP
  status and a multi-call submit, using a `ProfileFormState` subclass.

## Release

Additive change, version 1.1.0. Bumping the version and publishing are left to
the maintainer.
