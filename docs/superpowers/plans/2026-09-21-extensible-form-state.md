# Extensible Form State Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let apps extend `MkFormState` with their own typed status fields (extra statuses, several concurrent API calls, multi-call submit) without boilerplate or lost state.

**Architecture:** Keep `MkFormBloc extends Cubit<MkFormState>`; subclasses downcast `state`. Add two overridable members on `MkFormState` (`isBusy`, `reset()`) that the bloc uses for submit gating and reset, so subclass fields survive. Make `MkFormBuilder` optionally generic (`MkFormBuilder<S>`) so builders get the typed state without casts. Apps reuse `MkSubmissionStatus` for their own fields.

**Tech Stack:** Dart >=3.9, Flutter >=3.41, `flutter_bloc` ^9.1.1, `bloc` ^9.2.1, `equatable`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-21-extensible-form-state-design.md`

## Global Constraints

- Additive change only: no public symbol is removed or renamed; existing call sites (`MkFormBuilder(...)`, `MkFormWidgetBuilder`, `extends MkFormBloc`, `extends MkStepFormBloc`) compile unchanged.
- Target release 1.1.0, but do NOT edit `pubspec.yaml` `version:` and do NOT publish; the maintainer does that.
- No new package dependencies.
- CI gates that must pass: `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos`, `flutter test`.
- Code style: match surrounding code (trailing commas, `dart format` tall style, `///` doc comments on public members, `unawaited(...)` for fire-and-forget futures).
- Commit with the local git config only; do NOT add a `Co-Authored-By` trailer (or any attribution line) to commit messages.
- Work on a feature branch (`feat/extensible-form-state`), not `main`.

## File Structure

| File | Responsibility |
|---|---|
| `lib/src/blocs/form/form_state.dart` (modify) | Add `isBusy`, `reset()`; `canSubmit` uses `isBusy` |
| `lib/src/blocs/form/step_form_state.dart` (modify) | Override `reset()` to return to step 0 |
| `lib/src/blocs/form/form_bloc.dart` (modify) | `submit()` gates on `isBusy`; `reset()` delegates to `state.reset` |
| `lib/src/blocs/form/step_form_bloc.dart` (modify) | Delete duplicated `reset()` override |
| `lib/src/ui/form_builder.dart` (modify) | Generic `MkFormBuilder<S>` and `MkFormWidgetBuilder<S>` |
| `test/support/profile_form.dart` (create) | Shared test fixture: `ProfileState` (extended state) and `ProfileBloc` |
| `test/blocs/extensible_state_test.dart` (create) | Reset, `isBusy`, concurrent-status tests |
| `test/blocs/step_form_bloc_test.dart` (modify) | Step reset regression test |
| `test/ui/form_builder_test.dart` (create) | Typed builder tests |
| `README.md`, `CHANGELOG.md` (modify) | Docs |
| `example/...` (create/modify) | Profile example screen, route, DI regeneration |

---

### Task 1: `isBusy` and `reset()` on the state, wired into the bloc

**Files:**
- Modify: `lib/src/blocs/form/form_state.dart`
- Modify: `lib/src/blocs/form/step_form_state.dart`
- Modify: `lib/src/blocs/form/form_bloc.dart`
- Modify: `lib/src/blocs/form/step_form_bloc.dart`
- Create: `test/support/profile_form.dart`
- Create: `test/blocs/extensible_state_test.dart`
- Modify: `test/blocs/step_form_bloc_test.dart`

**Interfaces:**
- Consumes: existing `MkFormState.copyWith`, `MkSubmissionStatus`, `MkFormBloc.emit`.
- Produces:
  - `bool MkFormState.isBusy` (getter, default `isSubmitting`)
  - `MkFormState MkFormState.reset({required bool isValid, required bool isValidating, required Map<String, dynamic> values})`
  - `MkStepFormState MkStepFormState.reset(...)` (same params, covariant return)
  - Test fixtures `ProfileState` / `ProfileBloc` (used again in Task 2). `ProfileBloc({Completer<void>? avatarUpload, Completer<void>? otpSend})`, methods `uploadAvatar()`, `sendOtp()`, field `submitCalls`, typed `state`.

- [ ] **Step 0: Create the branch**

```bash
git checkout -b feat/extensible-form-state
```

- [ ] **Step 1: Write the shared test fixture**

Create `test/support/profile_form.dart`:

