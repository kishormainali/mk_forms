# mk_forms 🚀

A reactive, type-safe, and highly performant Flutter form management library powered by [`flutter_bloc`](https://pub.dev/packages/flutter_bloc). Designed to handle everything from **minimal login forms** to **complex enterprise workflows** — multi-step wizards, multi-route onboarding, independent subforms, dynamic field arrays, cross-field validation, async validation, and autovalidation — with zero boilerplate and surgically fine-grained UI rebuilds.

[![pub version](https://img.shields.io/pub/v/mk_forms.svg)](https://pub.dev/packages/mk_forms)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/kishormainali/mk_forms/actions/workflows/ci.yml/badge.svg)](https://github.com/kishormainali/mk_forms/actions/workflows/ci.yml)

---

## ✨ Features at a Glance

| Feature | Description |
|---|---|
| ⚡ **Fine-grained rebuilds** | Typing in one field only rebuilds that widget — never the whole screen |
| 🎯 **Zero-boilerplate minimal forms** | `MkSimpleFormBloc` without needing a custom class |
| 🪜 **Multi-step & multi-route wizards** | `MkStepFormBloc` with step validation gating across Navigator routes |
| 🌐 **Remote draft hydration** | `loadInitialData()` + `populateValues()` — pristine fields, no premature errors |
| 📦 **Independent subforms** | `MkSubformBuilder` + `validateGroup()` for isolated section validation |
| 🔄 **Cross-field reactive validation** | `dependsOn: [otherField]` auto-revalidates without recursion loops |
| ⏳ **Debounced async validation** | Built-in debounce, cancels stale in-flight requests automatically |
| 🛡️ **Pristine initial state** | Errors never appear on load — only after touch or submit |
| 🧹 **Clean submission lifecycle** | Stale server errors are auto-cleared when user edits |
| ✅ **AutovalidateMode** | Per-scope or per-field: `always`, `onUserInteraction`, `onUnfocus`, `disabled` |
| 🌍 **Full i18n** | `MkFormLocalizations.delegate`, scoped overrides, runtime locale switching |
| 📋 **Dynamic field arrays** | `MkArrayBloc` — add, insert, remove, reorder |
| 🎨 **Rich widget suite** | Text, Email, Password, Checkbox, Radio, Dropdown, MultiSelect, custom builder |

---

## 📦 Installation

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  mk_forms: ^1.0.1
```

For i18n support, add `flutter_localizations` and configure your `MaterialApp`:

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

---

## 🚀 Quick Start — Minimal Login Form

For simple forms use `MkSimpleFormBloc` — no subclass required:

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final MkSimpleFormBloc _form;

  @override
  void initState() {
    super.initState();
    _form = MkSimpleFormBloc(
      controls: {
        'email': MkFieldBloc<String>(
          validators: [MkValidators.required(), MkValidators.email()],
        ),
        'password': MkFieldBloc<String>(
          validators: [MkValidators.required(), MkValidators.minLength(6)],
        ),
      },
      onSubmit: (values) async {
        await authRepository.signIn(
          values['email'] as String,
          values['password'] as String,
        );
      },
    );
  }

  @override
  void dispose() {
    _form.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MkFormScope.value(
        value: _form,
        child: MkFormListener(
          formBloc: _form,
          onSuccess: (context, _) =>
              Navigator.pushReplacementNamed(context, '/home'),
          onFailure: (context, error) => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$error'))),
          child: Column(
            children: [
              const MkEmailField(name: 'email'),
              const SizedBox(height: 16),
              const MkPasswordField(name: 'password'),
              const SizedBox(height: 24),
              BlocBuilder<MkFormBloc, MkFormState>(
                bloc: _form,
                builder: (context, state) => FilledButton(
                  onPressed: state.isSubmitting ? null : _form.submit,
                  child: state.isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🧠 Core Concepts

### Field Blocs (`MkFieldBloc<T>`)

Every form field is powered by an `MkFieldBloc<T>` — a reactive BLoC managing value, validation, dirty/touched state, and async validation.

```dart
// String field with sync validators
final username = MkFieldBloc<String>(
  initialValue: '',
  validators: [
    MkValidators.required(),
    MkValidators.minLength(3),
    MkValidators.maxLength(20),
  ],
);

// Numeric field
final age = MkFieldBloc<int>(
  validators: [MkValidators.required(), MkValidators.min(18)],
);

// Boolean field (checkbox / toggle)
final agreeTerms = MkFieldBloc<bool>(
  validators: [MkValidators.required()], // required() treats false as invalid
);

// Multi-value field
final interests = MkFieldBloc<List<String>>(
  validators: [MkValidators.required()],
);
```

**Key properties on `MkFieldState<T>`:**

| Property | Type | Description |
|---|---|---|
| `value` | `T?` | Current value |
| `initialValue` | `T?` | Value at creation/reset |
| `error` | `String?` | Current validation error |
| `isDirty` | `bool` | Value changed from `initialValue` (collections compare by contents) |
| `isTouched` | `bool` | User has interacted with the field |
| `isValidating` | `bool` | Async validation in progress |
| `isValid` | `bool` | No error and not validating |
| `wasFormSubmitted` | `bool` | Form submission was attempted |
| `showError` | `bool` | Convenience getter — `shouldShowError()` with default mode |
| `shouldShowError([mode])` | `bool` | Whether to display error per `AutovalidateMode` |

---

### Form Blocs

#### `MkSimpleFormBloc` — Inline submit handler

```dart
final form = MkSimpleFormBloc(
  controls: {
    'name': MkFieldBloc<String>(validators: [MkValidators.required()]),
  },
  onSubmit: (values) async => api.save(values),
  onSubmitSuccess: (response) => print('Saved: $response'),
  onSubmitFailure: (error) => print('Error: $error'),
);
```

#### `MkFormBloc` — Custom subclass

```dart
class RegistrationFormBloc extends MkFormBloc {
  RegistrationFormBloc()
      : super(controls: {
          'email': MkFieldBloc<String>(
            validators: [MkValidators.required(), MkValidators.email()],
          ),
          'password': MkFieldBloc<String>(
            validators: [MkValidators.required(), MkValidators.minLength(8)],
          ),
        });

  @override
  Future<void> onSubmit(Map<String, dynamic> values) async {
    await authRepository.register(
      email: values['email'] as String,
      password: values['password'] as String,
    );
  }

  @override
  void onSubmitSuccess(dynamic _) {
    // Navigate, show banner, etc.
  }

  @override
  void onSubmitFailure(Object error) {
    // Map server errors to fields
    if (error is ApiException && error.fieldErrors != null) {
      setFieldErrors(error.fieldErrors!);
    }
  }
}
```

**Key `MkFormBloc` methods:**

| Method | Description |
|---|---|
| `submit()` | Validate all fields then invoke `onSubmit` |
| `reset()` | Reset form and all controls to initial state |
| `populateValues(data)` | Hydrate fields from API data, optionally marks pristine |
| `setFieldErrors(Map<String, String>)` | Map server field errors onto controls |
| `validateGroup(name)` | Validate only a named group/subform |
| `validateControls([names])` | Validate a specific subset of controls |
| `field<T>(name)` | Look up a typed `MkFieldBloc<T>` by name |
| `control<C>(name)` | Look up any `MkControlBloc` by name |

---

### `MkFormScope` & Context Extensions

`MkFormScope` is built on `BlocProvider`, so it provides the form bloc (as `MkFormBloc`, reachable via `context.read<MkFormBloc>()` too) and a default `AutovalidateMode` down the tree. Like `BlocProvider`, it has two constructors:

```dart
// The scope creates the bloc and closes it when removed from the tree.
MkFormScope(
  create: (context) => LoginFormBloc(),
  lazy: true, // default
  autovalidateMode: AutovalidateMode.onUserInteraction, // default
  child: MyFormWidget(),
)

// The scope exposes an existing bloc (e.g. owned by a State) and never closes it.
MkFormScope.value(
  value: myFormBloc,
  child: MyFormWidget(),
)
```

**Context extensions** (available anywhere inside `MkFormScope`):

```dart
// Access the form bloc
context.mkForm.submit();

// Access a field by name
final emailField = context.mkField<String>('email');

// Access the active autovalidate mode
final mode = context.mkAutovalidateMode;
```

---

### `MkFormBuilder`

Rebuilds when the form state changes — handy for submit buttons. Use `buildWhen` to limit rebuilds:

```dart
MkFormBuilder(
  formBloc: _form, // optional: falls back to MkFormScope lookup
  buildWhen: (prev, curr) =>
      prev.isValid != curr.isValid ||
      prev.submissionStatus != curr.submissionStatus,
  builder: (context, state, form) => FilledButton(
    onPressed: state.isValid && !state.submissionStatus.isSubmitting
        ? form.submit
        : null,
    child: const Text('Submit'),
  ),
)
```

---

### `MkFormListener`

Listens to submission status transitions without causing rebuilds of its subtree:

```dart
MkFormListener(
  formBloc: _form, // optional: falls back to MkFormScope lookup
  onSubmitting: (context) => showLoadingDialog(context),
  onSuccess: (context, response) {
    hideLoadingDialog(context);
    context.go('/dashboard'); // auto_route / go_router
  },
  onFailure: (context, error) {
    hideLoadingDialog(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  },
  child: MyFormBody(),
)
```

---

## ✅ AutovalidateMode

Control when field errors are surfaced to the user — at the scope level or per-field.

### Scope-Level Mode

```dart
MkFormScope.value(
  value: _form,
  autovalidateMode: AutovalidateMode.always, // Show errors immediately even on pristine fields
  child: MyForm(),
)
```

### Per-Field Override

```dart
MkTextField(
  name: 'username',
  autovalidateMode: AutovalidateMode.disabled, // Only show after submit
)
```

### Mode Reference

| Mode | When error is shown |
|---|---|
| `AutovalidateMode.always` | Immediately, even before any interaction |
| `AutovalidateMode.onUserInteraction` *(default)* | After touch (`isTouched`) **or** after submit attempt |
| `AutovalidateMode.onUnfocus` | After the field loses focus **or** after submit attempt |
| `AutovalidateMode.onUserInteractionIfError` | Same as `onUserInteraction` |
| `AutovalidateMode.disabled` | Only after submit attempt (`wasFormSubmitted`) |

### Custom Widget Integration

When building custom fields with `MkFieldBuilder`, use `shouldShowError(mode)`:

```dart
MkFieldBuilder<String>(
  fieldBloc: _form.field<String>('username')!,
  builder: (context, state, bloc) {
    final mode = context.mkAutovalidateMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => _form.field<String>('username')!.changeValue(v),
          decoration: InputDecoration(
            errorText: state.shouldShowError(mode) ? state.error : null,
          ),
        ),
      ],
    );
  },
)
```

---

## 🧩 Built-in Validators

```dart
// Required (null, empty string, empty list, false bool — all invalid)
MkValidators.required()
MkValidators.required('Please fill this field') // custom message

// String validators
MkValidators.email()
MkValidators.minLength(3)
MkValidators.maxLength(100)
MkValidators.pattern(RegExp(r'^\d+$'), 'Numbers only')

// Numeric validators
MkValidators.min(18)
MkValidators.max(120)

// Match / confirm (for password confirmation)
MkValidators.match(() => passwordField.value, 'Passwords do not match')
MkValidators.matchControl(passwordField, 'Passwords do not match')

// Compose multiple validators (returns first error)
MkValidators.compose([MkValidators.required(), MkValidators.email()])

// Compose multiple async validators
MkValidators.composeAsync([checkUsername, checkProfanity])
```

---

## 🔄 Cross-Field Dependent Validation

Use `dependsOn` to automatically revalidate a field when another field changes — no infinite loops:

```dart
final password = MkFieldBloc<String>(
  validators: [MkValidators.required(), MkValidators.minLength(8)],
);

final confirmPassword = MkFieldBloc<String>(
  validators: [
    MkValidators.required(),
    MkValidators.matchControl(password, 'Passwords do not match'),
  ],
  dependsOn: [password], // ← Auto-revalidates when password changes
);

// When password changes → confirmPassword revalidates immediately
// When confirmPassword changes → password does NOT revalidate (no loop)
```

A dependent field revalidates when the dependency's **value** changes (not when it merely re-validates).
Synchronous validators re-run immediately; async validators are debounced like after `changeValue`, and
adding `dependsOn` never fires an async validator (a network call) on its own at construction.

---

## ⏳ Debounced Async Validation

Check uniqueness or availability with automatic debouncing and stale request cancellation:

```dart
final username = MkFieldBloc<String>(
  validators: [MkValidators.required(), MkValidators.minLength(3)],
  asyncValidators: [
    (val) async {
      final available = await userRepository.checkUsernameAvailable(val!);
      return available ? null : 'Username is already taken';
    },
  ],
  debounceTime: const Duration(milliseconds: 400),
);
```

If an async validator **throws** (e.g. the network is down), the field becomes invalid with a generic,
localized message (`MkErrorCodes.asyncValidationFailed`) instead of the raw exception text. The original
error is reported through the field's `onError` / `BlocObserver.onError` so you can log it. Return a
string from the validator for errors you want users to see.

Display async validation state in the UI:

```dart
MkFieldBuilder<String>(
  fieldBloc: _form.field<String>('username')!,
  builder: (context, state, bloc) {
    return TextField(
      decoration: InputDecoration(
        suffixIcon: state.isValidating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : state.isValid && state.isTouched
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
        errorText: state.showError ? state.error : null,
      ),
    );
  },
)
```

---

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
MkFormStateBuilder<ProfileFormState>(
  buildWhen: (prev, curr) => prev.avatarStatus != curr.avatarStatus,
  builder: (context, state, bloc) => switch (state.avatarStatus) {
    MkSubmissionInProgress() => const CircularProgressIndicator(),
    MkSubmissionSuccess(:final response) => Image.network('$response'),
    MkSubmissionFailure(:final error) => Text('$error'),
    MkSubmissionIdle() => const SizedBox.shrink(),
  },
)
```

`MkFormStateBuilder<S>` throws a `StateError` if the bloc's state is not an `S`. Without a type argument it behaves exactly as before.

| Member | Purpose |
|---|---|
| `MkFormState.isBusy` | Override to include your own in-flight work; drives `canSubmit` and blocks `submit()` |
| `MkFormState.reset(...)` | Override to return custom fields to defaults; called by `MkFormBloc.reset()` |
| `MkFormStateBuilder<S>` | Typed access to the custom state |

## 🪜 Multi-Step Forms & Multi-Route Wizards

### Define the Bloc

```dart
class OnboardingFormBloc extends MkStepFormBloc {
  OnboardingFormBloc()
      : super(
          controls: {
            // Step 0 — Account
            'username': MkFieldBloc<String>(validators: [MkValidators.required()]),
            'email': MkFieldBloc<String>(
              validators: [MkValidators.required(), MkValidators.email()],
            ),
            // Step 1 — Profile
            'fullName': MkFieldBloc<String>(validators: [MkValidators.required()]),
            'role': MkFieldBloc<String>(initialValue: 'developer'),
            // Step 2 — Preferences
            'interests': MkFieldBloc<List<String>>(validators: [MkValidators.required()]),
            'agreeTerms': MkFieldBloc<bool>(validators: [MkValidators.required()]),
          },
          steps: const [
            MkFormStep(controlNames: ['username', 'email'], title: 'Account'),
            MkFormStep(controlNames: ['fullName', 'role'], title: 'Profile'),
            MkFormStep(
              controlNames: ['interests', 'agreeTerms'],
              title: 'Preferences',
            ),
          ],
        );

  @override
  Future<void> onSubmit(Map<String, dynamic> values) async {
    await onboardingRepository.complete(values);
  }
}
```

### Step 0 Screen — Validate & Navigate

```dart
// Only validates Step 0's fields — Step 1 and 2 remain pristine
final canProceed = await formBloc.nextStep();
if (canProceed && context.mounted) {
  context.pushRoute(const OnboardingStep1Route()); // auto_route
}
```

### Load Draft From API

```dart
@override
void initState() {
  super.initState();
  _formBloc.loadInitialData(
    () => draftRepository.fetchDraft(),
    resolveInitialStep: (data) => data['lastCompletedStep'] as int? ?? 0,
  );
}
```

**Smart redirect behavior:** If the API draft has values for Step 2 but Step 0 has a validation issue (e.g. a missing required field), `loadInitialData` automatically:
1. Populates all step values (pristine — no premature errors)
2. Detects the earliest invalid step
3. Redirects to that step and **shows errors only on that step**
4. Marks previous valid steps as completed

### Listen to Loading State

```dart
BlocBuilder<OnboardingFormBloc, MkStepFormState>(
  bloc: _formBloc,
  builder: (context, state) {
    if (state.isLoadingInitialData) {
      return const Center(child: CircularProgressIndicator());
    }
    return MyStepContent(currentStep: state.currentStep);
  },
)
```

### Step Navigation Methods

```dart
formBloc.nextStep();          // Validate current step → advance if valid
formBloc.previousStep();      // Go back unconditionally
formBloc.goToStep(2);         // Jump to step 2 (validates intermediate steps if going forward)
formBloc.validateStep(0);     // Validate step 0 controls only
```

### `MkSimpleStepFormBloc` — Inline Handler

```dart
final form = MkSimpleStepFormBloc(
  controls: { /* ... */ },
  steps: [ /* ... */ ],
  onSubmit: (values) async => api.submit(values),
);
```

---

## 📦 Independent Subforms

Group form sections so that validating Shipping never touches Billing fields:

### Define Subforms

```dart
final formBloc = MkSimpleFormBloc(
  controls: {
    'shipping': MkGroupBloc({
      'street': MkFieldBloc<String>(validators: [MkValidators.required()]),
      'city': MkFieldBloc<String>(validators: [MkValidators.required()]),
      'zip': MkFieldBloc<String>(validators: [MkValidators.required()]),
    }),
    'billing': MkGroupBloc({
      'street': MkFieldBloc<String>(validators: [MkValidators.required()]),
      'city': MkFieldBloc<String>(validators: [MkValidators.required()]),
      'zip': MkFieldBloc<String>(validators: [MkValidators.required()]),
    }),
  },
  onSubmit: (values) async => checkoutRepository.placeOrder(values),
);

// Validate ONLY shipping — billing fields stay pristine
final shippingValid = await formBloc.validateGroup('shipping');
```

### Build Subforms Efficiently

```dart
MkFormScope.value(
  value: formBloc,
  child: Column(
    children: [
      // Changes in shipping NEVER rebuild billing and vice versa
      MkSubformBuilder(
        name: 'shipping',
        builder: (context, state, groupBloc) => Column(
          children: [
            Text('Shipping', style: Theme.of(context).textTheme.titleMedium),
            MkTextField(fieldBloc: groupBloc.field('street'), label: 'Street'),
            MkTextField(fieldBloc: groupBloc.field('city'), label: 'City'),
            MkTextField(fieldBloc: groupBloc.field('zip'), label: 'ZIP'),
          ],
        ),
      ),
      const Divider(),
      MkSubformBuilder(
        name: 'billing',
        builder: (context, state, groupBloc) => Column(
          children: [
            Text('Billing', style: Theme.of(context).textTheme.titleMedium),
            MkTextField(fieldBloc: groupBloc.field('street'), label: 'Street'),
            MkTextField(fieldBloc: groupBloc.field('city'), label: 'City'),
            MkTextField(fieldBloc: groupBloc.field('zip'), label: 'ZIP'),
          ],
        ),
      ),
    ],
  ),
)
```

---

## 📋 Dynamic Field Arrays (`MkArrayBloc`)

Manage a dynamic list of fields — phone numbers, invoice rows, tags:

```dart
final phones = MkArrayBloc<MkFieldBloc<String>>([
  MkFieldBloc<String>(validators: [MkValidators.required()]),
]);

// Append a new field
phones.add(MkFieldBloc<String>(validators: [MkValidators.required()]));

// Insert at position
phones.insert(0, MkFieldBloc<String>());

// Remove by index
phones.removeAt(1);

// Reorder (e.g. from ReorderableListView)
phones.move(oldIndex, newIndex);
```

### Build Dynamic Array UI

```dart
BlocBuilder<MkArrayBloc<MkFieldBloc<String>>, MkArrayState<MkFieldBloc<String>>>(
  bloc: phones,
  builder: (context, state) {
    return Column(
      children: [
        ...state.controls.asMap().entries.map((e) => Row(
          children: [
            Expanded(
              child: MkTextField(
                fieldBloc: e.value,
                label: 'Phone ${e.key + 1}',
              ),
            ),
            if (state.controls.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => phones.removeAt(e.key),
              ),
          ],
        )),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Phone'),
          onPressed: () => phones.add(
            MkFieldBloc<String>(validators: [MkValidators.required()]),
          ),
        ),
      ],
    );
  },
)
```

---

## 📦 Tree Shaking & Bundle Size

`mk_forms` is built to be tree-shaken: it uses no reflection, `dart:mirrors`, `dart:io` or top-level side effects, its
icons are `const`, and nothing is registered globally. Importing `package:mk_forms/mk_forms.dart` costs nothing for the
parts you do not use: in release builds, unused widgets, validators, the step-form bloc and the built-in Spanish
messages (only pulled in if you use `MkFormLocalizations.delegate`) are dropped. It also compiles to WebAssembly
(`flutter build web --wasm`) and does not interfere with Flutter's icon tree shaking.

Measured on Flutter 3.47 (web, release, `main.dart.js`), relative to an app with a plain `TextField`:

| App uses | Added size (raw / gzip) |
|---|---|
| `MkTextField` + `MkFieldBloc` + `MkValidators.required` | ~21 KB / ~7 KB |
| Everything (email, password, multi-select, step form, localization) | ~209 KB / ~62 KB |

## 🎨 Widget Reference

All field widgets take either `name:` (looked up in the nearest `MkFormScope`) or `fieldBloc:` (direct
reference), plus an optional `autovalidateMode:` override. On top of that they expose **the parameters of the
Flutter widget they wrap**, so you rarely need to build your own. Only what the bloc must control is handled for
you (value, error text, enabled state); for `enabled:` the widget is disabled if *either* the parameter or the
bloc says so, and `onChanged:` callbacks run *after* the bloc has been updated.

### `MkTextField`

Mirrors [`TextField`](https://api.flutter.dev/flutter/material/TextField-class.html): `keyboardType`,
`textInputAction`, `inputFormatters`, `maxLength`, `maxLines` / `minLines` / `expands`, `cursor*`, `autofillHints`,
`contextMenuBuilder`, `onTap`, `onEditingComplete`, `onTapOutside`, `buildCounter`, `focusNode`, `scrollController`,
`undoController`, `spellCheckConfiguration`, … everything except `controller`, which the widget owns to keep the
text in sync with the bloc.

```dart
MkTextField(
  name: 'username',              // Looks up field from MkFormScope
  // OR:
  fieldBloc: myFieldBloc,        // Direct field reference

  decoration: const InputDecoration(
    labelText: 'Username',
    hintText: 'Enter your username',
    prefixIcon: Icon(Icons.person),
    border: OutlineInputBorder(),
  ),
  keyboardType: TextInputType.text,
  textInputAction: TextInputAction.next,
  inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
  maxLength: 20,
  autofillHints: const [AutofillHints.username],
  autovalidateMode: AutovalidateMode.onUserInteraction,
  showValidatingIndicator: true, // spinner while async validators run
)
```

Typing does not rebuild the `TextField` unless something visible changes (error, validating state, …).

### `MkEmailField`

`MkTextField` preset with an email keyboard, `Email` label, hint and icon (any of which your `decoration` can
override). Accepts every `MkTextField` parameter except `maxLines`, `minLines` and `expands`.

```dart
MkEmailField(name: 'email')
MkEmailField(
  fieldBloc: emailBloc,
  decoration: const InputDecoration(labelText: 'Work email'),
  autofillHints: const [AutofillHints.email],
)
```

### `MkPasswordField`

Obscured input with a show/hide toggle. Accepts every `MkTextField` parameter except `obscureText` (use
`initiallyObscured`), `maxLines`, `minLines` and `expands`.

```dart
MkPasswordField(name: 'password')
MkPasswordField(
  fieldBloc: passwordBloc,
  initiallyObscured: false,
  obscuringCharacter: '*',
  showPasswordIcon: const Icon(Icons.visibility),
  hidePasswordIcon: const Icon(Icons.visibility_off),
  autofillHints: const [AutofillHints.newPassword],
  autovalidateMode: AutovalidateMode.onUnfocus,
)
```

### `MkCheckboxField`

Mirrors [`CheckboxListTile`](https://api.flutter.dev/flutter/material/CheckboxListTile-class.html) (`title`,
`subtitle`, `secondary`, `controlAffinity`, `tristate`, `activeColor`, `fillColor`, `shape`, `side`, `dense`,
`contentPadding`, `visualDensity`, …). `isError` defaults to "a validation error is currently shown". Style the
error text with `errorStyle` / `errorPadding`.

```dart
MkCheckboxField(
  name: 'agreeTerms',
  title: const Text('I agree to the Terms of Service'),
  controlAffinity: ListTileControlAffinity.leading, // default
  onChanged: (value) => analytics.log('terms', value),
)
```

### `MkRadioGroup<T>`

Vertical layouts render `RadioListTile`s, horizontal and wrap layouts render `Radio`s. Group-level parameters
(`activeColor`, `fillColor`, `mouseCursor`, `toggleable`, `radioSide`, `dense`, `controlAffinity`, `shape`,
`tileColor`, …) apply to every option; `highlightSelected` turns on the selected-tile styling. Per option:
`label`, `subtitle`, `secondary`, `enabled`.

```dart
MkRadioGroup<String>(
  name: 'role',
  layout: MkRadioLayout.vertical, // or horizontal / wrap
  title: const Text('Role'),
  options: const [
    MkRadioOption(value: 'developer', label: Text('Developer')),
    MkRadioOption(value: 'designer', label: Text('Designer'), subtitle: Text('UI / UX')),
    MkRadioOption(value: 'manager', label: Text('Manager'), enabled: false),
  ],
  activeColor: Colors.teal,
  onChanged: (role) => debugPrint('role: $role'),
)
```

Fully custom options with `itemBuilder`:

```dart
MkRadioGroup<String>(
  fieldBloc: roleBloc,
  options: roles,
  itemBuilder: (context, option, isSelected, onSelect) => Card(
    color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
    child: ListTile(title: option.label, onTap: onSelect),
  ),
)
```

### `MkDropdownField<T>`

Mirrors [`DropdownButtonFormField`](https://api.flutter.dev/flutter/material/DropdownButtonFormField-class.html)
(`selectedItemBuilder`, `isExpanded`, `icon`, `iconSize`, `dropdownColor`, `menuMaxHeight`, `borderRadius`,
`elevation`, `style`, `alignment`, `focusNode`, …) except its `FormField` members (`validator`, `onSaved`, …), which
the bloc replaces.

```dart
MkDropdownField<String>(
  name: 'country',
  decoration: const InputDecoration(labelText: 'Country'),
  isExpanded: true,
  menuMaxHeight: 300,
  items: countries
      .map((c) => DropdownMenuItem(value: c.code, child: Text(c.name)))
      .toList(),
)
```

### `MkMultiSelectSearchDropdown<T>`

Multi-selection with search, chips, select all / clear all. Customization is grouped by what it configures:
the field (`decoration`, `icon`, `hintStyle` and the `InkWell` parameters such as `borderRadius`, `focusNode`,
`mouseCursor`), the chips (`chip*`, mirroring `InputChip`, or `chipBuilder`), the picker (`sheet*` for the bottom
sheet, `dialog*` for the dialog) and all texts (`hintText`, `searchHint`, `modalTitle`, `doneLabel`,
`selectAllLabel`, `clearAllLabel`, `moreLabelBuilder`) so they can be localized.

```dart
MkMultiSelectSearchDropdown<String>(
  name: 'interests',
  items: const ['Flutter', 'Dart', 'Firebase'],
  itemToString: (item) => item,
  decoration: const InputDecoration(labelText: 'Interests'),
  hintText: 'Pick some…',
  searchHint: 'Search interests…',
  modalType: MkMultiSelectModalType.bottomSheet, // or dialog
  maxChipsDisplayed: 3,
  moreLabelBuilder: (hidden) => '+$hidden more',
  chipBackgroundColor: Colors.teal.shade50,
  sheetShowDragHandle: true,
  onChanged: (selection) => debugPrint('$selection'),
)
```

### `MkFieldBuilder<T>` — Custom Field Widget

Build a completely custom field widget with fine-grained rebuild control:

```dart
MkFieldBuilder<int>(
  fieldBloc: ratingBloc,
  buildWhen: (prev, curr) => prev.value != curr.value || prev.showError != curr.showError,
  builder: (context, state, bloc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) => IconButton(
            icon: Icon(
              i < (state.value ?? 0) ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: () => ratingBloc.changeValue(i + 1),
          )),
        ),
        if (state.showError && state.error != null)
          Text(state.error!, style: const TextStyle(color: Colors.red)),
      ],
    );
  },
)
```

---

## 🌍 Internationalization (i18n)

### Standard Setup

```dart
MaterialApp(
  localizationsDelegates: const [
    MkFormLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: MkFormLocalizations.supportedLocales, // ['en', 'es']
  home: const HomeScreen(),
)
```

### Global Override

Override all validation messages globally (useful for app-level branded messages):

```dart
MkFormLocalizations.current = MyCustomMessages();
```

### Scoped Override

Override messages for a specific subtree:

```dart
MkLocalizationScope(
  messages: SpanishMessages(),
  child: MySpanishFormScreen(),
)
```

### Dynamic Locale Switching

Wrap with `Localizations.override` for live locale switching — validation errors update immediately:

```dart
Localizations.override(
  context: context,
  locale: _selectedLocale,
  child: MyFormWidget(),
)
```

### Custom Messages

```dart
class MyAppMessages extends MkFormMessages {
  @override
  String required() => 'This field cannot be empty';

  @override
  String email() => 'Please enter a valid email address';

  @override
  String minLength(int min) => 'Must be at least $min characters';

  @override
  String maxLength(int max) => 'Must be at most $max characters';

  @override
  String min(num min) => 'Must be at least $min';

  @override
  String max(num max) => 'Must be at most $max';

  @override
  String pattern() => 'Invalid format';

  @override
  String match() => 'Values do not match';
}
```

---

## 🏗️ Server Error Mapping

After a failed API call, map server-returned field errors directly onto form controls:

```dart
try {
  await formBloc.submit();
} catch (e) {
  if (e is ApiException) {
    formBloc.setFieldErrors({
      'email': 'This email is already registered',
      'username': 'Username is already taken',
    });
  }
}
```

Or override `onSubmitFailure` in your custom `MkFormBloc`:

```dart
@override
void onSubmitFailure(Object error) {
  if (error is ServerValidationException) {
    setFieldErrors(error.fieldErrors);
  }
}
```

---

## 🛠️ Programmatic Control

Control fields programmatically outside the UI:

```dart
final emailField = formBloc.field<String>('email')!;

// Change value programmatically (marks dirty)
emailField.changeValue('user@example.com');

// Reset field to initial value (clears dirty/touched)
emailField.reset();

// Reset with a new initial value
emailField.reset('new@example.com');

// Manually touch the field (reveals any error)
emailField.touch();

// Set a server error directly
emailField.setError('Email is already taken');

// Enable / disable
emailField.setEnabled(false);
emailField.setEnabled(true);

// Show / hide in UI
emailField.setVisible(false);
```

---

## 🧪 Testing

### Unit Testing Field Blocs

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  test('required validator shows error after touch', () {
    final field = MkFieldBloc<String>(
      validators: [MkValidators.required()],
    );

    expect(field.state.showError, isFalse); // pristine — no error shown

    field.touch();

    expect(field.state.showError, isTrue); // touched — error visible
    expect(field.state.error, isNotNull);

    field.changeValue('hello');
    expect(field.state.error, isNull); // now valid
  });
}
```

### Unit Testing Form Blocs

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('LoginFormBloc', () {
    late LoginFormBloc sut;

    setUp(() => sut = LoginFormBloc());
    tearDown(() => sut.close());

    test('is initially invalid', () {
      expect(sut.state.isValid, isFalse);
    });

    test('becomes valid with valid credentials', () async {
      sut.field<String>('email')!.changeValue('test@example.com');
      sut.field<String>('password')!.changeValue('password123');
      await Future.microtask(() {}); // allow async validators to settle
      expect(sut.state.isValid, isTrue);
    });

    blocTest<LoginFormBloc, MkFormState>(
      'emits submitting then success',
      build: () => LoginFormBloc(),
      act: (bloc) {
        bloc.field<String>('email')!.changeValue('test@example.com');
        bloc.field<String>('password')!.changeValue('validpass');
        bloc.submit();
      },
      expect: () => [
        isA<MkFormState>().having((s) => s.isSubmitting, 'isSubmitting', isTrue),
        isA<MkFormState>().having((s) => s.isSuccess, 'isSuccess', isTrue),
      ],
    );
  });
}
```

### Running Tests

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Analyze code
flutter analyze
```

---

## 📐 Example App Architecture

The `example/` app demonstrates **Clean Architecture with a 2-layer repository pattern**:

```
example/lib/
├── core/
│   ├── di/              # GetIt + Injectable dependency injection
│   └── router/          # AutoRoute declarative routing
├── data/
│   ├── client/          # ApiClient interface + MockApiClient implementation
│   ├── models/          # AuthCredentials, UserProfile, OnboardingData, etc.
│   └── repositories/    # Abstract contracts + concrete implementations
└── presentation/
    ├── screens/          # HomeScreen (root navigation)
    └── features/
        ├── minimal_login/         # Simple login with MkSimpleFormBloc
        ├── onboarding_flow/       # Multi-route 3-step wizard with API draft
        ├── subforms_checkout/     # Independent subforms with validateGroup()
        ├── dependent_fields/      # Cross-validating password + confirm password
        ├── async_validation/      # Debounced username availability check
        ├── dynamic_array/         # Dynamic task list with reordering
        ├── all_fields_showcase/   # Full field type gallery
        ├── autovalidate_demo/     # AutovalidateMode switcher demo
        ├── i18n_demo/             # Live locale switching EN ↔ ES
        └── custom_design_system/  # Custom card radios, styled chips
```

**Key architecture decisions:**
- No datasource layer — repositories call the API client directly
- BLoC handles all presentation logic — no business logic in widget build methods
- `@injectable` / `@lazySingleton` with GetIt for compile-safe DI
- `@RoutePage()` with AutoRoute for type-safe, nested navigation

---

## 📄 License

MIT License. Copyright (c) 2026.
