# 1. Getting Started

## Install

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  mk_forms: ^1.3.0
  # only if you use i18n:
  flutter_localizations:
    sdk: flutter
```

One import gives you everything:

```dart
import 'package:mk_forms/mk_forms.dart';
```

## Mental model

| Type | Role |
|---|---|
| `MkFieldBloc<T>` | One control per field: value, error, dirty/touched, async validation |
| `MkGroupBloc` | A named set of controls validated independently (a subform) |
| `MkArrayBloc<C>` | A dynamic ordered list of controls |
| `MkFormBloc` | Root coordinator: aggregates validity, runs `submit()` |
| `MkStepFormBloc` | A form split into steps with per-step validation gating |
| `MkFormScope` | Provides the form bloc + default `AutovalidateMode` to the subtree |

Everything is a Cubit, so each field rebuilds **only its own widget** — typing in one field never rebuilds the screen.

## Which form bloc do I need?

| Situation | Use |
|---|---|
| One async call on submit | `MkSimpleFormBloc` |
| Lifecycle hooks, server-error mapping, extra state | subclass `MkFormBloc` |
| Wizard | `MkStepFormBloc` / `MkSimpleStepFormBloc` |
| Independent sections | nest `MkGroupBloc` in `controls` |
| Repeating rows | `MkArrayBloc` |

## Full example — sign-in form

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

void main() => runApp(const MaterialApp(home: LoginScreen()));

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
        // Replace with a real call.
        await Future<void>.delayed(const Duration(seconds: 1));
        if (values['password'] == 'wrong-password') {
          throw Exception('Invalid credentials');
        }
        return 'token-123';
      },
    );
  }

  @override
  void dispose() {
    _form.close(); // MkFormScope.value never closes the bloc for you
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: MkFormScope.value(
          value: _form,
          child: MkFormListener(
            formBloc: _form,
            onSuccess: (context, token) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Signed in: $token'))),
            onFailure: (context, error) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$error'))),
            child: Column(
              children: [
                const MkEmailField(name: 'email'),
                const SizedBox(height: 16),
                const MkPasswordField(name: 'password'),
                const SizedBox(height: 24),
                MkFormBuilder(
                  formBloc: _form,
                  buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
                  builder: (context, state, form) => FilledButton(
                    onPressed: state.isSubmitting ? null : form.submit,
                    child: state.isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

What to notice:

- Errors do **not** appear on load. They appear after the user touches a field or presses Sign in (`submit()` validates everything and reveals all errors).
- `MkEmailField(name: 'email')` finds its bloc through the `MkFormScope`; no wiring needed.
- The button uses `buildWhen` so it only rebuilds when `isSubmitting` changes.

Next: [Field Blocs](02-field-blocs.md).
