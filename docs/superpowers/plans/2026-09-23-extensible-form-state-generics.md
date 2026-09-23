# Generic MkFormState<T> Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace subclassing `MkFormState` with a generic `extra` slot (`MkFormState<T>`), so apps that need typed status fields stop writing a subclass (constructor, `copyWith`, `reset`, `props`) and just parameterize `MkFormState<T>` / `MkFormBloc<T>` directly.

**Architecture:** `MkFormState<T extends Object?>` gains one field, `extra` (type `T`), plus two construction-only behavior hooks (`extraReset`, `isExtraBusy`). `MkFormBloc<T extends Object?>` becomes generic so `state` is already `MkFormState<T>` with no downcast. `MkStepFormState<T>` / `MkStepFormBloc<T>` get the same treatment. Every existing "no extras" form (the vast majority) needs zero source changes: omitting the type argument compiles via Dart's instantiate-to-bound rule (`T` → `Object?`).

**Tech Stack:** Dart 3.9 / Flutter 3.41, `package:equatable`, `package:flutter_bloc` (`Cubit`). No new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-23-extensible-form-state-generics-design.md`

## Global Constraints

- Dart SDK `>=3.9.0 <4.0.0`, Flutter `>=3.41.0` — unchanged, from `pubspec.yaml`.
- No new dependency in `lib`'s `pubspec.yaml` (no codegen/freezed in the core package).
- This replaces the unreleased 2026-09-21 subclassing design outright — no deprecation shim, no back-compat path. Current published version is 1.0.1; 1.1.0 has never shipped.
- Every pre-existing raw usage (`class Foo extends MkFormBloc { ... }`, `MkFormBuilder(...)`, `BlocBuilder<MkFormBloc, MkFormState>`, etc.) must keep compiling and passing **unmodified**.
- Field edits (`MkFormBloc._onRootGroupChanged`) must never replace the `extra` object reference — `identical(before.extra, after.extra)` must hold across any pure control-value edit.
- Only three `as` casts are allowed anywhere in `lib/`, all listed in the spec's "Residual casts" section (`MkFormBloc`'s `null as T` fallback, `MkStepFormBloc.state`, `MkStepFormState.reset`). No other cast — in `lib/`, `test/`, or `example/` — should exist after this plan; if a task's code needs one beyond those three, stop and reconsider the approach instead of adding it.
- `dart analyze` and `flutter test` must be clean, from **both** the repo root and `example/`, before any task is considered done.
- Commit messages follow this repo's existing convention: `type(scope): summary` (see `git log`), no trailing attribution/co-author line.

## Review Focus

- A `MkFormBloc<T>` / `MkStepFormBloc<T>` subclass with a non-nullable `T` that omits `initialState` (or, for step forms, `initialExtra`) hits the documented `null as T` fallback and must throw immediately and clearly at construction, not silently store a broken `extra` — pinned in Task 2 and Task 6.
- `extra`'s own equality now feeds `MkFormState.==`/`props` directly (previously a subclass flattened its custom fields into `props` itself). An `extra` type without value equality (`==`/`hashCode`, `Equatable`, or a freezed class) makes state equality fall back to identity, silently breaking `buildWhen` dedup for anyone who copies the pattern without noticing — documented in Task 8 and dogfooded with `Equatable` in the Task 3 test support.
- Field edits must leave `extra` reference-identical (no rebuild, no reallocation) — pinned with an explicit `identical()` assertion in Task 3, not just an "equal by value" assertion, which would pass even if a bug allocated a new-but-equal `extra` on every edit.
- Every existing raw (no type argument) form — the library's own `test/blocs/form_bloc_test.dart`, `form_bloc_regression_test.dart`, `step_form_bloc_test.dart`, and the example's `autovalidate_demo`/`minimal_login` screens — must keep compiling and passing with **zero source changes**; this is checked at the end of Task 2 and Task 5 by running the existing suites unmodified.
- `MkStepFormState.reset()` must correctly regenerate `extra` via `extraReset` *and* reset step fields in the same call, now that a step form can carry extras too — pinned by the Task 6 combo test's `reset()` assertion.

---

## File Structure

**Library (`lib/src/blocs/form/`):**
- `form_state.dart` — `MkFormState` becomes generic. Rewritten.
- `form_bloc.dart` — `MkFormBloc` becomes generic. Rewritten.
- `step_form_state.dart` — `MkStepFormState` becomes generic. Rewritten.
- `step_form_bloc.dart` — `MkStepFormBloc` / `MkSimpleStepFormBloc` become generic; redundant `onUpdateFormState` override deleted. Rewritten.
- `simple_form_bloc.dart` — **no changes** (raw `extends MkFormBloc` still compiles as `MkFormBloc<Object?>`).
- `lib/src/ui/form_builder.dart`, `lib/src/ui/form_listener.dart`, `lib/src/ui/form_scope.dart` — **no changes** (all use bare `MkFormState`/`MkFormBloc`, which resolve via instantiate-to-bound; verified by `dart analyze` at the end of Task 2).

**Tests:**
- `test/support/profile_form.dart` — rewritten: `ProfileState` subclass replaced by a plain `ProfileExtra` (`Equatable`) class and `ProfileBloc extends MkFormBloc<ProfileExtra>`.
- `test/blocs/extensible_state_test.dart` — updated to the new shape; adds the identity-preservation test.
- `test/blocs/form_state_test.dart` — **new**: direct unit tests of `MkFormState<T>` (no bloc involved).
- `test/ui/form_builder_test.dart` — updated: `MkFormStateBuilder<ProfileState>` → `MkFormStateBuilder<MkFormState<ProfileExtra>>`.
- `test/blocs/step_form_extras_test.dart` — **new**: a step form combining step tracking with typed extras.

**Example:**
- `example/lib/presentation/features/extended_state/bloc/profile_form_state.dart` — **deleted**.
- `example/lib/presentation/features/extended_state/bloc/profile_extras.dart` — **no changes** (the freezed class itself is unaffected).
- `example/lib/presentation/features/extended_state/bloc/profile_form_bloc.dart` — rewritten to `MkFormBloc<ProfileExtras>`; gains an extension with the two derived getters that used to live on `ProfileFormState`.
- `example/lib/presentation/features/extended_state/extended_state_screen.dart` — updated: `MkFormStateBuilder<ProfileFormState>` → `MkFormStateBuilder<MkFormState<ProfileExtras>>`, `.extras` → `.extra`.
- `example/test/profile_form_bloc_test.dart` — updated: `.extras` → `.extra`.
- `example/test/extended_state_screen_test.dart` — **no changes** (asserts on rendered text only).

**Docs:**
- `README.md` — "Extending Form State" section rewritten.
- `CHANGELOG.md` — 1.1.0 entry rewritten.

---

### Task 1: `MkFormState<T>` core rewrite

**Files:**
- Modify: `lib/src/blocs/form/form_state.dart`
- Test: `test/blocs/form_state_test.dart` (create)

**Interfaces:**
- Produces: `class MkFormState<T extends Object?> extends Equatable` with fields `submissionStatus`, `isValid`, `isValidating`, `isDirty`, `isTouched`, `wasSubmitted`, `values`, `submissionError`, `extra` (type `T`), and `@protected` fields `extraReset` (`T Function()?`) and `isExtraBusy` (`bool Function(T extra)?`). Methods: `copyWith({..., T? extra})`, `reset({required isValid, required isValidating, required values})`, `updateExtra(T Function(T) update)`, getters `canSubmit`, `isBusy`, `isSubmitting`, `isSuccess`, `isFailure`.

- [ ] **Step 1: Replace `lib/src/blocs/form/form_state.dart`**

```dart
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../../core/status.dart';

/// Represents the overall state of an [MkFormBloc].
///
/// [T] is the type of [extra]: a single slot for whatever a form needs
/// beyond the base fields (independent statuses, extra data). Most forms
/// never need it and can ignore the type parameter entirely — plain
/// `MkFormState` (no type argument) resolves to `MkFormState<Object?>` with
/// `extra` left `null`.
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

  /// Current submission lifecycle status (idle, submitting, success, failure).
  final MkSubmissionStatus submissionStatus;

  /// Whether all fields in the form are valid.
  final bool isValid;

  /// Whether any field in the form is performing asynchronous validation.
  final bool isValidating;

  /// Whether any field has been modified from its initial value.
  final bool isDirty;

  /// Whether any field has been touched.
  final bool isTouched;

  /// Whether the user has attempted to submit the form at least once.
  final bool wasSubmitted;

  /// Aggregated values of all controls in the form.
  final Map<String, dynamic> values;

  /// The error object if the last submission failed, or null.
  final Object? submissionError;

  /// App-defined payload: statuses and extra fields beyond the base ones.
  ///
  /// Field edits never touch this: [MkFormBloc] only calls [copyWith] with
  /// the base fields, so the same [extra] instance carries through every
  /// edit untouched. Update it explicitly with [updateExtra] or `copyWith`.
  final T extra;

  /// Regenerates a pristine [extra] on [reset]. If omitted, [reset] leaves
  /// [extra] unchanged.
  ///
  /// Marked `@protected`: part of the constructor's public surface (an app
  /// sets it once when building its bloc's initial state) but not meant to
  /// be read outside a state's own `copyWith`/`reset` chain. It is a plain
  /// (non-underscore) field rather than Dart-private, because
  /// `MkStepFormState` (a different file/library) must read it from its own
  /// `copyWith`/`reset` overrides — Dart privacy is per-library.
  @protected
  final T Function()? extraReset;

  /// Feeds [isBusy]. If omitted, [extra] never contributes to [isBusy].
  /// Same visibility rationale as [extraReset].
  @protected
  final bool Function(T extra)? isExtraBusy;

  /// Whether the form can currently be submitted.
  bool get canSubmit => isValid && !isValidating && !isBusy;

  /// Whether the form is busy and must not accept another submission.
  ///
  /// Defaults to [isSubmitting] plus whatever [isExtraBusy] reports for
  /// [extra].
  bool get isBusy => isSubmitting || (isExtraBusy?.call(extra) ?? false);

  /// Shorthand getters for submission states.
  bool get isSubmitting => submissionStatus.isSubmitting;
  bool get isSuccess => submissionStatus.isSuccess;
  bool get isFailure => submissionStatus.isFailure;

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

  /// Returns an idle, pristine copy of this state.
  ///
  /// Used by [MkFormBloc.reset]. [extra] is regenerated via [extraReset], or
  /// left unchanged if none was given.
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
    submissionStatus,
    isValid,
    isValidating,
    isDirty,
    isTouched,
    wasSubmitted,
    values,
    submissionError,
    extra,
  ];
}
```

- [ ] **Step 2: Write `test/blocs/form_state_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

