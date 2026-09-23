# Extensible form state via generics — design

Date: 2026-09-23
Target release: 1.1.0 (still unpublished — supersedes the subclassing-based
design in `2026-09-21-extensible-form-state-design.md`; no back-compat shims
needed)

## Goal

Let apps add typed fields (statuses, extra data) to `MkFormState` without
writing a subclass. Today's subclassing pattern (`ProfileFormState extends
MkFormState`) forces every subclass to redeclare the full constructor,
`copyWith`, `reset`, and `props` for all inherited fields — Dart requires an
overridden `copyWith` to repeat every base named parameter, so this
boilerplate cannot be trimmed while keeping subclassing as the extension
mechanism. Replacing it with a generic slot on `MkFormState` removes that
boilerplate entirely: apps stop subclassing and instead parameterize.

## Non-goals

- Making `MkFormBuilder` (the untyped, no-type-argument widget) generic.
  It stays exactly as it is; `MkFormStateBuilder<S>` remains the opt-in typed
  widget, unchanged in shape.
- A built-in status map, `runOperation`, or new status classes. Apps declare
  a single typed `extra` payload (e.g. a freezed class) and reuse
  `MkSubmissionStatus` inside it, as `ProfileExtras` already does.
- Per-call configuration such as debounce, retry or concurrency policy.
- Any deprecation/migration shim for the 2026-09-21 subclassing design — it
  was never published, so it is replaced outright.

## Design

### 1. `MkFormState<T extends Object?>`

`MkFormState` gains a generic parameter `T` and a single `extra` field of
type `T`, plus two optional behavior hooks stored (not treated as data):

```dart
class MkFormState<T extends Object?> extends Equatable {
  const MkFormState({
    required this.submissionStatus,
    required this.isValid,
    required this.isValidating,
    required this.isDirty,
    required this.isTouched,
    required this.wasSubmitted,
    required this.values,
    this.submissionError,
    required this.extra,
    this.extraReset,
    this.isExtraBusy,
  });

  final T extra;

  /// Regenerates a pristine [extra] on [reset]. If omitted, [reset] leaves
  /// [extra] untouched.
  ///
  /// Marked `@protected`: part of the constructor's public surface (apps set
  /// it once when building their initial state) but not meant to be read
  /// outside a state's own `copyWith`/`reset` chain. It is a plain
  /// (non-underscore) field, not Dart-private, because `MkStepFormState`
  /// (in a different file) must read it from its own `copyWith`/`reset`
  /// overrides — Dart privacy is per-library, so a leading-underscore field
  /// declared in `form_state.dart` would not be visible there.
  @protected
  final T Function()? extraReset;

  /// Feeds [isBusy]. If omitted, [extra] never contributes to [isBusy].
  /// Same visibility rationale as [extraReset].
  @protected
  final bool Function(T extra)? isExtraBusy;

  bool get isBusy => isSubmitting || (isExtraBusy?.call(extra) ?? false);

  /// Returns a copy with [update] applied to [extra].
  MkFormState<T> updateExtra(T Function(T extra) update) =>
      copyWith(extra: update(extra));

  MkFormState<T> copyWith({
    MkSubmissionStatus? submissionStatus,
    bool? isValid,
    bool? isValidating,
    bool? isDirty,
    bool? isTouched,
    bool? wasSubmitted,
    Map<String, dynamic>? values,
    Object? Function()? submissionError,
    T? extra,
  }) {
    return MkFormState<T>(
      submissionStatus: submissionStatus ?? this.submissionStatus,
      isValid: isValid ?? this.isValid,
      isValidating: isValidating ?? this.isValidating,
      isDirty: isDirty ?? this.isDirty,
      isTouched: isTouched ?? this.isTouched,
      wasSubmitted: wasSubmitted ?? this.wasSubmitted,
      values: values ?? this.values,
      submissionError: submissionError != null
          ? submissionError()
          : this.submissionError,
      extra: extra ?? this.extra,
      extraReset: extraReset,
      isExtraBusy: isExtraBusy,
    );
  }