```dart
import 'dart:async';
import 'package:mk_forms/mk_forms.dart';

/// A form state extended with two independent API-call statuses.
class ProfileState extends MkFormState {
  const ProfileState({
    required super.submissionStatus,
    required super.isValid,
    required super.isValidating,
    required super.isDirty,
    required super.isTouched,
    required super.wasSubmitted,
    required super.values,
    super.submissionError,
    this.avatarStatus = const MkSubmissionStatus.idle(),
    this.otpStatus = const MkSubmissionStatus.idle(),
  });

  factory ProfileState.initial(Map<String, MkControlBloc<dynamic>> controls) {
    return ProfileState(
      submissionStatus: const MkSubmissionStatus.idle(),
      isValid: controls.values.every((c) => c.isValid),
      isValidating: controls.values.any((c) => c.isValidating),
      isDirty: controls.values.any((c) => c.isDirty),
      isTouched: controls.values.any((c) => c.isTouched),
      wasSubmitted: false,
      values: {
        for (final entry in controls.entries) entry.key: entry.value.value,
      },
    );
  }

  final MkSubmissionStatus avatarStatus;
  final MkSubmissionStatus otpStatus;

  @override
  bool get isBusy =>
      super.isBusy || avatarStatus.isSubmitting || otpStatus.isSubmitting;

  @override
  ProfileState copyWith({
    MkSubmissionStatus? submissionStatus,
    bool? isValid,
    bool? isValidating,
    bool? isDirty,
    bool? isTouched,
    bool? wasSubmitted,
    Map<String, dynamic>? values,
    Object? Function()? submissionError,
    MkSubmissionStatus? avatarStatus,
    MkSubmissionStatus? otpStatus,
  }) {
    return ProfileState(
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
      avatarStatus: avatarStatus ?? this.avatarStatus,
      otpStatus: otpStatus ?? this.otpStatus,
    );
  }

  @override
  ProfileState reset({
    required bool isValid,
    required bool isValidating,
    required Map<String, dynamic> values,
  }) {
    return (super.reset(
              isValid: isValid,
              isValidating: isValidating,
              values: values,
            )
            as ProfileState)
        .copyWith(
          avatarStatus: const MkSubmissionStatus.idle(),
          otpStatus: const MkSubmissionStatus.idle(),
        );
  }

  @override
  List<Object?> get props => [...super.props, avatarStatus, otpStatus];
}

/// A form bloc whose two side calls are driven by test-controlled completers.
class ProfileBloc extends MkFormBloc {
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
  ) : super(controls: controls, initialState: ProfileState.initial(controls));

  final Completer<void>? _avatarUpload;
  final Completer<void>? _otpSend;
  int submitCalls = 0;

  @override
  ProfileState get state => super.state as ProfileState;

  Future<void> uploadAvatar() =>
      _track(_avatarUpload!, (s) => state.copyWith(avatarStatus: s));

  Future<void> sendOtp() =>
      _track(_otpSend!, (s) => state.copyWith(otpStatus: s));

  Future<void> _track(
    Completer<void> call,
    ProfileState Function(MkSubmissionStatus status) apply,
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

- [ ] **Step 2: Write the failing tests**

Create `test/blocs/extensible_state_test.dart`:

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';
import '../support/profile_form.dart';

void main() {
  group('extending MkFormState', () {
    test('reset keeps the subclass type and resets custom fields', () {
      final bloc = ProfileBloc(avatarUpload: Completer<void>());
      addTearDown(bloc.close);

      unawaited(bloc.uploadAvatar());
      expect(bloc.state.avatarStatus.isSubmitting, isTrue);

      bloc.reset();

      expect(bloc.state, isA<ProfileState>());
      expect(bloc.state.avatarStatus.isIdle, isTrue);
      expect(bloc.state.otpStatus.isIdle, isTrue);
      expect(bloc.state.submissionStatus.isIdle, isTrue);
    });

    test('a busy custom status blocks canSubmit and submit()', () async {
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
      expect(bloc.state.avatarStatus.isSubmitting, isTrue);
      expect(bloc.state.otpStatus.isSubmitting, isTrue);

      otp.complete();
      await pumpEventQueue();
      expect(bloc.state.otpStatus.isSuccess, isTrue);
      expect(bloc.state.avatarStatus.isSubmitting, isTrue);
      expect(bloc.state.isBusy, isTrue);

      upload.completeError(Exception('upload failed'));
      await pumpEventQueue();
      expect(bloc.state.avatarStatus.isFailure, isTrue);
      expect(bloc.state.otpStatus.isSuccess, isTrue);
      expect(bloc.state.isBusy, isFalse);
    });

    test('custom fields survive control updates', () {
      final bloc = ProfileBloc(avatarUpload: Completer<void>());
      addTearDown(bloc.close);

      unawaited(bloc.uploadAvatar());
      bloc.field<String>('name')!.changeValue('Ada');

      expect(bloc.state.avatarStatus.isSubmitting, isTrue);
      expect(bloc.state.values['name'], 'Ada');
    });
  });
}
```

Add this regression test at the end of the `group('MkStepFormBloc', ...)` in `test/blocs/step_form_bloc_test.dart` (it passes before and after the change; it guards the deleted `reset()` override):

```dart
    test('reset returns to step 0 and clears progress and submission', () async {
      usernameField.changeValue('u');
      emailField.changeValue('a@b.co');
      expect(await stepFormBloc.nextStep(), isTrue);
      expect(stepFormBloc.state.currentStep, 1);
      expect(stepFormBloc.state.completedSteps, {0});

      stepFormBloc.reset();

      expect(stepFormBloc.state.currentStep, 0);
      expect(stepFormBloc.state.completedSteps, isEmpty);
      expect(stepFormBloc.state.totalSteps, 3);
      expect(stepFormBloc.state.isDirty, isFalse);
      expect(stepFormBloc.state.isTouched, isFalse);
      expect(stepFormBloc.state.wasSubmitted, isFalse);
      expect(stepFormBloc.state.submissionStatus.isIdle, isTrue);
    });
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/blocs/extensible_state_test.dart`
Expected: FAIL to compile — `'isBusy'` / `'reset'` are not overridable members of `MkFormState` (`The method doesn't override an inherited method`).

- [ ] **Step 4: Implement `isBusy` and `reset()` on `MkFormState`**

In `lib/src/blocs/form/form_state.dart` replace the `canSubmit` getter and the shorthand getters block:

```dart
  /// Whether the form can currently be submitted.
  bool get canSubmit => isValid && !isValidating && !isBusy;

  /// Whether the form is busy and must not accept another submission.
  ///
  /// Defaults to [isSubmitting]. Subclasses that track other in-flight work
  /// (an avatar upload, an OTP request) override this to include it:
  ///
  /// ```dart
  /// @override
  /// bool get isBusy => super.isBusy || avatarStatus.isSubmitting;
  /// ```
  bool get isBusy => isSubmitting;

  /// Shorthand getters for submission states.
  bool get isSubmitting => submissionStatus.isSubmitting;
  bool get isSuccess => submissionStatus.isSuccess;
  bool get isFailure => submissionStatus.isFailure;
```

(`isSubmitting`, `isSuccess`, `isFailure` currently read `submissionStatus.is…`; keep them exactly as they are — the snippet above only shows the new/changed lines in context.)

Then add, after `copyWith`:

```dart
  /// Returns an idle, pristine copy of this state.
  ///
  /// Used by [MkFormBloc.reset]. It goes through [copyWith], so subclass
  /// fields are preserved; subclasses that add fields override this to return
  /// them to their defaults:
  ///
  /// ```dart
  /// @override
  /// MyState reset({required bool isValid, required bool isValidating,
  ///     required Map<String, dynamic> values}) {
  ///   return (super.reset(isValid: isValid, isValidating: isValidating,
  ///           values: values) as MyState)
  ///       .copyWith(avatarStatus: const MkSubmissionStatus.idle());
  /// }
  /// ```
  MkFormState reset({
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
    );
  }
```

- [ ] **Step 5: Override `reset()` on `MkStepFormState`**

In `lib/src/blocs/form/step_form_state.dart`, add after `copyWith` (before `props`):

```dart
  @override
  MkStepFormState reset({
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
      currentStep: 0,
      completedSteps: const {},
      isLoadingInitialData: false,
      redirectedFromStep: () => null,
      invalidStepIndex: () => null,
    );
  }
```

- [ ] **Step 6: Wire the bloc**

In `lib/src/blocs/form/form_bloc.dart`:

1. In `submit()` change the guard to:

```dart
    if (isClosed || _isSubmitInFlight || state.isBusy) return;
```

Also update the comment above it to read `// \`state.isBusy\` only flips once validation has finished, so a` (keep the rest of the comment).

2. Replace the body of `reset()`:

```dart
  /// Resets the form and all its controls to their initial states.
  ///
  /// Subclass state is preserved through [MkFormState.reset].
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
```

In `lib/src/blocs/form/step_form_bloc.dart` delete the whole `@override void reset() { … }` method at the end of `MkStepFormBloc` (the one that emits `MkStepFormState(...)`). Leave `MkSimpleStepFormBloc` untouched.

- [ ] **Step 7: Run the new and existing bloc tests**

Run: `flutter test test/blocs`
Expected: all PASS (new tests plus every existing bloc test, including the step reset regression test).

- [ ] **Step 8: Analyze and format**

Run: `dart format lib test && flutter analyze --fatal-infos`
Expected: no changes needed beyond formatting; analyzer prints `No issues found!`.

- [ ] **Step 9: Commit**

```bash
git add lib/src/blocs test/support test/blocs
git commit -m "feat(state): add overridable isBusy and reset() on MkFormState

reset() now preserves subclass state (fixes reset dropping custom fields);
submit() and canSubmit gate on isBusy so subclasses can block submission
while other calls are in flight."
```

---

### Task 2: Typed `MkFormBuilder<S>`

**Files:**
- Modify: `lib/src/ui/form_builder.dart`
- Create: `test/ui/form_builder_test.dart`

**Interfaces:**
- Consumes: `ProfileState`, `ProfileBloc` from `test/support/profile_form.dart` (Task 1); `MkFormScope.value`.
- Produces:
  - `typedef MkFormWidgetBuilder<S extends MkFormState> = Widget Function(BuildContext context, S state, MkFormBloc formBloc)`
  - `class MkFormBuilder<S extends MkFormState>` with `bool Function(S previous, S current)? buildWhen` and `MkFormWidgetBuilder<S> builder`. Throws `StateError` when the bloc's state is not an `S`.

- [ ] **Step 1: Write the failing tests**

Create `test/ui/form_builder_test.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';
import '../support/profile_form.dart';

void main() {
  group('MkFormBuilder<S>', () {
    testWidgets('delivers the custom state type and honours buildWhen', (
      tester,
    ) async {
      final upload = Completer<void>();
      final bloc = ProfileBloc(avatarUpload: upload);
      addTearDown(bloc.close);
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MkFormScope.value(
            value: bloc,
            child: MkFormBuilder<ProfileState>(
              buildWhen: (previous, current) =>
                  previous.avatarStatus != current.avatarStatus,
              builder: (context, state, formBloc) {
                builds++;
                return Text(
                  state.avatarStatus.isSubmitting ? 'uploading' : 'idle',
                );
              },
            ),
          ),
        ),
      );
      expect(find.text('idle'), findsOneWidget);
      final buildsAfterFirstFrame = builds;

      // Not part of buildWhen: must not rebuild.
      bloc.field<String>('name')!.changeValue('Ada');
      await tester.pump();
      expect(builds, buildsAfterFirstFrame);

      unawaited(bloc.uploadAvatar());
      await tester.pump();
      expect(find.text('uploading'), findsOneWidget);
    });

    testWidgets('untyped usage still receives MkFormState', (tester) async {
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
              builder: (context, state, formBloc) =>
                  Text('valid: ${state.isValid}'),
            ),
          ),
        ),
      );

      expect(find.text('valid: true'), findsOneWidget);
    });

    testWidgets('throws a StateError when the state is not an S', (
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
            child: MkFormBuilder<ProfileState>(
              builder: (context, state, formBloc) => const SizedBox(),
            ),
          ),
        ),
      );

      final error = tester.takeException();
      expect(error, isA<StateError>());
      expect(error.toString(), contains('ProfileState'));
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/ui/form_builder_test.dart`
Expected: FAIL to compile — `MkFormBuilder` is not generic (`Expected 0 type arguments`).

