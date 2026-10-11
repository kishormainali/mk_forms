# 7. Dependent & Async Validation

## Cross-field validation with `dependsOn`

A field listed in `dependsOn` is revalidated whenever the dependency's **value** changes. The relation is one-directional, so there are no loops: changing `password` revalidates `confirmPassword`, but not the reverse.

- Sync validators re-run immediately.
- Async validators are debounced like after `changeValue`.
- Adding `dependsOn` never fires an async validator at construction.

```dart
final password = MkFieldBloc<String>(validators: [MkValidators.required(), MkValidators.minLength(8)]);
final confirm = MkFieldBloc<String>(
  validators: [MkValidators.required(), MkValidators.matchControl(password, 'Passwords do not match')],
  dependsOn: [password],
);
```

## Debounced async validation

`asyncValidators` run after sync validators pass, once the user pauses for `debounceTime`. A newer keystroke cancels the stale in-flight check, so an old response can never overwrite a newer one. While running, `state.isValidating` is `true` (and `isValid` is `false`, so the form can't submit mid-check).

If an async validator **throws** (offline, 500…), the field becomes invalid with a generic localized message (`MkErrorCodes.asyncValidationFailed`) rather than the raw exception. The original error goes to `onError` / `BlocObserver.onError` for logging. Return a string for errors users should see.

## Full example — registration with availability check and confirm password

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

class UserRepository {
  static const _taken = {'admin', 'root', 'kishor'};

  Future<bool> isUsernameAvailable(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (name == 'boom') throw Exception('network down');
    return !_taken.contains(name.toLowerCase());
  }
}

final userRepository = UserRepository();

class SignupFormBloc extends MkFormBloc {
  SignupFormBloc() : super(controls: _build());

  static Map<String, MkFieldBloc<dynamic>> _build() {
    final password = MkFieldBloc<String>(
      validators: [MkValidators.required(), MkValidators.minLength(8)],
    );
    return {
      'username': MkFieldBloc<String>(
        validators: [MkValidators.required(), MkValidators.minLength(3)],
        asyncValidators: [
          (val) async {
            final ok = await userRepository.isUsernameAvailable(val!);
            return ok ? null : 'Username is already taken';
          },
        ],
        debounceTime: const Duration(milliseconds: 400),
      ),
      'password': password,
      'confirm': MkFieldBloc<String>(
        validators: [
          MkValidators.required(),
          MkValidators.matchControl(password, 'Passwords do not match'),
        ],
        dependsOn: [password],
      ),
    };
  }

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async => 'ok';
}

void main() => runApp(const MaterialApp(home: SignupScreen()));

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MkFormScope(
      create: (_) => SignupFormBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Sign up')),
        body: Builder(builder: (context) {
          final username = context.mkField<String>('username')!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Built-in widget shows a spinner while async validation runs.
              const MkTextField(
                name: 'username',
                showValidatingIndicator: true,
                decoration: InputDecoration(labelText: 'Username (try "admin" or "boom")'),
              ),
              // Custom status line using the same field state.
              MkFieldBuilder<String>(
                fieldBloc: username,
                builder: (context, s, _) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    s.isValidating
                        ? 'Checking…'
                        : (s.isValid && s.isTouched ? '✓ Available' : ''),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const MkPasswordField(name: 'password'),
              const SizedBox(height: 12),
              const MkPasswordField(
                name: 'confirm',
                decoration: InputDecoration(labelText: 'Confirm password'),
              ),
              const SizedBox(height: 20),
              MkFormBuilder(
                builder: (context, state, form) => FilledButton(
                  onPressed: state.canSubmit ? form.submit : null,
                  child: const Text('Create account'),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }
}
```

Edit the password after typing a confirmation: the confirm field flips to an error instantly, without touching it.

Next: [Extending Form State](08-extending-form-state.md).