  MkFormState<T> reset({
    required bool isValid,
    required bool isValidating,
    required Map<String, dynamic> values,
  }) {
    return copyWith(
      submissionStatus: const MkSubmissionStatus.idle(),
      isValid: isValid,
      isValidating: isValidating,
      isDirty: false,
      isTouched: false,
      wasSubmitted: false,
      values: values,
      submissionError: () => null,
      extra: extraReset != null ? extraReset!() : extra,
    );
  }

  @override
  List<Object?> get props => [
    submissionStatus, isValid, isValidating, isDirty, isTouched,
    wasSubmitted, values, submissionError, extra,
  ]; // extraReset / isExtraBusy are behavior config, not data — excluded
}
```

`copyWith` and `reset` never expose `extraReset`/`isExtraBusy` as overridable
parameters — they are fixed at construction (set once when the bloc builds
its initial state) and simply carried through unchanged on every copy.

**Controls-changed updates never touch `extra`.** `MkFormBloc`'s
`_onRootGroupChanged` handler (fired on every field edit) calls
`onUpdateFormState(state, isValid:, isValidating:, isDirty:, isTouched:,
values:, submissionStatus:, submissionError:)` — it never passes `extra:`.
Because `copyWith` uses `extra ?? this.extra`, the omitted case keeps the
**same `extra` reference**: no rebuild, no allocation, and
`Equatable`/`buildWhen` correctly report no change in the extras portion of
state on a field edit. Only an explicit `updateExtra`/`copyWith(extra: ...)`
call, or `reset()` (via `extraReset`), ever changes `extra`.

### 2. `MkFormBloc<T extends Object?>`

```dart
abstract class MkFormBloc<T extends Object?> extends Cubit<MkFormState<T>> {
  MkFormBloc({
    Map<String, MkControlBloc<dynamic>>? controls,
    MkFormState<T>? initialState,
  }) : _rootGroup = MkGroupBloc(controls ?? {}),
       super(
         initialState ??
             MkFormState<T>(
               submissionStatus: const MkSubmissionStatus.idle(),
               isValid: controls?.values.every((c) => c.isValid) ?? true,
               isValidating: controls?.values.any((c) => c.isValidating) ?? false,
               isDirty: controls?.values.any((c) => c.isDirty) ?? false,
               isTouched: controls?.values.any((c) => c.isTouched) ?? false,
               wasSubmitted: false,
               values: {
                 for (final e in (controls ?? const {}).entries) e.key: e.value.value,
               },
               extra: null as T, // see "Residual casts" below
             ),
       );
  ...
}
```

`state` is inherited directly from `Cubit<MkFormState<T>>` — already exactly
`MkFormState<T>`. No override, no cast, in any app-level bloc.

- Plain (no-extras) blocs need **zero changes**:
  `class LoginFormBloc extends MkFormBloc { ... }` — omitting the type
  argument compiles via Dart's "instantiate to bound" rule (`T` → `Object?`),
  exactly as it does today for a non-generic class.
- A bloc with typed extras writes one type argument and nothing else:
  `class ProfileFormBloc extends MkFormBloc<ProfileExtras> { ... }`, passing
  `initialState: MkFormState<ProfileExtras>(..., extra: const ProfileExtras(),
  extraReset: () => const ProfileExtras(), isExtraBusy: (e) => e.isBusy)`.
  `state.extra` is already typed `ProfileExtras`.

This does not reopen the "no `MkFormBloc<S>`" rejection from the 2026-09-21
spec. That rejection was specifically about making the **widget**
(`MkFormBuilder<S>`) generic, where `S` would appear only in an unannotated
closure parameter position and Dart cannot infer it. Here, `T` is always
supplied explicitly by the app at the class-declaration site
(`extends MkFormBloc<ProfileExtras>`), never inferred from a closure, so that
failure mode does not apply. `MkFormBuilder` and `MkFormStateBuilder<S>` are
unchanged: raw `MkFormBloc`/`MkFormState` (no type argument) instantiate to
`MkFormBloc<Object?>`/`MkFormState<Object?>` via the same bound-default rule,
which is exactly the type `MkFormBuilder` already assumes.

### 3. `MkStepFormState<T extends Object?>` / `MkStepFormBloc<T extends Object?>`

Same generic slot, added to the step-tracking state, written once in the
library:

```dart
class MkStepFormState<T extends Object?> extends MkFormState<T> {
  const MkStepFormState({
    required super.submissionStatus, required super.isValid,
    required super.isValidating, required super.isDirty,
    required super.isTouched, required super.wasSubmitted,
    required super.values, super.submissionError,
    required super.extra, super.extraReset, super.isExtraBusy,
    required this.currentStep, required this.totalSteps,
    required this.completedSteps, this.isLoadingInitialData = false,
    this.redirectedFromStep, this.invalidStepIndex,
  });