- [ ] **Step 3: Implement the generic builder**

Replace the contents of `lib/src/ui/form_builder.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/form_bloc.dart';
import 'form_scope.dart';

/// Function signature for building a widget based on a form state [S].
///
/// [S] defaults to [MkFormState]; use a subclass to receive a custom state
/// without casting.
typedef MkFormWidgetBuilder<S extends MkFormState> =
    Widget Function(BuildContext context, S state, MkFormBloc formBloc);

/// A reactive widget that rebuilds when the state of an [MkFormBloc] changes.
///
/// Useful for things like submit buttons that depend on form validity or
/// submission status. Prefer [MkFieldBuilder] / [MkSubformBuilder] for
/// per-field or per-section UI so typing does not rebuild the whole form.
///
/// When the form bloc uses a custom [MkFormState] subclass, pass it as the type
/// argument to receive it without casts:
///
/// ```dart
/// MkFormBuilder<ProfileFormState>(
///   buildWhen: (prev, curr) => prev.avatarStatus != curr.avatarStatus,
///   builder: (context, state, bloc) => Text('${state.avatarStatus}'),
/// )
/// ```
///
/// A [StateError] is thrown if the bloc's state is not an [S].
class MkFormBuilder<S extends MkFormState> extends StatelessWidget {
  const MkFormBuilder({
    super.key,
    this.formBloc,
    this.buildWhen,
    required this.builder,
  });

  /// The form bloc to build from. If null, it will be looked up via [MkFormScope] or [BlocProvider].
  final MkFormBloc? formBloc;

  /// Optional condition determining whether the builder should be called.
  final bool Function(S previous, S current)? buildWhen;

  /// The builder function called when the form state changes.
  final MkFormWidgetBuilder<S> builder;