MkFormState<int> _state({
  int extra = 0,
  int Function()? extraReset,
  bool Function(int)? isExtraBusy,
}) {
  return MkFormState<int>(
    submissionStatus: const MkSubmissionStatus.idle(),
    isValid: true,
    isValidating: false,
    isDirty: false,
    isTouched: false,
    wasSubmitted: false,
    values: const {},
    extra: extra,
    extraReset: extraReset,
    isExtraBusy: isExtraBusy,
  );
}

void main() {
  group('MkFormState<T>', () {
    test('extra defaults to null for the untyped base case', () {
      const state = MkFormState<Object?>(
        submissionStatus: MkSubmissionStatus.idle(),
        isValid: true,
        isValidating: false,
        isDirty: false,
        isTouched: false,
        wasSubmitted: false,
        values: {},
        extra: null,
      );
      expect(state.extra, isNull);
    });

    test('copyWith without extra: keeps the same extra reference', () {
      final state = _state(extra: 1);
      final copy = state.copyWith(isDirty: true);
      expect(identical(copy.extra, state.extra), isTrue);
      expect(copy.isDirty, isTrue);
    });

    test('copyWith(extra:) replaces extra', () {
      final state = _state(extra: 1);
      final copy = state.copyWith(extra: 2);
      expect(copy.extra, 2);
    });

    test('updateExtra applies the function to the current extra', () {
      final state = _state(extra: 1);
      final updated = state.updateExtra((e) => e + 1);
      expect(updated.extra, 2);
    });

    test('reset() regenerates extra via extraReset when provided', () {
      final state = _state(
        extra: 5,
        extraReset: () => 0,
      ).copyWith(isDirty: true);

      final reset = state.reset(
        isValid: true,
        isValidating: false,
        values: const {},
      );

      expect(reset.extra, 0);
      expect(reset.isDirty, isFalse);
    });

    test('reset() leaves extra unchanged when extraReset is omitted', () {
      final state = _state(extra: 5);
      final reset = state.reset(
        isValid: true,
        isValidating: false,
        values: const {},
      );
      expect(reset.extra, 5);
    });

    test(
      'isBusy defaults to isSubmitting alone when isExtraBusy is omitted',
      () {
        final idle = _state(extra: 1);
        expect(idle.isBusy, isFalse);

        final submitting = MkFormState<int>(
          submissionStatus: const MkSubmissionStatus.submitting(),
          isValid: true,
          isValidating: false,
          isDirty: false,
          isTouched: false,
          wasSubmitted: false,
          values: const {},
          extra: 1,
        );
        expect(submitting.isBusy, isTrue);
      },
    );

    test('isBusy reflects isExtraBusy(extra) when provided', () {
      final busy = _state(extra: 1, isExtraBusy: (e) => e > 0);
      expect(busy.isBusy, isTrue);
      expect(busy.canSubmit, isFalse);

      final idle = _state(extra: 0, isExtraBusy: (e) => e > 0);
      expect(idle.isBusy, isFalse);
    });

    test(
      'props includes extra, so states with different extras are unequal',
      () {
        expect(_state(extra: 1), isNot(equals(_state(extra: 2))));
        expect(_state(extra: 1), equals(_state(extra: 1)));
      },
    );
  });
}
```

- [ ] **Step 3: Run the new test**

Run: `flutter test test/blocs/form_state_test.dart`
Expected: PASS (9 tests).

- [ ] **Step 4: Run static analysis on the library**

Run: `dart analyze lib`
Expected: `No issues found!` — this will not yet be true if other files still reference the old non-generic `MkFormState`; if `form_bloc.dart` fails to analyze at this point, that's expected until Task 2. Confirm the *error* is confined to files this task hasn't touched yet (`form_bloc.dart`, `step_form_state.dart`, `step_form_bloc.dart`) and `form_state.dart` itself has no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/src/blocs/form/form_state.dart test/blocs/form_state_test.dart
git commit -m "feat(state): make MkFormState generic over a typed extra field"
```

---

### Task 2: `MkFormBloc<T>` rewrite

**Files:**
- Modify: `lib/src/blocs/form/form_bloc.dart`
- Test: existing `test/blocs/form_bloc_test.dart`, `test/blocs/form_bloc_regression_test.dart` (must pass **unmodified**)