  // currentStep, totalSteps, completedSteps, isLoadingInitialData,
  // redirectedFromStep, invalidStepIndex, and their getters: unchanged.

  @override
  MkStepFormState<T> copyWith({
    ...same base optional params as MkFormState.copyWith, plus T? extra...,
    int? currentStep, int? totalSteps, Set<int>? completedSteps,
    bool? isLoadingInitialData, int? Function()? redirectedFromStep,
    int? Function()? invalidStepIndex,
  }) => MkStepFormState<T>(...);

  @override
  MkStepFormState<T> reset({
    required bool isValid, required bool isValidating,
    required Map<String, dynamic> values,
  }) => (super.reset(isValid: isValid, isValidating: isValidating, values: values)
          as MkStepFormState<T>)
      .copyWith(currentStep: 0, completedSteps: const {},
          isLoadingInitialData: false, redirectedFromStep: () => null,
          invalidStepIndex: () => null);
}
```

```dart
abstract class MkStepFormBloc<T extends Object?> extends MkFormBloc<T> {
  MkStepFormBloc({
    required Map<String, MkControlBloc<dynamic>> controls,
    required List<MkFormStep> steps,
    int initialStep = 0,
    T Function()? initialExtra,
    T Function()? extraReset,
    bool Function(T extra)? isExtraBusy,
  }) : _steps = List.unmodifiable(steps),
       super(
         controls: controls,
         initialState: _buildInitialState<T>(
           controls, steps, initialStep, initialExtra, extraReset, isExtraBusy,
         ),
       );

  static MkStepFormState<T> _buildInitialState<T extends Object?>(
    Map<String, MkControlBloc<dynamic>> controls,
    List<MkFormStep> steps,
    int initialStep,
    T Function()? initialExtra,
    T Function()? extraReset,
    bool Function(T extra)? isExtraBusy,
  ) {
    final validInitialStep = steps.isEmpty ? 0 : initialStep.clamp(0, steps.length - 1);
    return MkStepFormState<T>(
      submissionStatus: const MkSubmissionStatus.idle(),
      isValid: controls.values.every((c) => c.isValid),
      isValidating: controls.values.any((c) => c.isValidating),
      isDirty: controls.values.any((c) => c.isDirty),
      isTouched: controls.values.any((c) => c.isTouched),
      wasSubmitted: false,
      values: {for (final e in controls.entries) e.key: e.value.value},
      extra: initialExtra != null ? initialExtra() : null as T,
      extraReset: extraReset,
      isExtraBusy: isExtraBusy,
      currentStep: validInitialStep,
      totalSteps: steps.length,
      completedSteps: const {},
    );
  }

  @override
  MkStepFormState<T> get state => super.state as MkStepFormState<T>;