  static S _typed<S extends MkFormState>(MkFormState state) {
    if (state is S) return state;
    throw StateError(
      'MkFormBuilder<$S> expected the form bloc state to be $S, '
      'but it is ${state.runtimeType}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = formBloc ?? MkFormScope.of(context);
    final condition = buildWhen;

    return BlocBuilder<MkFormBloc, MkFormState>(
      bloc: bloc,
      buildWhen: condition == null
          ? null
          : (previous, current) =>
                condition(_typed<S>(previous), _typed<S>(current)),
      builder: (context, state) => builder(context, _typed<S>(state), bloc),
    );
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/ui/form_builder_test.dart`
Expected: 3 tests PASS.

- [ ] **Step 5: Run the whole suite, analyze, format**

Run: `dart format lib test && flutter analyze --fatal-infos && flutter test`
Expected: analyzer `No issues found!`, all tests PASS (existing widget tests use `MkFormBuilder` untyped and must be unaffected).

- [ ] **Step 6: Commit**

```bash
git add lib/src/ui/form_builder.dart test/ui/form_builder_test.dart
git commit -m "feat(ui): make MkFormBuilder generic over the form state type

MkFormBuilder<S> and MkFormWidgetBuilder<S> deliver a custom MkFormState
subclass without casts. S defaults to MkFormState, so existing usage is
unchanged; a wrong type throws a descriptive StateError."
```

---

### Task 3: README and CHANGELOG

**Files:**
- Modify: `README.md` (insert a new section before `## 🪜 Multi-Step Forms & Multi-Route Wizards`)
- Modify: `CHANGELOG.md` (insert a new entry above `## [1.0.1] - 2026-09-20`)

**Interfaces:**
- Consumes: the APIs from Tasks 1–2 (documented, must match exactly).
- Produces: user-facing docs only.

- [ ] **Step 1: Insert the README section**

Use `Edit` on `README.md` with `old_string` = `## 🪜 Multi-Step Forms & Multi-Route Wizards` and `new_string` = the block below followed by a blank line and the original heading line:

````markdown
## 🧬 Extending Form State

Need more than idle / submitting / success / failure? Subclass `MkFormState` and add your own typed fields. Reuse `MkSubmissionStatus` for each independent API call, so one form can track an avatar upload, a username check and an OTP request at the same time.

### 1. Extend the state

```dart
class ProfileFormState extends MkFormState {
  const ProfileFormState({
    required super.submissionStatus,
    required super.isValid,
    required super.isValidating,
    required super.isDirty,
    required super.isTouched,
    required super.wasSubmitted,
    required super.values,
    super.submissionError,
    this.avatarStatus = const MkSubmissionStatus.idle(),
    this.otpStatus = const MkSubmissionStatus.idle(),
  });

  /// Builds the first state from the form's controls.
  factory ProfileFormState.initial(Map<String, MkControlBloc<dynamic>> controls) {
    return ProfileFormState(
      submissionStatus: const MkSubmissionStatus.idle(),
      isValid: controls.values.every((c) => c.isValid),
      isValidating: controls.values.any((c) => c.isValidating),
      isDirty: controls.values.any((c) => c.isDirty),
      isTouched: controls.values.any((c) => c.isTouched),
      wasSubmitted: false,
      values: {for (final e in controls.entries) e.key: e.value.value},
    );
  }

  final MkSubmissionStatus avatarStatus;
  final MkSubmissionStatus otpStatus;

  /// Submit is blocked while either call is running.
  @override
  bool get isBusy =>
      super.isBusy || avatarStatus.isSubmitting || otpStatus.isSubmitting;

  @override
  ProfileFormState copyWith({
    MkSubmissionStatus? submissionStatus,
    bool? isValid,
    bool? isValidating,
    bool? isDirty,
    bool? isTouched,
    bool? wasSubmitted,
    Map<String, dynamic>? values,
    Object? Function()? submissionError,
    MkSubmissionStatus? avatarStatus,
    MkSubmissionStatus? otpStatus,
  }) {
    return ProfileFormState(
      submissionStatus: submissionStatus ?? this.submissionStatus,
      isValid: isValid ?? this.isValid,
      isValidating: isValidating ?? this.isValidating,
      isDirty: isDirty ?? this.isDirty,
      isTouched: isTouched ?? this.isTouched,
      wasSubmitted: wasSubmitted ?? this.wasSubmitted,
      values: values ?? this.values,
      submissionError:
          submissionError != null ? submissionError() : this.submissionError,
      avatarStatus: avatarStatus ?? this.avatarStatus,
      otpStatus: otpStatus ?? this.otpStatus,
    );
  }

  /// Called by `MkFormBloc.reset()`; return custom fields to their defaults.
  @override
  ProfileFormState reset({
    required bool isValid,
    required bool isValidating,
    required Map<String, dynamic> values,
  }) {
    return (super.reset(
              isValid: isValid,
              isValidating: isValidating,
              values: values,
            ) as ProfileFormState)
        .copyWith(
          avatarStatus: const MkSubmissionStatus.idle(),
          otpStatus: const MkSubmissionStatus.idle(),
        );
  }

  @override
  List<Object?> get props => [...super.props, avatarStatus, otpStatus];
}
```

### 2. Use it from the bloc

Pass the state through `initialState:` and downcast `state`, exactly like `MkStepFormBloc` does:

```dart
class ProfileFormBloc extends MkFormBloc {
  ProfileFormBloc(Api api)
    : this._(api, {'username': MkFieldBloc<String>(initialValue: '')});

  ProfileFormBloc._(this._api, Map<String, MkControlBloc<dynamic>> controls)
    : super(controls: controls, initialState: ProfileFormState.initial(controls));

  final Api _api;

  @override
  ProfileFormState get state => super.state as ProfileFormState;

  Future<void> uploadAvatar(String path) async {
    emit(state.copyWith(avatarStatus: const MkSubmissionStatus.submitting()));
    try {
      final url = await _api.uploadAvatar(path);
      emit(state.copyWith(avatarStatus: MkSubmissionStatus.success(url)));
    } catch (error) {
      emit(state.copyWith(avatarStatus: MkSubmissionStatus.failure(error)));
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

> The redirecting constructor (`: this._(...)`) is needed because the controls must exist before `super(...)` so the initial state can be computed from them. Field edits never lose your custom fields: `MkFormBloc` updates state through `copyWith`.

### 3. Build the UI without casts

```dart
MkFormBuilder<ProfileFormState>(
  buildWhen: (prev, curr) => prev.avatarStatus != curr.avatarStatus,
  builder: (context, state, bloc) => switch (state.avatarStatus) {
    MkSubmissionInProgress() => const CircularProgressIndicator(),
    MkSubmissionSuccess(:final response) => Image.network('$response'),
    MkSubmissionFailure(:final error) => Text('$error'),
    MkSubmissionIdle() => const SizedBox.shrink(),
  },
)
```

`MkFormBuilder<S>` throws a `StateError` if the bloc's state is not an `S`. Without a type argument it behaves exactly as before.

| Member | Purpose |
|---|---|
| `MkFormState.isBusy` | Override to include your own in-flight work; drives `canSubmit` and blocks `submit()` |
| `MkFormState.reset(...)` | Override to return custom fields to defaults; called by `MkFormBloc.reset()` |
| `MkFormBuilder<S>` | Typed access to the custom state |

````

- [ ] **Step 2: Add the CHANGELOG entry**

Use `Edit` on `CHANGELOG.md` with `old_string` = `## [1.0.1] - 2026-09-20` and `new_string`:

```markdown
## [1.1.0] - Unreleased

### Added
- **Extensible form state.** `MkFormState` can be subclassed with your own typed status fields, so one form can track several independent API calls (upload, availability check, OTP) or extra statuses. See "Extending Form State" in the README.
  - `MkFormState.isBusy` — overridable; `canSubmit` and `MkFormBloc.submit()` now respect it, so in-flight side calls can block submission.
  - `MkFormState.reset(...)` — overridable; `MkFormBloc.reset()` uses it to keep subclass state.
  - `MkFormBuilder<S extends MkFormState>` and `MkFormWidgetBuilder<S>` — receive the custom state type without casts (`S` defaults to `MkFormState`, so existing code is unchanged).

### Fixed
- `MkFormBloc.reset()` dropped subclass state by emitting a plain `MkFormState`. `MkStepFormBloc` no longer needs its own `reset()` override.

---

## [1.0.1] - 2026-09-20
```

Note the file already has a `---` separator between entries in the existing style; keep exactly one `---` between `[1.1.0]` and `[1.0.1]` (the new block ends with its own `---` and the old heading follows it). If the old heading was preceded by a `---` already, do not add a second one above the new entry.

- [ ] **Step 3: Verify the docs render sensibly**

Run: `grep -n "Extending Form State\|## \[1.1.0\]" README.md CHANGELOG.md && sed -n 1,20p CHANGELOG.md`
Expected: one README match, one CHANGELOG match, header and entries in order, a single `---` between entries.

- [ ] **Step 4: Commit**

```bash
git add README.md CHANGELOG.md
git commit -m "docs: document extending form state and add 1.1.0 changelog entry"
```

---

### Task 4: Example screen (profile form with three concurrent calls and a multi-call submit)

**Files:**
- Modify: `example/lib/data/client/api_client.dart`
- Modify: `example/lib/data/client/mock_api_client.dart`
- Create: `example/lib/data/repositories/profile_repository.dart`
- Create: `example/lib/presentation/features/extended_state/bloc/profile_form_state.dart`
- Create: `example/lib/presentation/features/extended_state/bloc/profile_form_bloc.dart`
- Create: `example/lib/presentation/features/extended_state/extended_state_screen.dart`
- Modify: `example/lib/core/router/app_router.dart`
- Modify: `example/lib/presentation/screens/home_screen.dart`
- Regenerate: `example/lib/core/di/injection.config.dart`, `example/lib/core/router/app_router.gr.dart`

**Interfaces:**
- Consumes: `MkFormState.isBusy/reset`, `MkFormBuilder<S>`, `MkSubmissionStatus` (Tasks 1–2); existing `ApiClient.checkUsernameAvailability(String)`.
- Produces:
  - `ApiClient.uploadAvatar(String fileName) → Future<String>`, `sendOtp(String phone) → Future<void>`, `saveProfile(Map<String, dynamic>) → Future<Map<String, dynamic>>`
  - `ProfileRepository` (`isUsernameAvailable`, `uploadAvatar`, `sendOtp`, `saveProfile`)
  - `ProfileFormState` (`avatarStatus`, `usernameStatus`, `otpStatus`), `ProfileFormBloc` (`uploadAvatar(fileName)`, `checkUsername()`, `sendOtp()`)
  - `ExtendedStateScreen` / `ExtendedStateRoute`

- [ ] **Step 1: Extend the API client**

Append to the `ApiClient` abstract class in `example/lib/data/client/api_client.dart` (before the closing brace):

```dart

  /// Uploads an avatar image and returns its public URL.
  Future<String> uploadAvatar(String fileName);

  /// Sends a one-time passcode to [phone].
  Future<void> sendOtp(String phone);

  /// Persists the profile and returns the saved record.
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile);
```

Append to `MockApiClient` in `example/lib/data/client/mock_api_client.dart` (before the closing brace):

```dart

  @override
  Future<String> uploadAvatar(String fileName) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (fileName.contains('fail')) {
      throw Exception('Upload failed: file rejected by server');
    }
    return 'https://example.com/avatars/$fileName';
  }

  @override
  Future<void> sendOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<Map<String, dynamic>> saveProfile(
    Map<String, dynamic> profile,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return {'id': 'profile-1', ...profile};
  }
```

- [ ] **Step 2: Add the repository**

Create `example/lib/data/repositories/profile_repository.dart`:

```dart
import 'package:injectable/injectable.dart';
import '../client/api_client.dart';

/// Repository for the profile form's independent API calls.
abstract class ProfileRepository {
  Future<bool> isUsernameAvailable(String username);
  Future<String> uploadAvatar(String fileName);
  Future<void> sendOtp(String phone);
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile);
}

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<bool> isUsernameAvailable(String username) =>
      _client.checkUsernameAvailability(username);

  @override
  Future<String> uploadAvatar(String fileName) =>
      _client.uploadAvatar(fileName);

  @override
  Future<void> sendOtp(String phone) => _client.sendOtp(phone);

  @override
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile) =>
      _client.saveProfile(profile);
}
```

- [ ] **Step 3: Add the extended state**

Create `example/lib/presentation/features/extended_state/bloc/profile_form_state.dart`:

```dart
import 'package:mk_forms/mk_forms.dart';

/// Form state extended with one status per independent API call.
class ProfileFormState extends MkFormState {
  const ProfileFormState({
    required super.submissionStatus,
    required super.isValid,
    required super.isValidating,
    required super.isDirty,
    required super.isTouched,
    required super.wasSubmitted,
    required super.values,
    super.submissionError,
    this.avatarStatus = const MkSubmissionStatus.idle(),
    this.usernameStatus = const MkSubmissionStatus.idle(),
    this.otpStatus = const MkSubmissionStatus.idle(),
  });

  factory ProfileFormState.initial(
    Map<String, MkControlBloc<dynamic>> controls,
  ) {
    return ProfileFormState(
      submissionStatus: const MkSubmissionStatus.idle(),
      isValid: controls.values.every((c) => c.isValid),
      isValidating: controls.values.any((c) => c.isValidating),
      isDirty: controls.values.any((c) => c.isDirty),
      isTouched: controls.values.any((c) => c.isTouched),
      wasSubmitted: false,
      values: {for (final e in controls.entries) e.key: e.value.value},
    );
  }

  /// Avatar upload; the success response is the uploaded URL.
  final MkSubmissionStatus avatarStatus;

  /// Username availability check; the success response is a `bool`.
  final MkSubmissionStatus usernameStatus;

  /// OTP request.
  final MkSubmissionStatus otpStatus;

  /// Submit is blocked while any side call is running.
  @override
  bool get isBusy =>
      super.isBusy ||
      avatarStatus.isSubmitting ||
      usernameStatus.isSubmitting ||
      otpStatus.isSubmitting;

  @override
  ProfileFormState copyWith({
    MkSubmissionStatus? submissionStatus,
    bool? isValid,
    bool? isValidating,
    bool? isDirty,
    bool? isTouched,
    bool? wasSubmitted,
    Map<String, dynamic>? values,
    Object? Function()? submissionError,
    MkSubmissionStatus? avatarStatus,
    MkSubmissionStatus? usernameStatus,
    MkSubmissionStatus? otpStatus,
  }) {
    return ProfileFormState(
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
      avatarStatus: avatarStatus ?? this.avatarStatus,
      usernameStatus: usernameStatus ?? this.usernameStatus,
      otpStatus: otpStatus ?? this.otpStatus,
    );
  }

  @override
  ProfileFormState reset({
    required bool isValid,
    required bool isValidating,
    required Map<String, dynamic> values,
  }) {
    return (super.reset(
              isValid: isValid,
              isValidating: isValidating,
              values: values,
            )
            as ProfileFormState)
        .copyWith(
          avatarStatus: const MkSubmissionStatus.idle(),
          usernameStatus: const MkSubmissionStatus.idle(),
          otpStatus: const MkSubmissionStatus.idle(),
        );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    avatarStatus,
    usernameStatus,
    otpStatus,
  ];
}
```

- [ ] **Step 4: Add the bloc**

Create `example/lib/presentation/features/extended_state/bloc/profile_form_bloc.dart`:

```dart
import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../data/repositories/profile_repository.dart';
import 'profile_form_state.dart';

/// Profile form with three independent API calls plus a multi-call submit.
@injectable
class ProfileFormBloc extends MkFormBloc {
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
  ) : super(controls: controls, initialState: ProfileFormState.initial(controls));

  final ProfileRepository _repository;

  @override
  ProfileFormState get state => super.state as ProfileFormState;

  /// Uploads an avatar; independent of the other calls.
  Future<void> uploadAvatar(String fileName) => _track(
    () => _repository.uploadAvatar(fileName),
    (status) => state.copyWith(avatarStatus: status),
  );

  /// Checks whether the typed username is available.
  Future<void> checkUsername() => _track(() {
    final username = (values['username'] as String?)?.trim() ?? '';
    if (username.isEmpty) {
      throw Exception('Enter a username first');
    }
    return _repository.isUsernameAvailable(username);
  }, (status) => state.copyWith(usernameStatus: status));

  /// Sends a one-time passcode to the typed phone number.
  Future<void> sendOtp() => _track(() async {
    final phone = (values['phone'] as String?)?.trim() ?? '';
    if (phone.isEmpty) {
      throw Exception('Enter a phone number first');
    }
    await _repository.sendOtp(phone);
    return null;
  }, (status) => state.copyWith(otpStatus: status));

  Future<void> _track(
    Future<Object?> Function() call,
    ProfileFormState Function(MkSubmissionStatus status) apply,
  ) async {
    emit(apply(const MkSubmissionStatus.submitting()));
    try {
      final response = await call();
      emit(apply(MkSubmissionStatus.success(response)));
    } catch (error) {
      emit(apply(MkSubmissionStatus.failure(error)));
    }
  }

  /// A single submit that chains two API calls.
  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    final username = values['username'] as String;
    final available = await _repository.isUsernameAvailable(username);
    if (!available) {
      throw Exception('Username "$username" is already taken');
    }
    final avatar = state.avatarStatus;
    return _repository.saveProfile({
      ...values,
      'avatarUrl': avatar is MkSubmissionSuccess ? avatar.response : null,
    });
  }
}
```

- [ ] **Step 5: Add the screen**

Create `example/lib/presentation/features/extended_state/extended_state_screen.dart`:

```dart
import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/profile_form_bloc.dart';
import 'bloc/profile_form_state.dart';

/// Demonstrates extending [MkFormState] with several independent statuses.
///
/// - Avatar upload, username check and OTP request run concurrently, each with
///   its own status field on [ProfileFormState].
/// - The submit button is disabled while any of them is running (`isBusy`).
/// - Submitting chains two API calls inside `onSubmit`.
@RoutePage()
class ExtendedStateScreen extends StatefulWidget {
  const ExtendedStateScreen({super.key, ProfileFormBloc? formBloc})
    : _formBloc = formBloc;

  final ProfileFormBloc? _formBloc;

  @override
  State<ExtendedStateScreen> createState() => _ExtendedStateScreenState();
}

class _ExtendedStateScreenState extends State<ExtendedStateScreen> {
  late final ProfileFormBloc _formBloc;

  @override
  void initState() {
    super.initState();
    _formBloc = widget._formBloc ?? getIt<ProfileFormBloc>();
  }

  @override
  void dispose() {
    unawaited(_formBloc.close());
    super.dispose();
  }

  void _snack(BuildContext context, String message, {Color? color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extended Form State')),
      body: MkFormScope.value(
        value: _formBloc,
        child: MkFormListener(
          formBloc: _formBloc,
          onSuccess: (context, response) =>
              _snack(context, 'Profile saved', color: Colors.green),
          onFailure: (context, error) =>
              _snack(context, 'Save failed: $error', color: Colors.red),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const MkTextField(
                name: 'displayName',
                decoration: InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 16),
              const MkTextField(
                name: 'username',
                decoration: InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 8),
              MkFormBuilder<ProfileFormState>(
                buildWhen: (prev, curr) =>
                    prev.usernameStatus != curr.usernameStatus,
                builder: (context, state, bloc) => _CallRow(
                  label: 'Check availability',
                  status: state.usernameStatus,
                  onPressed: () => unawaited(_formBloc.checkUsername()),
                  successText: (response) =>
                      response == true ? 'Available' : 'Taken',
                ),
              ),
              const SizedBox(height: 16),
              const MkTextField(
                name: 'phone',
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 8),
              MkFormBuilder<ProfileFormState>(
                buildWhen: (prev, curr) => prev.otpStatus != curr.otpStatus,
                builder: (context, state, bloc) => _CallRow(
                  label: 'Send code',
                  status: state.otpStatus,
                  onPressed: () => unawaited(_formBloc.sendOtp()),
                  successText: (_) => 'Code sent',
                ),
              ),
              const SizedBox(height: 16),
              MkFormBuilder<ProfileFormState>(
                buildWhen: (prev, curr) =>
                    prev.avatarStatus != curr.avatarStatus,
                builder: (context, state, bloc) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton.tonal(
                          onPressed: state.avatarStatus.isSubmitting
                              ? null
                              : () => unawaited(
                                  _formBloc.uploadAvatar('avatar.png'),
                                ),
                          child: const Text('Upload avatar'),
                        ),
                        FilledButton.tonal(
                          onPressed: state.avatarStatus.isSubmitting
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
                      state.avatarStatus,
                      successText: (response) => 'Uploaded: $response',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              MkFormBuilder<ProfileFormState>(
                buildWhen: (prev, curr) => prev.isBusy != curr.isBusy,
                builder: (context, state, bloc) => FilledButton(
                  onPressed: state.isBusy ? null : () => unawaited(bloc.submit()),
                  child: state.isBusy
                      ? const Text('Working…')
                      : const Text('Save profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({
    required this.label,
    required this.status,
    required this.onPressed,
    this.successText,
  });

  final String label;
  final MkSubmissionStatus status;
  final VoidCallback onPressed;
  final String Function(Object? response)? successText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.tonal(
          onPressed: status.isSubmitting ? null : onPressed,
          child: Text(label),
        ),
        const SizedBox(width: 12),
        Expanded(child: _CallStatusText(status, successText: successText)),
      ],
    );
  }
}

class _CallStatusText extends StatelessWidget {
  const _CallStatusText(this.status, {this.successText});

  final MkSubmissionStatus status;
  final String Function(Object? response)? successText;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MkSubmissionIdle() => const SizedBox.shrink(),
      MkSubmissionInProgress() => const Text('Working…'),
      MkSubmissionSuccess(:final response) => Text(
        successText?.call(response) ?? 'Done',
        style: const TextStyle(color: Colors.green),
      ),
      MkSubmissionFailure(:final error) => Text(
        '$error',
        style: const TextStyle(color: Colors.red),
      ),
    };
  }
}
```

- [ ] **Step 6: Register the route and home entry**

In `example/lib/core/router/app_router.dart` add after `AutoRoute(page: AutovalidateRoute.page),`:

```dart
    AutoRoute(page: ExtendedStateRoute.page),
```

In `example/lib/presentation/screens/home_screen.dart` add after the `Autovalidate Modes` record (inside the `features` list, before the closing `];`):

```dart
          (
            title: 'Extended Form State',
            subtitle:
                'Custom state with several concurrent API calls and a multi-call submit',
            icon: Icons.account_tree_outlined,
            color: Colors.orange.shade800,
            route: ExtendedStateRoute(),
          ),
```

- [ ] **Step 7: Regenerate DI and routes**

Run:

```bash
cd example && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```

Expected: build succeeds; `injection.config.dart` now registers `ProfileRepository` and `ProfileFormBloc`; `app_router.gr.dart` defines `ExtendedStateRoute`.

- [ ] **Step 8: Format and analyze the example**

Run:

```bash
cd example && dart format lib && flutter analyze --fatal-infos
```

Expected: `No issues found!`. If the analyzer flags a `switch` exhaustiveness or a lint in the new files, fix it in the new files (do not edit generated files by hand).

- [ ] **Step 9: Exercise the screen once**

Run the example (e.g. `cd example && flutter run -d chrome`), open "Extended Form State" and check:
1. Tap "Upload avatar" then "Check availability" while the upload runs: both show "Working…" independently and "Save profile" is disabled until both finish.
2. "Upload failing avatar" shows a red error; the form stays usable.
3. Username `admin` shows "Taken"; saving with `admin` fails with a red snackbar (second call in the submit). A free username saves.

Report what you actually observed. If you cannot run the app in this environment, say so explicitly rather than claiming it works.

- [ ] **Step 10: Commit**

```bash
git add example
git commit -m "docs(example): add extended form state screen

Profile form with independent avatar/username/OTP statuses on a custom
MkFormState, isBusy-gated submit and a two-call onSubmit."
```

---

### Task 5: Full verification

**Files:** none (verification only).

- [ ] **Step 1: Run the CI gates from the repo root**

Run:

```bash
dart format --output=none --set-exit-if-changed . && flutter analyze --fatal-infos && flutter test
```

Expected: format check exits 0 with no changes, analyzer `No issues found!`, all tests PASS. If format check fails, run `dart format .`, re-run, and commit the formatting as `style: apply dart format`.

- [ ] **Step 2: Confirm backward compatibility**

Run: `grep -rn "MkFormBuilder\|MkFormWidgetBuilder" lib example/lib test --include=*.dart | grep -v "form_builder.dart\|form_builder_test.dart\|extended_state_screen.dart"`
Expected: every remaining usage is untyped and compiles (already proven by the full test run and example analyze).

- [ ] **Step 3: Confirm nothing out of scope changed**

Run: `git diff main --stat && git diff main -- pubspec.yaml`
Expected: no `pubspec.yaml` diff (version untouched); changed files match the File Structure table plus the regenerated example files.

- [ ] **Step 4: Report**

Summarize for the maintainer: what changed, the exact commands run and their results, whether the example screen was run manually, and that the version bump and publish are left to them.