**Interfaces:**
- Consumes: `MkFormState<T>` from Task 1 (`extra`, `copyWith`, `reset`).
- Produces: `abstract class MkFormBloc<T extends Object?> extends Cubit<MkFormState<T>>`. `state` is inherited (no override needed by any subclass). `field<F>(String name)` (renamed from `field<T>` to avoid shadowing the class's own `T`).

- [ ] **Step 1: Replace `lib/src/blocs/form/form_bloc.dart`**

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/deep_equals.dart';
import '../../core/status.dart';
import '../control_bloc.dart';
import '../field/field_bloc.dart';
import '../group/group_bloc.dart';
import 'form_state.dart';

/// Abstract or standalone coordinator bloc managing the form lifecycle.
///
/// [T] is the type of [MkFormState.extra]; most forms never need it and can
/// extend `MkFormBloc` (no type argument) exactly as before. A form that
/// wants typed extra fields extends `MkFormBloc<MyExtras>` and passes
/// `initialState: MkFormState<MyExtras>(...)`.
///
/// Handles:
/// - Aggregated validation across all controls.
/// - Submission flow with automatic validation gating.
/// - Clear submission error lifecycle (automatically clears submission error
///   when the user modifies any field, preventing repeated error banners).
/// - Server error mapping to field controls via [setFieldErrors].
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
               isValidating:
                   controls?.values.any((c) => c.isValidating) ?? false,
               isDirty: controls?.values.any((c) => c.isDirty) ?? false,
               isTouched: controls?.values.any((c) => c.isTouched) ?? false,
               wasSubmitted: false,
               values: {
                 for (final entry in (controls ?? const {}).entries)
                   entry.key: entry.value.value,
               },
               // Only reached by forms that don't need typed extras (T is
               // Object?, so null is a valid value); a bloc with a real
               // extras type must always pass `initialState` explicitly, as
               // it must today for a subclassed state. See the "Residual
               // casts" section of the design spec.
               extra: null as T,
             ),
       ) {
    _initControlListeners();
  }

  final MkGroupBloc _rootGroup;
  bool _isSubmitInFlight = false;

  /// The root control group containing all registered controls.
  MkGroupBloc get root => _rootGroup;

  /// Map of all controls in the form.
  Map<String, MkControlBloc<dynamic>> get controls => _rootGroup.controls;

  /// Aggregated map of form values.
  Map<String, dynamic> get values => _rootGroup.value;

  /// Retrieves a registered control by [name].
  C? control<C extends MkControlBloc<dynamic>>(String name) =>
      _rootGroup.control<C>(name);

  /// Retrieves a registered [MkFieldBloc<F>] by [name].
  MkFieldBloc<F>? field<F>(String name) => _rootGroup.field<F>(name);

  /// Registers a control dynamically.
  void registerControl(String name, MkControlBloc<dynamic> control) {
    _rootGroup.addControl(name, control);
  }

  /// Removes a registered control.
  void unregisterControl(String name) {
    _rootGroup.removeControl(name);
  }

  /// Emitting after [close] is a silent no-op, so submissions or validations
  /// that finish after the form was disposed cannot throw.
  @protected
  @override
  void emit(MkFormState<T> state) {
    if (isClosed) return;
    super.emit(state);
  }

  void _initControlListeners() {
    _rootGroup.addStateListener(_onRootGroupChanged);
  }

  void _onRootGroupChanged() {
    if (isClosed) return;
    final groupState = _rootGroup.state;

    // When the user edits any field after a failed submission, clear the
    // submission error so the user doesn't see persistent/repeated error
    // banners. Only actual value changes count: touching a field, or mapping
    // server errors onto fields via [setFieldErrors], must keep the failure.
    final shouldClearSubmissionError =
        state.isFailure && !mkDeepEquals(state.values, groupState.values);

    emit(
      onUpdateFormState(
        state,
        isValid: groupState.isValid,
        isValidating: groupState.isValidating,
        isDirty: groupState.isDirty,
        isTouched: groupState.isTouched,
        values: groupState.values,
        submissionStatus: shouldClearSubmissionError
            ? const MkSubmissionStatus.idle()
            : state.submissionStatus,
        submissionError: shouldClearSubmissionError ? () => null : null,
      ),
    );
  }

  /// Hook for subclasses to customize how control changes update the state.
  ///
  /// The base implementation calls [MkFormState.copyWith], which dispatches
  /// virtually to the runtime type's `copyWith` override — so a state
  /// subclass such as [MkStepFormState] never needs to override this to
  /// preserve its own fields. `extra` is never passed here, so it is always
  /// preserved untouched across control edits.
  @protected
  MkFormState<T> onUpdateFormState(
    MkFormState<T> currentState, {
    required bool isValid,
    required bool isValidating,
    required bool isDirty,
    required bool isTouched,
    required Map<String, dynamic> values,
    required MkSubmissionStatus submissionStatus,
    required Object? Function()? submissionError,
  }) {
    return currentState.copyWith(
      isValid: isValid,
      isValidating: isValidating,
      isDirty: isDirty,
      isTouched: isTouched,
      values: values,
      submissionStatus: submissionStatus,
      submissionError: submissionError,
    );
  }

  /// Manually clears any active submission error.
  void clearSubmissionError() {
    if (isClosed || state.submissionError == null) return;
    emit(
      state.copyWith(
        submissionStatus: const MkSubmissionStatus.idle(),
        submissionError: () => null,
      ),
    );
  }

  /// Sets errors returned from a backend/server response onto individual fields.
  ///
  /// For example: `setFieldErrors({'email': 'Email is already taken'})`.
  void setFieldErrors(Map<String, String> fieldErrors) {
    for (final entry in fieldErrors.entries) {
      final f = field<dynamic>(entry.key);
      if (f != null) {
        f.setError(entry.value);
        f.touch();
      }
    }
  }

  /// Submits the form.
  ///
  /// 1. Prevents duplicate submissions if already submitting.
  /// 2. Touches all fields and marks [wasSubmitted] = true.
  /// 3. Validates all synchronous and asynchronous controls.
  /// 4. If invalid, halts submission.
  /// 5. If valid, invokes [onSubmit] and handles success/failure.
  Future<void> submit() async {
    // `state.isSubmitting` only flips once validation has finished, so a
    // dedicated flag is needed to reject calls made while validating.
    // `state.isBusy` also covers extra-defined in-flight work.
    if (isClosed || _isSubmitInFlight || state.isBusy) return;
    _isSubmitInFlight = true;
    try {
      await _submit();
    } finally {
      _isSubmitInFlight = false;
    }
  }

  Future<void> _submit() async {
    // Mark submitted across all fields so errors become visible to user
    emit(state.copyWith(wasSubmitted: true));
    _rootGroup.markFormSubmitted();
    _rootGroup.touch();

    // Validate all controls
    final isValid = await _rootGroup.validate();
    if (!isValid || isClosed) {
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: const MkSubmissionStatus.submitting(),
        submissionError: () => null,
      ),
    );

    try {
      final response = await onSubmit(values);
      if (!isClosed) {
        emit(
          state.copyWith(
            submissionStatus: MkSubmissionStatus.success(response),
            submissionError: () => null,
          ),
        );
        onSubmitSuccess(response);
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            submissionStatus: MkSubmissionStatus.failure(error),
            submissionError: () => error,
          ),
        );
        onSubmitFailure(error);
      }
    }
  }

  /// Method to be overridden by subclasses or custom implementations
  /// containing the async submit logic (API call, database write, etc.).
  Future<dynamic> onSubmit(Map<String, dynamic> values);

  /// Callback hook invoked when submission succeeds.
  void onSubmitSuccess(dynamic response) {}

  /// Callback hook invoked when submission fails.
  void onSubmitFailure(Object error) {}

  /// Populates the form controls with [data] (e.g. from an API response or draft).
  ///
  /// If [markPristine] is `true`, values are applied as new initial values,
  /// keeping controls pure and resetting dirty/touched states so no premature errors appear.
  /// If [markPristine] is `false`, values are applied via `changeValue`.
  void populateValues(Map<String, dynamic> data, {bool markPristine = true}) {
    for (final entry in data.entries) {
      final ctrl = control<MkControlBloc<dynamic>>(entry.key);
      if (ctrl is MkFieldBloc) {
        if (markPristine) {
          ctrl.reset(entry.value);
        } else {
          ctrl.changeValue(entry.value);
        }
      } else if (ctrl is MkGroupBloc && entry.value is Map<String, dynamic>) {
        for (final subEntry in (entry.value as Map<String, dynamic>).entries) {
          final subCtrl = ctrl.control<MkControlBloc<dynamic>>(subEntry.key);
          if (subCtrl is MkFieldBloc) {
            if (markPristine) {
              subCtrl.reset(subEntry.value);
            } else {
              subCtrl.changeValue(subEntry.value);
            }
          }
        }
      }
    }
  }

  /// Touches and validates only the specified [groupName] (subform).
  ///
  /// Useful for multi-section forms (e.g. shipping address before billing address)
  /// without triggering validation errors on unrelated controls.
  Future<bool> validateGroup(String groupName) async {
    final grp = control<MkGroupBloc>(groupName);
    if (grp == null) return true;
    grp.touch();
    grp.markFormSubmitted();
    return grp.validate();
  }

  /// Touches and validates only a specific subset of [controlNames].
  Future<bool> validateControls(Iterable<String> controlNames) async {
    final targets = <MkControlBloc<dynamic>>[];
    for (final name in controlNames) {
      final c = control<MkControlBloc<dynamic>>(name);
      if (c != null) {
        targets.add(c);
        c.touch();
        c.markFormSubmitted();
      }
    }
    final results = await Future.wait(targets.map((c) => c.validate()));
    return results.every((valid) => valid);
  }

  /// Resets the form and all its controls to their initial states.
  ///
  /// `extra` is preserved (or regenerated via `extraReset`) through
  /// [MkFormState.reset].
  void reset() {
    _rootGroup.reset();
    emit(
      state.reset(
        isValid: _rootGroup.isValid,
        isValidating: _rootGroup.isValidating,
        values: _rootGroup.value,
      ),
    );
  }

  @override
  Future<void> close() async {
    _rootGroup.removeStateListener(_onRootGroupChanged);
    await _rootGroup.close();
    return super.close();
  }
}
```

- [ ] **Step 2: Run static analysis on the library**

Run: `dart analyze lib`
Expected: errors remain only in `step_form_state.dart` / `step_form_bloc.dart` (not yet updated); `form_state.dart` and `form_bloc.dart` must be clean.

- [ ] **Step 3: Run the existing form-bloc suites unmodified**

Run: `flutter test test/blocs/form_bloc_test.dart test/blocs/form_bloc_regression_test.dart`
Expected: all PASS, with no source changes to either test file — this is the "raw usage still compiles and behaves identically" check from Global Constraints.

- [ ] **Step 4: Add a construction-time failure test for the residual cast**

Append to `test/blocs/form_bloc_test.dart` (inside the existing `group('MkFormBloc', () { ... })`, alongside the other tests):

```dart
    test(
      'a non-nullable T without an explicit initialState throws at construction',
      () {
        expect(() => TestTypedFormBloc(), throwsA(isA<TypeError>()));
      },
    );