  // currentStep, totalSteps, validateStep, nextStep, previousStep, goToStep,
  // loadInitialData: unchanged (all go through `state.copyWith(...)`, which
  // already preserves `extra` because none of these call sites pass it).
}
```

`MkStepFormBloc` needs its own `initialExtra`/`extraReset`/`isExtraBusy`
constructor parameters (not just a plain `MkFormBloc<T>`-style `initialState`
override) because it *always* builds its own `MkStepFormState<T>` — a
subclass has no other way to supply a non-default `extra` for a step form. A
`class OnboardingBloc extends MkStepFormBloc<OnboardingExtra>` that omits
these (like a no-extras step form) hits the same `null as T` fallback as
`MkFormBloc`, documented below.

Note this also fixes a constructor-shape mistake earlier in this section:
`controls` cannot be declared via `required super.controls` shorthand *and*
also referenced by name inside an explicit `super(...)` call in the same
initializer list — it must be its own named parameter, exactly as
`MkFormBloc`'s constructor already declares `controls` today.

`onUpdateFormState`'s override in `MkStepFormBloc` is **deleted**. The base
`MkFormBloc.onUpdateFormState` already does `currentState.copyWith(...)`,
which dispatches virtually to `MkStepFormState<T>.copyWith` at runtime
(covariant return type), preserving every step field automatically. The
override was redundant even before this change — it repeated the exact same
call the base class already makes.

`MkSimpleStepFormBloc<T extends Object?> extends MkStepFormBloc<T>` picks up
the type parameter; existing raw (no-extras) callers are unaffected.

### Residual casts (unavoidable, library-internal only)

Three casts remain, all inside the library, none in application code:

1. `MkFormBloc`'s constructor, when `initialState` is omitted: `extra: null
   as T`. Only exercised in practice for `T = Object?` (plain forms); a
   custom `T` that isn't nullable must pass `initialState` explicitly — if it
   doesn't, this cast throws immediately at construction, the same
   fail-fast behavior `MkFormStateBuilder` already uses for a type mismatch.
2. `MkStepFormBloc<T>.state`, narrowing `MkFormState<T>` (from
   `Cubit<MkFormState<T>>`) to `MkStepFormState<T>` so `currentStep`,
   `totalSteps` etc. are accessible. One override, written once.
3. `MkStepFormState<T>.reset()`, narrowing `super.reset()`'s declared
   `MkFormState<T>` return (a `copyWith` covariant-return call that is a
   `MkStepFormState<T>` at runtime, but not at that call's static type) back
   to `MkStepFormState<T>` before applying step-specific resets.

No cast exists anywhere in `MkFormBuilder`, `MkFormStateBuilder<S>`, or any
app-authored bloc/state.

## Error handling and lifecycle

Unchanged from the 2026-09-21 design: all emits go through `MkFormBloc.emit`'s
`isClosed` guard; `MkFormStateBuilder<S>`'s wrong-type `StateError` remains a
programmer-error path, not a runtime concern for correctly typed usage.

## Testing (existing tests in `test/blocs` and `test/ui` must still pass)

- `MkFormState<T>.reset()` restores `extra` via `extraReset` when provided,
  and leaves it unchanged when `extraReset` is omitted.
- `isBusy` reflects `isExtraBusy(extra)` when provided; defaults to
  `isSubmitting` alone when omitted.
- **A field edit (`_onRootGroupChanged`) leaves `extra` reference-identical**
  (`identical(before.extra, after.extra)`) — this is the new guarantee this
  redesign must not regress.
- `MkStepFormState<T>.reset()` returns to step 0 with nothing completed, and
  still applies `extraReset` for the extras portion.
- A bloc tracking two concurrent calls via `updateExtra` emits independent,
  correctly-typed status transitions.
- Raw usage (`class LoginFormBloc extends MkFormBloc { ... }`,
  `MkFormBuilder(...)`) still compiles and behaves exactly as before the
  change, with no type argument required anywhere.
- `class ProfileFormBloc extends MkFormBloc<ProfileExtras>` compiles with no
  `state` override and no cast anywhere in the file.
- `dart analyze` and `flutter test` are clean before completion is claimed.

## Docs and example

- `example/lib/presentation/features/extended_state/bloc/profile_form_state.dart`
  is deleted. `ProfileFormBloc extends MkFormBloc<ProfileExtras>`;
  `profile_extras.dart` (the freezed class) is unchanged.
- README "Extending form state" section rewritten around `MkFormState<T>`
  instead of subclassing.
- CHANGELOG 1.1.0 entry rewritten to describe the generic mechanism.
- The 2026-09-21 spec/plan docs are superseded by this document; leave them
  in place as history (git already records the sequence) rather than editing
  them retroactively.

## Release

Additive relative to 1.0.1 (the subclassing design was never published, so
there is nothing to deprecate). Version 1.1.0. Bumping the version and
publishing are left to the maintainer.
