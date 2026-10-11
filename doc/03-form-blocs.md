# 3. Form Blocs

A form bloc takes a map of named controls, aggregates their validity/values, and runs submission.

## `MkSimpleFormBloc` — inline handler

```dart
final form = MkSimpleFormBloc(
  controls: {'name': MkFieldBloc<String>(validators: [MkValidators.required()])},
  onSubmit: (values) async => api.save(values),
  onSubmitSuccess: (response) => print('Saved: $response'),
  onSubmitFailure: (error) => print('Error: $error'),
);
```

## `MkFormBloc` — subclass

Override `onSubmit`, and optionally `onSubmitSuccess` / `onSubmitFailure`.

## Submission lifecycle

`submit()` → validates all controls (revealing every error) → if invalid, stops → otherwise status becomes `submitting` → `onSubmit(values)` → `success(response)` or `failure(error)`. Editing a field after a failure auto-clears stale server errors. `submit()` is ignored while already submitting.

`MkFormState` exposes `isValid`, `values`, `isSubmitting`, `isSuccess`, `submissionStatus`, `canSubmit`.

## Methods

| Method | Description |
|---|---|
| `submit()` | Validate everything then call `onSubmit` |
| `reset()` | Reset form and all controls |
| `populateValues(data)` | Hydrate fields from API data (optionally pristine) |
| `setFieldErrors(Map<String,String>)` | Apply server errors to controls |
| `validateGroup(name)` | Validate one subform |
| `validateControls([names])` | Validate a subset |
| `field<T>(name)` | Typed `MkFieldBloc<T>` lookup |
| `control<C>(name)` | Any `MkControlBloc` lookup |

## Full example — registration with lifecycle hooks and server errors

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.fieldErrors});
  final String message;
  final Map<String, String>? fieldErrors;
  @override
  String toString() => message;
}

class FakeAuthRepository {
  Future<String> register({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (email == 'taken@example.com') {
      throw ApiException('Validation failed',
          fieldErrors: {'email': 'This email is already registered'});
    }
    return 'user-42';
  }
}

final authRepository = FakeAuthRepository();

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
  Future<dynamic> onSubmit(Map<String, dynamic> values) {
    return authRepository.register(
      email: values['email'] as String,
      password: values['password'] as String,
    );
  }

  @override
  void onSubmitSuccess(dynamic response) => debugPrint('Registered $response');

  @override
  void onSubmitFailure(Object error) {
    if (error is ApiException && error.fieldErrors != null) {
      setFieldErrors(error.fieldErrors!); // shows under the right field
    }
  }
}

void main() => runApp(const MaterialApp(home: RegistrationScreen()));

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // `create` form: the scope owns and closes the bloc.
    return MkFormScope(
      create: (_) => RegistrationFormBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Register')),
        body: Builder(
          builder: (context) => MkFormListener(
            onSuccess: (context, id) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Welcome, $id'))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const MkEmailField(name: 'email'),
                const SizedBox(height: 16),
                const MkPasswordField(name: 'password'),
                const SizedBox(height: 24),
                MkFormBuilder(
                  builder: (context, state, form) => Row(children: [
                    FilledButton(
                      onPressed: state.isSubmitting ? null : form.submit,
                      child: Text(state.isSubmitting ? 'Working…' : 'Create account'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(onPressed: form.reset, child: const Text('Reset')),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
```

Try `taken@example.com` to see the server error land on the email field.

Next: [Scope, Builder & Listener](04-scope-builder-listener.md).