```

And above `void main() {`, add the helper class used by that test:

```dart
class TestTypedFormBloc extends MkFormBloc<String> {
  TestTypedFormBloc() : super(controls: const {});

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async => null;
}
```

- [ ] **Step 5: Run the updated test file**

Run: `flutter test test/blocs/form_bloc_test.dart`
Expected: all PASS, including the new construction-failure test.

- [ ] **Step 6: Commit**

```bash
git add lib/src/blocs/form/form_bloc.dart test/blocs/form_bloc_test.dart
git commit -m "feat(state): make MkFormBloc generic over MkFormState's extra type"
```

---

### Task 3: Rewrite the extras test support and its consumers

**Files:**
- Modify: `test/support/profile_form.dart`
- Modify: `test/blocs/extensible_state_test.dart`
- Modify: `test/ui/form_builder_test.dart`

**Interfaces:**
- Consumes: `MkFormState<T>` / `MkFormBloc<T>` from Tasks 1–2.
- Produces: `class ProfileExtra extends Equatable` (`avatarStatus`, `otpStatus`, `isBusy`, `copyWith`); `class ProfileBloc extends MkFormBloc<ProfileExtra>` (`uploadAvatar()`, `sendOtp()`, `submitCalls`). No `state` override on `ProfileBloc` — it is inherited as `MkFormState<ProfileExtra>`.

- [ ] **Step 1: Replace `test/support/profile_form.dart`**

```dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:mk_forms/mk_forms.dart';

/// Extra fields held in [ProfileBloc]'s [MkFormState.extra]: two independent
/// API-call statuses.
///
/// Extends [Equatable] because `extra` feeds `MkFormState`'s own equality
/// directly — an extra type without value equality would make state
/// equality (and `buildWhen` dedup) fall back to identity.
class ProfileExtra extends Equatable {
  const ProfileExtra({
    this.avatarStatus = const MkSubmissionStatus.idle(),
    this.otpStatus = const MkSubmissionStatus.idle(),
  });

  final MkSubmissionStatus avatarStatus;
  final MkSubmissionStatus otpStatus;

  bool get isBusy => avatarStatus.isSubmitting || otpStatus.isSubmitting;

  ProfileExtra copyWith({
    MkSubmissionStatus? avatarStatus,
    MkSubmissionStatus? otpStatus,
  }) {
    return ProfileExtra(
      avatarStatus: avatarStatus ?? this.avatarStatus,
      otpStatus: otpStatus ?? this.otpStatus,
    );
  }

  @override
  List<Object?> get props => [avatarStatus, otpStatus];
}

/// A form bloc whose two side calls are driven by test-controlled completers.
class ProfileBloc extends MkFormBloc<ProfileExtra> {
  ProfileBloc({Completer<void>? avatarUpload, Completer<void>? otpSend})
    : this._(avatarUpload, otpSend, {
        'name': MkFieldBloc<String>(
          initialValue: '',
          validators: [MkValidators.required()],
        ),
      });

  ProfileBloc._(
    this._avatarUpload,
    this._otpSend,
    Map<String, MkControlBloc<dynamic>> controls,
  ) : super(
        controls: controls,
        initialState: MkFormState<ProfileExtra>(
          submissionStatus: const MkSubmissionStatus.idle(),
          isValid: controls.values.every((c) => c.isValid),
          isValidating: controls.values.any((c) => c.isValidating),
          isDirty: controls.values.any((c) => c.isDirty),
          isTouched: controls.values.any((c) => c.isTouched),
          wasSubmitted: false,
          values: {
            for (final entry in controls.entries)
              entry.key: entry.value.value,
          },
          extra: const ProfileExtra(),
          extraReset: () => const ProfileExtra(),
          isExtraBusy: (e) => e.isBusy,
        ),
      );

  final Completer<void>? _avatarUpload;
  final Completer<void>? _otpSend;
  int submitCalls = 0;

  Future<void> uploadAvatar() => _track(
    _avatarUpload!,
    (status) => state.updateExtra((e) => e.copyWith(avatarStatus: status)),
  );

  Future<void> sendOtp() => _track(
    _otpSend!,
    (status) => state.updateExtra((e) => e.copyWith(otpStatus: status)),
  );

  Future<void> _track(
    Completer<void> call,
    MkFormState<ProfileExtra> Function(MkSubmissionStatus status) apply,
  ) async {
    emit(apply(const MkSubmissionStatus.submitting()));
    try {
      await call.future;
      emit(apply(const MkSubmissionStatus.success()));
    } catch (error) {
      emit(apply(MkSubmissionStatus.failure(error)));
    }
  }

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    submitCalls++;
    return 'ok';
  }
}
```

- [ ] **Step 2: Replace `test/blocs/extensible_state_test.dart`**

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../support/profile_form.dart';

void main() {
  group('MkFormState<T> extras', () {
    test('reset preserves the extra type and resets custom fields', () {
      final bloc = ProfileBloc(avatarUpload: Completer<void>());
      addTearDown(bloc.close);

      unawaited(bloc.uploadAvatar());
      expect(bloc.state.extra.avatarStatus.isSubmitting, isTrue);

      bloc.reset();

      expect(bloc.state.extra.avatarStatus.isIdle, isTrue);
      expect(bloc.state.extra.otpStatus.isIdle, isTrue);
      expect(bloc.state.submissionStatus.isIdle, isTrue);
    });

    test('a busy extra blocks canSubmit and submit()', () async {
      final upload = Completer<void>();
      final bloc = ProfileBloc(avatarUpload: upload);
      addTearDown(bloc.close);
      bloc.field<String>('name')!.changeValue('Ada');
      expect(bloc.state.canSubmit, isTrue);

      unawaited(bloc.uploadAvatar());
      expect(bloc.state.isBusy, isTrue);
      expect(bloc.state.canSubmit, isFalse);

      await bloc.submit();
      expect(bloc.submitCalls, 0);

      upload.complete();
      await pumpEventQueue();
      expect(bloc.state.isBusy, isFalse);
      expect(bloc.state.canSubmit, isTrue);

      await bloc.submit();
      expect(bloc.submitCalls, 1);
      expect(bloc.state.isSuccess, isTrue);
    });

    test('concurrent calls report independent statuses', () async {
      final upload = Completer<void>();
      final otp = Completer<void>();
      final bloc = ProfileBloc(avatarUpload: upload, otpSend: otp);
      addTearDown(bloc.close);

      unawaited(bloc.uploadAvatar());
      unawaited(bloc.sendOtp());
      expect(bloc.state.extra.avatarStatus.isSubmitting, isTrue);
      expect(bloc.state.extra.otpStatus.isSubmitting, isTrue);

      otp.complete();
      await pumpEventQueue();
      expect(bloc.state.extra.otpStatus.isSuccess, isTrue);
      expect(bloc.state.extra.avatarStatus.isSubmitting, isTrue);
      expect(bloc.state.isBusy, isTrue);

      upload.completeError(Exception('upload failed'));
      await pumpEventQueue();
      expect(bloc.state.extra.avatarStatus.isFailure, isTrue);
      expect(bloc.state.extra.otpStatus.isSuccess, isTrue);
      expect(bloc.state.isBusy, isFalse);
    });

    test('a control edit leaves extra reference-identical', () {
      final bloc = ProfileBloc(avatarUpload: Completer<void>());
      addTearDown(bloc.close);

      unawaited(bloc.uploadAvatar());
      final extraBeforeEdit = bloc.state.extra;

      bloc.field<String>('name')!.changeValue('Ada');

      expect(identical(bloc.state.extra, extraBeforeEdit), isTrue);
      expect(bloc.state.extra.avatarStatus.isSubmitting, isTrue);
      expect(bloc.state.values['name'], 'Ada');
    });
  });
}
```

- [ ] **Step 3: Replace `test/ui/form_builder_test.dart`**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';
import '../support/profile_form.dart';

void main() {
  group('MkFormStateBuilder<S> / MkFormBuilder', () {
    testWidgets(
      'MkFormStateBuilder delivers the custom state type and honours buildWhen',
      (tester) async {
        final upload = Completer<void>();
        final bloc = ProfileBloc(avatarUpload: upload);
        addTearDown(bloc.close);
        var filteredBuilds = 0;
        var unfilteredBuilds = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: MkFormScope.value(
              value: bloc,
              child: Column(
                children: [
                  // Filtered builder: only rebuilds when avatarStatus changes.
                  MkFormStateBuilder<MkFormState<ProfileExtra>>(
                    buildWhen: (previous, current) =>
                        previous.extra.avatarStatus !=
                        current.extra.avatarStatus,
                    builder: (context, state, formBloc) {
                      filteredBuilds++;
                      return Text(
                        state.extra.avatarStatus.isSubmitting
                            ? 'uploading'
                            : 'idle',
                      );
                    },
                  ),
                  // Unfiltered builder: rebuilds on any state change (positive control).
                  MkFormStateBuilder<MkFormState<ProfileExtra>>(
                    builder: (context, state, formBloc) {
                      unfilteredBuilds++;
                      return Text('unfiltered: $unfilteredBuilds');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        expect(find.text('idle'), findsOneWidget);
        final filteredAfterFirstFrame = filteredBuilds;
        final unfilteredAfterFirstFrame = unfilteredBuilds;

        // Not part of buildWhen: name change should deliver state but not
        // rebuild the filtered builder (avatarStatus unchanged).
        bloc.field<String>('name')!.changeValue('Ada');
        // Bloc stream delivery takes a microtask hop.
        await tester.pump();
        // Allow state emission to propagate to widgets.
        await tester.pump();
        // Prove the state actually changed.
        expect(bloc.state.values['name'], 'Ada');
        // Unfiltered builder should have rebuilt (any state change).
        expect(unfilteredBuilds, greaterThan(unfilteredAfterFirstFrame));
        // Filtered builder should NOT have rebuilt (avatarStatus unchanged).
        expect(filteredBuilds, filteredAfterFirstFrame);

        unawaited(bloc.uploadAvatar());
        // Bloc stream delivery takes a microtask hop.
        await tester.pump();
        // Allow state emission to propagate to widgets.
        await tester.pump();
        expect(find.text('uploading'), findsOneWidget);
      },
    );

    testWidgets('MkFormBuilder untyped usage still receives MkFormState', (
      tester,
    ) async {
      final bloc = MkSimpleFormBloc(
        controls: {'name': MkFieldBloc<String>(initialValue: 'x')},
        onSubmit: (values) async => null,
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MkFormScope.value(
            value: bloc,
            child: MkFormBuilder(
              buildWhen: (p, c) => p.isValid != c.isValid,
              builder: (context, state, formBloc) =>
                  Text('valid: ${state.isValid}'),
            ),
          ),
        ),
      );

      expect(find.text('valid: true'), findsOneWidget);
    });

    testWidgets(
      'MkFormStateBuilder throws a StateError when the state is not an S',
      (tester) async {
        final bloc = MkSimpleFormBloc(
          controls: {'name': MkFieldBloc<String>(initialValue: 'x')},
          onSubmit: (values) async => null,
        );
        addTearDown(bloc.close);

        await tester.pumpWidget(
          MaterialApp(
            home: MkFormScope.value(
              value: bloc,
              child: MkFormStateBuilder<MkFormState<ProfileExtra>>(
                builder: (context, state, formBloc) => const SizedBox(),
              ),
            ),
          ),
        );

        final error = tester.takeException();
        expect(error, isA<StateError>());
        expect(error.toString(), contains('MkFormState<ProfileExtra>'));
      },
    );
  });
}
```

- [ ] **Step 4: Run both test files**

Run: `flutter test test/blocs/extensible_state_test.dart test/ui/form_builder_test.dart`
Expected: all PASS.

- [ ] **Step 5: Run the full library test suite and analyzer**

Run: `flutter test && dart analyze lib`
Expected: all tests PASS; analyzer clean for every file except `step_form_state.dart`/`step_form_bloc.dart` (Tasks 4–5 not done yet) — confirm no *other* file has errors.

- [ ] **Step 6: Commit**

```bash
git add test/support/profile_form.dart test/blocs/extensible_state_test.dart test/ui/form_builder_test.dart
git commit -m "test(state): rewrite extras test support around MkFormState<T>"
```

---

### Task 4: `MkStepFormState<T>` rewrite

**Files:**
- Modify: `lib/src/blocs/form/step_form_state.dart`

**Interfaces:**
- Consumes: `MkFormState<T>` from Task 1 (extended, not composed).
- Produces: `class MkStepFormState<T extends Object?> extends MkFormState<T>` with all the fields it has today (`currentStep`, `totalSteps`, `completedSteps`, `isLoadingInitialData`, `redirectedFromStep`, `invalidStepIndex`) plus inherited `extra`.

- [ ] **Step 1: Replace `lib/src/blocs/form/step_form_state.dart`**

```dart
import '../../core/status.dart';
import 'form_state.dart';

/// Represents the state of a multi-step / wizard form.
///
/// [T] is the type of [MkFormState.extra], exactly as on [MkFormState]; most
/// step forms never need it and can use `MkStepFormState` (no type
/// argument).
class MkStepFormState<T extends Object?> extends MkFormState<T> {
  const MkStepFormState({
    required super.submissionStatus,
    required super.isValid,
    required super.isValidating,
    required super.isDirty,
    required super.isTouched,
    required super.wasSubmitted,
    required super.values,
    super.submissionError,
    required super.extra,
    super.extraReset,
    super.isExtraBusy,
    required this.currentStep,
    required this.totalSteps,
    required this.completedSteps,
    this.isLoadingInitialData = false,
    this.redirectedFromStep,
    this.invalidStepIndex,
  });

  /// The active step index (0-indexed).
  final int currentStep;

  /// The total number of steps configured in the form.
  final int totalSteps;

  /// Set of step indices that have passed validation.
  final Set<int> completedSteps;

  /// Whether draft or initial step data is currently being fetched asynchronously.
  final bool isLoadingInitialData;

  /// If loading initial data redirected away from the server's targeted step due to
  /// validation errors in an earlier step, this holds the original target step.
  final int? redirectedFromStep;

  /// If a redirection occurred due to validation errors, this holds the 0-indexed step
  /// that contained the invalid controls.
  final int? invalidStepIndex;

  /// Whether loading draft/initial data was redirected to an earlier step because of
  /// validation errors in that step.
  bool get wasRedirectedDueToError =>
      redirectedFromStep != null && invalidStepIndex != null;

  /// Whether the active step is the first step.
  bool get isFirstStep => currentStep == 0;

  /// Whether the active step is the final step.
  bool get isLastStep => currentStep >= totalSteps - 1;

  /// Progress fraction from 0.0 to 1.0.
  double get stepProgress =>
      totalSteps > 1 ? (currentStep / (totalSteps - 1)).clamp(0.0, 1.0) : 1.0;

  /// Whether step at [index] is marked as completed.
  bool isStepCompleted(int index) => completedSteps.contains(index);

  @override
  MkStepFormState<T> copyWith({
    MkSubmissionStatus? submissionStatus,
    bool? isValid,
    bool? isValidating,
    bool? isDirty,
    bool? isTouched,
    bool? wasSubmitted,
    Map<String, dynamic>? values,
    Object? Function()? submissionError,
    T? extra,
    int? currentStep,
    int? totalSteps,
    Set<int>? completedSteps,
    bool? isLoadingInitialData,
    int? Function()? redirectedFromStep,
    int? Function()? invalidStepIndex,
  }) {
    return MkStepFormState<T>(
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
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      completedSteps: completedSteps ?? this.completedSteps,
      isLoadingInitialData: isLoadingInitialData ?? this.isLoadingInitialData,
      redirectedFromStep: redirectedFromStep != null
          ? redirectedFromStep()
          : this.redirectedFromStep,
      invalidStepIndex: invalidStepIndex != null
          ? invalidStepIndex()
          : this.invalidStepIndex,
    );
  }

  @override
  MkStepFormState<T> reset({
    required bool isValid,
    required bool isValidating,
    required Map<String, dynamic> values,
  }) {
    return (super.reset(
              isValid: isValid,
              isValidating: isValidating,
              values: values,
            )
            as MkStepFormState<T>)
        .copyWith(
          currentStep: 0,
          completedSteps: const {},
          isLoadingInitialData: false,
          redirectedFromStep: () => null,
          invalidStepIndex: () => null,
        );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    currentStep,
    totalSteps,
    completedSteps,
    isLoadingInitialData,
    redirectedFromStep,
    invalidStepIndex,
  ];
}
```

- [ ] **Step 2: Run static analysis on this file**

Run: `dart analyze lib/src/blocs/form/step_form_state.dart`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/src/blocs/form/step_form_state.dart
git commit -m "feat(state): make MkStepFormState generic over MkFormState's extra type"
```

---

### Task 5: `MkStepFormBloc<T>` / `MkSimpleStepFormBloc<T>` rewrite

**Files:**
- Modify: `lib/src/blocs/form/step_form_bloc.dart`
- Test: existing `test/blocs/step_form_bloc_test.dart` (must pass **unmodified**)

**Interfaces:**
- Consumes: `MkFormBloc<T>` (Task 2), `MkStepFormState<T>` (Task 4).
- Produces: `abstract class MkStepFormBloc<T extends Object?> extends MkFormBloc<T>`, constructor gains optional `initialExtra`/`extraReset`/`isExtraBusy`; `class MkSimpleStepFormBloc<T extends Object?> extends MkStepFormBloc<T>` (unchanged public surface beyond the type parameter). `onUpdateFormState` override removed (dead code — see spec).

- [ ] **Step 1: Replace `lib/src/blocs/form/step_form_bloc.dart`**

```dart
import 'dart:async';
import '../../core/status.dart';
import '../control_bloc.dart';
import 'form_bloc.dart';
import 'step_form_state.dart';

export 'step_form_state.dart';

/// Configuration for a single step in an [MkStepFormBloc].
class MkFormStep {
  const MkFormStep({required this.controlNames, this.title, this.subtitle});

  /// Names of the controls that belong to this step.
  final List<String> controlNames;

  /// Optional title for this step (e.g. for stepper UI).
  final String? title;

  /// Optional subtitle or description.
  final String? subtitle;
}

/// A specialized [MkFormBloc] that manages multi-step forms, wizards,
/// and multi-route onboarding workflows.
///
/// [T] is the type of [MkFormState.extra]; most step forms never need it and
/// can extend `MkStepFormBloc` (no type argument) exactly as before. A step
/// form that wants typed extras extends `MkStepFormBloc<MyExtras>` and
/// passes `initialExtra`/`extraReset`/`isExtraBusy` to the constructor.
///
/// Features:
/// - Granular step validation: validating Step 1 never marks Step 2 or 3 as dirty/touched.
/// - Step progression gating: [nextStep] only advances if current step controls are valid.
/// - Initial step configuration: can start at any step (e.g. resuming an onboarding flow).
/// - Remote data hydration: [loadInitialData] fetches drafts from an API, marks fields
///   pristine without false errors, and jumps to the server-designated step.
/// - Safe route transitions: retains full form state across Navigator push and pop.
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
           controls,
           steps,
           initialStep,
           initialExtra,
           extraReset,
           isExtraBusy,
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
    final validInitialStep = steps.isEmpty
        ? 0
        : initialStep.clamp(0, steps.length - 1);
    return MkStepFormState<T>(
      submissionStatus: const MkSubmissionStatus.idle(),
      isValid: controls.values.every((c) => c.isValid),
      isValidating: controls.values.any((c) => c.isValidating),
      isDirty: controls.values.any((c) => c.isDirty),
      isTouched: controls.values.any((c) => c.isTouched),
      wasSubmitted: false,
      values: {
        for (final entry in controls.entries) entry.key: entry.value.value,
      },
      // Only reached without a mismatch when T is Object? (no extras); a
      // step form with a real extras type must always pass `initialExtra`,
      // exactly as `MkFormBloc` requires `initialState` for the same reason.
      extra: initialExtra != null ? initialExtra() : null as T,
      extraReset: extraReset,
      isExtraBusy: isExtraBusy,
      currentStep: validInitialStep,
      totalSteps: steps.length,
      completedSteps: const {},
    );
  }

  final List<MkFormStep> _steps;

  /// Unmodifiable list of configured steps.
  List<MkFormStep> get steps => _steps;

  @override
  MkStepFormState<T> get state => super.state as MkStepFormState<T>;

  /// The active step index.
  int get currentStep => state.currentStep;

  /// Total number of steps.
  int get totalSteps => state.totalSteps;

  /// Validates only the controls belonging to [step] (defaults to [currentStep]).
  ///
  /// Crucially, this does NOT touch or mark future steps as submitted,
  /// preserving pristine form state across multi-route wizards.
  Future<bool> validateStep([int? step]) async {
    final stepIndex = step ?? currentStep;
    if (stepIndex < 0 || stepIndex >= _steps.length) return true;

    final stepConfig = _steps[stepIndex];
    final isValid = await validateControls(stepConfig.controlNames);
    if (isClosed) return false;

    final updatedCompleted = Set<int>.from(state.completedSteps);
    if (isValid) {
      updatedCompleted.add(stepIndex);
    } else {
      updatedCompleted.remove(stepIndex);
    }

    emit(state.copyWith(completedSteps: updatedCompleted));

    return isValid;
  }

  /// Validates the current step and, if valid, advances to the next step.
  ///
  /// Returns `true` if validation passed and the step advanced (or is on the last step).
  Future<bool> nextStep() async {
    if (isClosed) return false;

    final isStepValid = await validateStep(currentStep);
    if (!isStepValid) return false;

    if (state.currentStep < totalSteps - 1) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
      return true;
    }

    return true;
  }

  /// Navigates to the previous step if not already on the first step.
  void previousStep() {
    if (isClosed || state.currentStep <= 0) return;
    emit(state.copyWith(currentStep: state.currentStep - 1));
  }

  /// Navigates directly to a target step.
  ///
  /// If navigating backwards, navigation is immediate.
  /// If navigating forward past incomplete steps, validates preceding steps first.
  Future<bool> goToStep(int targetStep) async {
    if (isClosed || targetStep < 0 || targetStep >= totalSteps) return false;

    if (targetStep <= currentStep) {
      emit(state.copyWith(currentStep: targetStep));
      return true;
    }

    // Navigating forward: validate all steps between current and target
    for (int i = currentStep; i < targetStep; i++) {
      final valid = await validateStep(i);
      if (!valid || isClosed) return false;
    }

    emit(state.copyWith(currentStep: targetStep));
    return true;
  }

  /// Asynchronously loads initial/draft data from an API and hydrates form fields.
  ///
  /// - Automatically sets [MkStepFormState.isLoadingInitialData] = true while loading.
  /// - Hydrates fields via [populateValues] with `markPristine: true` so no premature errors appear.
  /// - Resolves the server-designated starting step using [resolveInitialStep].
  Future<void> loadInitialData(
    Future<Map<String, dynamic>> Function() loader, {
    int? Function(Map<String, dynamic> data)? resolveInitialStep,
  }) async {
    if (isClosed) return;

    emit(state.copyWith(isLoadingInitialData: true));

    try {
      final data = await loader();
      if (isClosed) return;

      populateValues(data);

      int targetStep = currentStep;
      if (resolveInitialStep != null) {
        final resolved = resolveInitialStep(data);
        if (resolved != null) {
          targetStep = resolved.clamp(0, totalSteps - 1);
        }
      }

      // Check preceding steps up to targetStep for validation issues.
      // All field values from data have been populated and preserved.
      int? firstInvalidStep;
      final completed = <int>{};

      for (int i = 0; i < targetStep; i++) {
        final stepControls = _steps[i].controlNames;
        final allValid = stepControls.every((name) {
          final c = control<MkControlBloc<dynamic>>(name);
          return c != null && c.isValid;
        });

        if (allValid) {
          completed.add(i);
        } else {
          firstInvalidStep ??= i;
        }
      }

      if (firstInvalidStep != null) {
        // Preceding step has validation issues!
        // Touch/validate the invalid step's controls so errors are immediately visible.
        await validateControls(_steps[firstInvalidStep].controlNames);
        if (isClosed) return;

        emit(
          state.copyWith(
            isLoadingInitialData: false,
            currentStep: firstInvalidStep,
            completedSteps: completed,
            redirectedFromStep: () => targetStep,
            invalidStepIndex: () => firstInvalidStep,
          ),
        );
      } else {
        // All preceding steps are valid; proceed to designated target step
        emit(
          state.copyWith(
            isLoadingInitialData: false,
            currentStep: targetStep,
            completedSteps: completed,
            redirectedFromStep: () => null,
            invalidStepIndex: () => null,
          ),
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoadingInitialData: false));
      }
      rethrow;
    }
  }
}

/// A lightweight [MkStepFormBloc] implementation that allows passing
/// an [onSubmit] closure directly.
class MkSimpleStepFormBloc<T extends Object?> extends MkStepFormBloc<T> {
  MkSimpleStepFormBloc({
    required super.controls,
    required super.steps,
    super.initialStep,
    super.initialExtra,
    super.extraReset,
    super.isExtraBusy,
    required Future<dynamic> Function(Map<String, dynamic> values) onSubmit,
    void Function(dynamic response)? onSubmitSuccess,
    void Function(Object error)? onSubmitFailure,
  }) : _submitHandler = onSubmit,
       _successHandler = onSubmitSuccess,
       _failureHandler = onSubmitFailure;

  final Future<dynamic> Function(Map<String, dynamic> values) _submitHandler;
  final void Function(dynamic response)? _successHandler;
  final void Function(Object error)? _failureHandler;

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) {
    return _submitHandler(values);
  }

  @override
  void onSubmitSuccess(dynamic response) {
    _successHandler?.call(response);
  }

  @override
  void onSubmitFailure(Object error) {
    _failureHandler?.call(error);
  }
}
```

Note what was deliberately removed versus the pre-existing file: the `import 'package:flutter/foundation.dart';` and `import 'form_state.dart';` imports, and the `onUpdateFormState` override — all three only existed to support the override that is now dead code (see spec's "onUpdateFormState... is deleted" note). Leaving either import in would produce an `unused_import` analyzer warning.

- [ ] **Step 2: Run static analysis on the library**

Run: `dart analyze lib`
Expected: `No issues found!` — this is the first point where the whole `lib/` tree should be clean.

- [ ] **Step 3: Run the existing step-form suite unmodified**

Run: `flutter test test/blocs/step_form_bloc_test.dart`
Expected: all PASS, with zero source changes to that file.

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/blocs/form/step_form_bloc.dart
git commit -m "feat(state): make MkStepFormBloc generic and drop its redundant onUpdateFormState override"
```

---

### Task 6: Step form + typed extras combo test

**Files:**
- Test: `test/blocs/step_form_extras_test.dart` (create)

**Interfaces:**
- Consumes: `MkStepFormBloc<T>` (Task 5).

- [ ] **Step 1: Write `test/blocs/step_form_extras_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

/// Minimal extra payload proving MkStepFormBloc<T> composes step tracking
/// with typed extras without any hand-written state subclass.
class _OnboardingExtra {
  const _OnboardingExtra({
    this.welcomeEmailStatus = const MkSubmissionStatus.idle(),
  });

  final MkSubmissionStatus welcomeEmailStatus;

  _OnboardingExtra copyWith({MkSubmissionStatus? welcomeEmailStatus}) {
    return _OnboardingExtra(
      welcomeEmailStatus: welcomeEmailStatus ?? this.welcomeEmailStatus,
    );
  }
}

class _OnboardingBloc extends MkStepFormBloc<_OnboardingExtra> {
  _OnboardingBloc()
    : super(
        controls: {
          'username': MkFieldBloc<String>(
            initialValue: '',
            validators: [MkValidators.required()],
          ),
          'email': MkFieldBloc<String>(initialValue: ''),
        },
        steps: const [
          MkFormStep(controlNames: ['username']),
          MkFormStep(controlNames: ['email']),
        ],
        initialExtra: () => const _OnboardingExtra(),
        extraReset: () => const _OnboardingExtra(),
        isExtraBusy: (e) => e.welcomeEmailStatus.isSubmitting,
      );

  Future<void> sendWelcomeEmail() async {
    emit(
      state.updateExtra(
        (e) => e.copyWith(
          welcomeEmailStatus: const MkSubmissionStatus.submitting(),
        ),
      ),
    );
    emit(
      state.updateExtra(
        (e) => e.copyWith(
          welcomeEmailStatus: const MkSubmissionStatus.success(),
        ),
      ),
    );
  }

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async => 'ok';
}

void main() {
  group('MkStepFormBloc<T> with typed extras', () {
    test('extra and step fields coexist and update independently', () async {
      final bloc = _OnboardingBloc();
      addTearDown(bloc.close);

      expect(bloc.state.extra.welcomeEmailStatus.isIdle, isTrue);
      expect(bloc.currentStep, 0);

      bloc.field<String>('username')!.changeValue('ada');
      expect(await bloc.nextStep(), isTrue);
      expect(bloc.currentStep, 1);
      // Step advanced; extra untouched by the control edit and step move.
      expect(bloc.state.extra.welcomeEmailStatus.isIdle, isTrue);

      await bloc.sendWelcomeEmail();
      expect(bloc.state.extra.welcomeEmailStatus.isSuccess, isTrue);
      // Updating extra did not disturb step-tracking fields.
      expect(bloc.currentStep, 1);
      expect(bloc.state.completedSteps.contains(0), isTrue);

      bloc.reset();
      expect(bloc.currentStep, 0);
      expect(bloc.state.completedSteps, isEmpty);
      expect(bloc.state.extra.welcomeEmailStatus.isIdle, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the new test**

Run: `flutter test test/blocs/step_form_extras_test.dart`
Expected: PASS.

- [ ] **Step 3: Run the full test suite and analyzer**

Run: `flutter test && dart analyze lib`
Expected: all PASS, `No issues found!`.

- [ ] **Step 4: Commit**

```bash
git add test/blocs/step_form_extras_test.dart
git commit -m "test(state): cover MkStepFormBloc<T> combined with typed extras"
```

---

### Task 7: Rewrite the example's extended-state feature

**Files:**
- Delete: `example/lib/presentation/features/extended_state/bloc/profile_form_state.dart`
- Modify: `example/lib/presentation/features/extended_state/bloc/profile_form_bloc.dart`
- Modify: `example/lib/presentation/features/extended_state/extended_state_screen.dart`
- Modify: `example/test/profile_form_bloc_test.dart`

**Interfaces:**
- Consumes: `MkFormBloc<T>` (Task 2), `MkFormStateBuilder<S>` (unchanged), `ProfileExtras` (unchanged, freezed).
- Produces: `class ProfileFormBloc extends MkFormBloc<ProfileExtras>`; `extension ProfileFormStateX on MkFormState<ProfileExtras>` with `usernameVerdict` and `shownUsernameStatus` (the two getters that used to live on the deleted `ProfileFormState`).

- [ ] **Step 1: Delete `profile_form_state.dart`**

```bash
git rm example/lib/presentation/features/extended_state/bloc/profile_form_state.dart
```

- [ ] **Step 2: Replace `example/lib/presentation/features/extended_state/bloc/profile_form_bloc.dart`**

```dart
import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../data/repositories/profile_repository.dart';
import 'profile_extras.dart';

/// Profile form with three independent API calls plus a multi-call submit.
///
/// Each call updates its own status and stores what it produced in a typed
/// field of [ProfileExtras] — held directly in `MkFormState.extra`, no
/// hand-written state subclass needed.
@injectable
class ProfileFormBloc extends MkFormBloc<ProfileExtras> {
  ProfileFormBloc(ProfileRepository repository)
    : this._(repository, {
        'displayName': MkFieldBloc<String>(
          initialValue: '',
          validators: [MkValidators.required('Display name is required')],
        ),
        'username': MkFieldBloc<String>(
          initialValue: '',
          validators: [
            MkValidators.required('Username is required'),
            MkValidators.minLength(3, 'At least 3 characters'),
          ],
        ),
        'phone': MkFieldBloc<String>(
          initialValue: '',
          validators: [MkValidators.required('Phone is required')],
        ),
      });

  ProfileFormBloc._(
    this._repository,
    Map<String, MkControlBloc<dynamic>> controls,
  ) : super(
        controls: controls,
        initialState: MkFormState<ProfileExtras>(
          submissionStatus: const MkSubmissionStatus.idle(),
          isValid: controls.values.every((c) => c.isValid),
          isValidating: controls.values.any((c) => c.isValidating),
          isDirty: controls.values.any((c) => c.isDirty),
          isTouched: controls.values.any((c) => c.isTouched),
          wasSubmitted: false,
          values: {
            for (final entry in controls.entries)
              entry.key: entry.value.value,
          },
          extra: const ProfileExtras(),
          extraReset: () => const ProfileExtras(),
          isExtraBusy: (e) => e.isBusy,
        ),
      );

  final ProfileRepository _repository;

  String _text(String name) => (values[name] as String?)?.trim() ?? '';

  /// Uploads an avatar; independent of the other calls.
  Future<void> uploadAvatar(String fileName) => _track<String>(
    () => _repository.uploadAvatar(fileName),
    status: (s, status) =>
        s.updateExtra((e) => e.copyWith(avatarStatus: status)),
    onSuccess: (s, url) => s.updateExtra((e) => e.copyWith(avatarUrl: url)),
    onFailure: (s) => s.updateExtra((e) => e.copyWith(avatarUrl: null)),
  );

  /// Checks whether the typed username is available.
  ///
  /// The verdict is stored together with the username it was checked for, so
  /// [ProfileFormStateX.usernameVerdict] can ignore it once the field changes.
  Future<void> checkUsername() {
    final username = _text('username');
    return _track<bool>(
      () {
        if (username.isEmpty) throw Exception('Enter a username first');
        return _repository.isUsernameAvailable(username);
      },
      status: (s, status) =>
          s.updateExtra((e) => e.copyWith(usernameStatus: status)),
      onSuccess: (s, available) => s.updateExtra(
        (e) =>
            e.copyWith(checkedUsername: username, usernameAvailable: available),
      ),
      onFailure: (s) => s.updateExtra(
        (e) => e.copyWith(checkedUsername: null, usernameAvailable: null),
      ),
    );
  }

  /// Sends a one-time passcode to the typed phone number.
  Future<void> sendOtp() {
    final phone = _text('phone');
    return _track<void>(
      () {
        if (phone.isEmpty) throw Exception('Enter a phone number first');
        return _repository.sendOtp(phone);
      },
      status: (s, status) => s.updateExtra((e) => e.copyWith(otpStatus: status)),
      onSuccess: (s, _) => s.updateExtra((e) => e.copyWith(otpSentTo: phone)),
      onFailure: (s) => s.updateExtra((e) => e.copyWith(otpSentTo: null)),
    );
  }

  /// Runs one tracked call: `submitting`, then `success` or `failure`, with the
  /// extra fields updated on the way out.
  ///
  /// Every transition is applied to the state as it is *when the call
  /// returns*, so calls that overlap only ever touch their own fields.
  Future<void> _track<T>(
    Future<T> Function() call, {
    required MkFormState<ProfileExtras> Function(
      MkFormState<ProfileExtras> state,
      MkSubmissionStatus status,
    )
    status,
    MkFormState<ProfileExtras> Function(
      MkFormState<ProfileExtras> state,
      T result,
    )?
    onSuccess,
    MkFormState<ProfileExtras> Function(MkFormState<ProfileExtras> state)?
    onFailure,
  }) async {
    emit(status(state, const MkSubmissionStatus.submitting()));
    try {
      final result = await call();
      final updated = onSuccess?.call(state, result) ?? state;
      emit(status(updated, MkSubmissionStatus.success(result)));
    } catch (error) {
      final updated = onFailure?.call(state) ?? state;
      emit(status(updated, MkSubmissionStatus.failure(error)));
    }
  }

  /// A single submit that chains two API calls and reports which one is
  /// running through [ProfileExtras.submitStage].
  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    try {
      final username = values['username'] as String;
      _setStage('Checking username…');
      final available = await _repository.isUsernameAvailable(username);
      if (!available) {
        throw Exception('Username "$username" is already taken');
      }
      _setStage('Saving profile…');
      return await _repository.saveProfile({
        ...values,
        'avatarUrl': state.extra.avatarUrl,
      });
    } finally {
      _setStage(null);
    }
  }

  void _setStage(String? stage) =>
      emit(state.updateExtra((e) => e.copyWith(submitStage: stage)));
}

/// Derived read-only views over [ProfileFormBloc]'s state that used to live
/// as getters on the (now-deleted) `ProfileFormState` subclass. An extension
/// on `MkFormState<T>` is the replacement for "add a computed getter to my
/// form state" now that subclassing is no longer required.
extension ProfileFormStateX on MkFormState<ProfileExtras> {
  /// Availability of the username currently typed in the form: `null` unless
  /// a check finished for exactly this value, so a verdict never outlives an
  /// edit and a check that returns late for an older username is ignored.
  bool? get usernameVerdict {
    final current = (values['username'] as String?)?.trim();
    return extra.checkedUsername != null && extra.checkedUsername == current
        ? extra.usernameAvailable
        : null;
  }

  /// [ProfileExtras.usernameStatus] as it should be shown: a finished check
  /// that no longer matches the typed username is shown as idle.
  MkSubmissionStatus get shownUsernameStatus =>
      extra.usernameStatus.isSuccess && usernameVerdict == null
      ? const MkSubmissionStatus.idle()
      : extra.usernameStatus;
}
```

- [ ] **Step 3: Update `example/lib/presentation/features/extended_state/extended_state_screen.dart`**

Apply these changes to the existing file:

1. Remove the import of the deleted file and adjust the doc comment:

```dart
// Remove this line:
import 'bloc/profile_form_state.dart';
```

Update the class doc comment (currently lines 10–21) to:

```dart
/// Demonstrates a generic [MkFormState]`<T>` carrying several independent
/// statuses and typed extra fields.
///
/// - Avatar upload, username check and OTP request run concurrently, each with
///   its own status in [ProfileExtras], a freezed class held directly in
///   `MkFormState.extra` — no hand-written state subclass.
/// - Each call also stores what it produced in a typed field of that class
///   (`avatarUrl`, `checkedUsername` / `usernameAvailable`, `otpSentTo`) that
///   the UI reads directly.
/// - The submit button is disabled while any of them is running (`isBusy`).
/// - Submitting chains two API calls inside `onSubmit` and reports the running
///   one through `submitStage`.
```

2. Replace every `MkFormStateBuilder<ProfileFormState>` with
   `MkFormStateBuilder<MkFormState<ProfileExtras>>` (4 occurrences).

3. Replace every `.extras.` with `.extra.` (the fields read from the tracked
   calls: `otpStatus`, `otpSentTo`, `avatarStatus`, `avatarUrl`,
   `submitStage`). `usernameVerdict` and `shownUsernameStatus` stay exactly
   as written (`state.usernameVerdict`, `state.shownUsernameStatus`) — they
   now resolve through the `ProfileFormStateX` extension imported
   transitively via `profile_form_bloc.dart`.

The four `MkFormStateBuilder` blocks read, after both replacements:

```dart
              MkFormStateBuilder<MkFormState<ProfileExtras>>(
                buildWhen: (prev, curr) =>
                    prev.shownUsernameStatus != curr.shownUsernameStatus ||
                    prev.usernameVerdict != curr.usernameVerdict,
                builder: (context, state, bloc) => _CallRow(
                  label: 'Check availability',
                  status: state.shownUsernameStatus,
                  onPressed: () => unawaited(_formBloc.checkUsername()),
                  successText: (_) => state.usernameVerdict == true
                      ? (text: 'Available', color: Colors.green)
                      : (text: 'Taken', color: Colors.orange.shade800),
                ),
              ),
```

```dart
              MkFormStateBuilder<MkFormState<ProfileExtras>>(
                buildWhen: (prev, curr) =>
                    prev.extra.otpStatus != curr.extra.otpStatus ||
                    prev.extra.otpSentTo != curr.extra.otpSentTo,
                builder: (context, state, bloc) => _CallRow(
                  label: 'Send code',
                  status: state.extra.otpStatus,
                  onPressed: () => unawaited(_formBloc.sendOtp()),
                  successText: (_) => (
                    text: 'Code sent to ${state.extra.otpSentTo}',
                    color: Colors.green,
                  ),
                ),
              ),
```

```dart
              MkFormStateBuilder<MkFormState<ProfileExtras>>(
                buildWhen: (prev, curr) =>
                    prev.extra.avatarStatus != curr.extra.avatarStatus ||
                    prev.extra.avatarUrl != curr.extra.avatarUrl,
                builder: (context, state, bloc) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton.tonal(
                          onPressed: state.extra.avatarStatus.isSubmitting
                              ? null
                              : () => unawaited(
                                  _formBloc.uploadAvatar('avatar.png'),
                                ),
                          child: const Text('Upload avatar'),
                        ),
                        FilledButton.tonal(
                          onPressed: state.extra.avatarStatus.isSubmitting
                              ? null
                              : () => unawaited(
                                  _formBloc.uploadAvatar('avatar_fail.png'),
                                ),
                          child: const Text('Upload failing avatar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _CallStatusText(
                      state.extra.avatarStatus,
                      successText: (_) => (
                        text: 'Uploaded: ${state.extra.avatarUrl}',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
```

```dart
              MkFormStateBuilder<MkFormState<ProfileExtras>>(
                buildWhen: (prev, curr) =>
                    prev.isBusy != curr.isBusy ||
                    prev.extra.submitStage != curr.extra.submitStage,
                builder: (context, state, bloc) => FilledButton(
                  onPressed: state.isBusy
                      ? null
                      : () => unawaited(bloc.submit()),
                  // `submitStage` says which of the submit's two calls is
                  // running; side calls only make the form busy.
                  child: Text(
                    state.extra.submitStage ??
                        (state.isBusy ? 'Working…' : 'Save profile'),
                  ),
                ),
              ),
```

The rest of the file (imports of `profile_extras.dart` and
`profile_form_bloc.dart`, the widget scaffolding, `_CallRow`,
`_CallStatusText`) is unchanged.

- [ ] **Step 4: Update `example/test/profile_form_bloc_test.dart`**

Replace every `.extras.` with `.extra.` throughout the file (14
occurrences: `avatarUrl`, `avatarStatus`, `checkedUsername`,
`usernameAvailable`, `usernameStatus`, `otpStatus`, `otpSentTo`,
`submitStage`). `bloc.state.usernameVerdict` and
`bloc.state.shownUsernameStatus` are unchanged (still resolve via the
`ProfileFormStateX` extension).

- [ ] **Step 5: Run the example's analyzer and tests**

```bash
cd example
flutter pub get
dart analyze lib
flutter test
cd ..
```

Expected: analyzer clean, all tests PASS — including
`extended_state_screen_test.dart` and `widget_test.dart`, which were not
modified.

- [ ] **Step 6: Commit**

```bash
git add example/lib/presentation/features/extended_state example/test/profile_form_bloc_test.dart
git commit -m "refactor(example): drop ProfileFormState subclass for MkFormState<ProfileExtras>"
```

---

### Task 8: README and CHANGELOG

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Replace the "🧬 Extending Form State" section of `README.md`**

Replace the entire section (from `## 🧬 Extending Form State` through the
`---` right before `## 🪜 Multi-Step Forms & Multi-Route Wizards`) with:

```markdown
## 🧬 Extending Form State

Need more than idle / submitting / success / failure? `MkFormState<T>` has a
generic `extra` slot for whatever your form needs beyond the base fields.
Reuse `MkSubmissionStatus` for each independent API call, so one form can
track an avatar upload, a username check and an OTP request at the same
time — with no state subclass to write.

### 1. Declare the extra payload

Any type works: a `freezed` class (recommended — `copyWith`, `==` and
`toString` come for free), or a plain hand-written class. It should
implement value equality (`==`/`hashCode`, `Equatable`, or `freezed`),
because `extra` feeds `MkFormState`'s own equality directly.

```dart
@freezed
abstract class ProfileExtra with _$ProfileExtra {
  const ProfileExtra._();

  const factory ProfileExtra({
    @Default(MkSubmissionStatus.idle()) MkSubmissionStatus avatarStatus,
    @Default(MkSubmissionStatus.idle()) MkSubmissionStatus otpStatus,
  }) = _ProfileExtra;

  /// Submit is blocked while either call is running.
  bool get isBusy => avatarStatus.isSubmitting || otpStatus.isSubmitting;
}
```

### 2. Parameterize the bloc — no state subclass

```dart
class ProfileFormBloc extends MkFormBloc<ProfileExtra> {
  ProfileFormBloc(Api api)
    : this._(api, {'username': MkFieldBloc<String>(initialValue: '')});

  ProfileFormBloc._(this._api, Map<String, MkControlBloc<dynamic>> controls)
    : super(
        controls: controls,
        initialState: MkFormState<ProfileExtra>(
          submissionStatus: const MkSubmissionStatus.idle(),
          isValid: controls.values.every((c) => c.isValid),
          isValidating: controls.values.any((c) => c.isValidating),
          isDirty: controls.values.any((c) => c.isDirty),
          isTouched: controls.values.any((c) => c.isTouched),
          wasSubmitted: false,
          values: {for (final e in controls.entries) e.key: e.value.value},
          extra: const ProfileExtra(),
          extraReset: () => const ProfileExtra(),
          isExtraBusy: (e) => e.isBusy,
        ),
      );

  final Api _api;

  Future<void> uploadAvatar(String path) async {
    emit(state.updateExtra((e) => e.copyWith(avatarStatus: const MkSubmissionStatus.submitting())));
    try {
      final url = await _api.uploadAvatar(path);
      emit(state.updateExtra((e) => e.copyWith(avatarStatus: MkSubmissionStatus.success(url))));
    } catch (error) {
      emit(state.updateExtra((e) => e.copyWith(avatarStatus: MkSubmissionStatus.failure(error))));
    }
  }

  /// One submit can chain several API calls.
  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    await _api.reserveUsername(values['username'] as String);
    return _api.saveProfile(values);
  }
}
```

> The redirecting constructor (`: this._(...)`) is needed because the controls must exist before `super(...)` so the initial state can be computed from them. `state` is inherited directly as `MkFormState<ProfileExtra>` — no downcast. Field edits never lose or replace `extra`: `MkFormBloc` only ever updates state through the base fields, so the same `extra` instance carries through every edit untouched.

### 3. Build the UI without casts

```dart
MkFormStateBuilder<MkFormState<ProfileExtra>>(
  buildWhen: (prev, curr) => prev.extra.avatarStatus != curr.extra.avatarStatus,
  builder: (context, state, bloc) => switch (state.extra.avatarStatus) {
    MkSubmissionInProgress() => const CircularProgressIndicator(),
    MkSubmissionSuccess(:final response) => Image.network('$response'),
    MkSubmissionFailure(:final error) => Text('$error'),
    MkSubmissionIdle() => const SizedBox.shrink(),
  },
)
```

`MkFormStateBuilder<S>` throws a `StateError` if the bloc's state is not an `S`. Write the type argument explicitly (Dart cannot infer it from an unannotated builder closure); use the plain `MkFormBuilder` when you only need the base fields.

Need a derived, read-only view over the state (like "is this username available right now")? Write a Dart extension method on `MkFormState<ProfileExtra>` — this is the replacement for what a computed getter on a state subclass used to give you:

```dart
extension ProfileFormStateX on MkFormState<ProfileExtra> {
  bool get avatarReady => extra.avatarStatus.isSuccess;
}
```

| Member | Purpose |
|---|---|
| `MkFormState.extra` | Your typed payload; `T` defaults to `Object?` (`null`) when unused |
| `MkFormState.updateExtra(fn)` | Shorthand for `copyWith(extra: fn(extra))` |
| `MkFormState.isBusy` | `isSubmitting` plus whatever `isExtraBusy(extra)` reports; drives `canSubmit` and blocks `submit()` |
| `MkFormState.reset(...)` | Regenerates `extra` via `extraReset` (or leaves it unchanged if omitted); called by `MkFormBloc.reset()` |
| `MkFormStateBuilder<S>` | Typed access to `MkFormState<YourExtra>` |

**Things to watch**

- Every custom status must reach a terminal state on every code path (wrap the call in try/catch as in the example above). A status stuck in `submitting` keeps `isBusy` true and `submit()` returns silently forever.
- `reset()` regenerates `extra` via `extraReset`, but a call that is still in flight will write its result into the state afterwards. If `reset()` can run while calls are in flight, guard the emit (for example with a generation counter checked before emitting).
- Give your `extra` type value equality (`Equatable`, `freezed`, or manual `==`/`hashCode`). It feeds `MkFormState`'s own equality directly, so without it, `buildWhen` and any duplicate-state suppression fall back to identity.
- A form built with `extends MkFormBloc<MyExtra>` where `MyExtra` is not nullable must always pass `initialState` (or, for `MkStepFormBloc<MyExtra>`, `initialExtra`) — omitting it throws immediately at construction rather than silently storing a broken value.
```

- [ ] **Step 2: Replace the 1.1.0 entry in `CHANGELOG.md`**

```markdown
## [1.1.0] - Unreleased

### Added
- **Extensible form state via generics.** `MkFormState<T>` carries a single typed `extra` field, so one form can track several independent API calls (upload, availability check, OTP) or extra statuses — with no state subclass to write. See "Extending Form State" in the README.
  - `MkFormBloc<T>` / `MkStepFormBloc<T>` — generic over the same `T`; `state` is already typed, with no downcast in application code.
  - `MkFormState.updateExtra(fn)` — shorthand for `copyWith(extra: fn(extra))`.
  - `MkFormState.isBusy` — reflects `isSubmitting` plus `isExtraBusy(extra)` (set once via the constructor); `canSubmit` and `MkFormBloc.submit()` respect it.
  - `MkFormState.reset(...)` — regenerates `extra` via `extraReset` (set once via the constructor), or leaves it unchanged if omitted.
  - `MkFormStateBuilder<S extends MkFormState>` and `MkFormStateWidgetBuilder<S>` — unchanged in shape; used as `MkFormStateBuilder<MkFormState<YourExtra>>`. `MkFormBuilder` is unchanged.
  - Every pre-existing "no extras" form needs no source changes: omitting the type argument (`extends MkFormBloc`, `extends MkStepFormBloc`) still compiles.

### Fixed
- `MkFormBloc.reset()` dropped subclass state by emitting a plain `MkFormState`. Resetting `extra` is now built into `MkFormState.reset()` via `extraReset`, and `MkStepFormBloc` no longer needs its own `reset()`/`onUpdateFormState()` overrides.

### Changed
- This replaces the subclassing-based extensible-state design from the previous unreleased 1.1.0 draft (never published). If you were tracking that draft: subclass `ProfileFormState extends MkFormState` becomes `MkFormBloc<ProfileExtras>` with `extra: const ProfileExtras()`; `state.extras` becomes `state.extra`.
```

- [ ] **Step 3: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: rewrite Extending Form State around MkFormState<T> and update the 1.1.0 changelog entry"
```

---

### Task 9: Full-repository verification

**Files:** none (verification only).

- [ ] **Step 1: Library analyzer and tests**

```bash
dart analyze
flutter test
```

Expected: `No issues found!`; every test PASSES (including all files touched in Tasks 1–6).

- [ ] **Step 2: Example analyzer and tests**

```bash
cd example
flutter pub get
dart analyze
flutter test
cd ..
```

Expected: `No issues found!`; every test PASSES (including the untouched `extended_state_screen_test.dart` and `widget_test.dart`).

- [ ] **Step 3: Grep for stray casts and leftover references**

```bash
grep -rn " as MkFormState\| as MkStepFormState\| as ProfileFormState\| as ProfileState" lib example test
grep -rln "\.extras\b" lib example test
grep -rln "ProfileFormState" lib example test
```

Expected: the first grep returns only the three documented internal casts (`MkFormBloc`'s constructor, `MkStepFormBloc.state`, `MkStepFormState.reset` — check each match is one of these three, not a new one); the second and third return no matches at all.

- [ ] **Step 4: Confirm no new dependency was added**

```bash
git diff main -- pubspec.yaml
```

Expected: empty (or, if run before merging, no diff introduced by this branch beyond what was already on `feat/extensible-form-state` before this plan started).

- [ ] **Step 5: Report**

No commit for this task — it is a verification gate. If any step fails, return to the task that owns the offending file and fix it there (with its own commit), then re-run this task's steps from the top.
