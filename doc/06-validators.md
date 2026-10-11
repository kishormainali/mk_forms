# 6. Validators

A validator is a `Validator<T>` (`String? Function(T? value)`) — return `null` when valid, otherwise the error message. Validators in `validators:` run in order and the **first error wins**.

## Built-ins (`MkValidators`)

| Validator | Notes |
|---|---|
| `required([message])` | `null`, `''`, empty list/map and `false` are invalid |
| `email()` | Email format |
| `minLength(n)` / `maxLength(n)` | String length |
| `pattern(RegExp, message)` | Regex match |
| `min(n)` / `max(n)` | Numeric bounds |
| `match(() => other.value, message)` | Equal to a lazily read value |
| `matchControl(fieldBloc, message)` | Equal to another field's value |
| `compose([...])` | Combine validators; first error wins |
| `composeAsync([...])` | Combine async validators |

Messages are localized and field-aware by default (“Password must be at least 8 characters.”); pass a custom message to override. See [Internationalization](13-i18n.md).

## Writing your own

```dart
Validator<String> noSpaces([String message = 'No spaces allowed']) =>
    (value) => (value ?? '').contains(' ') ? message : null;
```

Async validators are `AsyncValidator<T>` (`Future<String?> Function(T? value)`); see the next guide.

## Full example — a signup form using every common validator

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

Validator<String> noSpaces([String message = 'Spaces are not allowed']) =>
    (v) => (v ?? '').contains(' ') ? message : null;

String? strongPassword(String? v) {
  final s = v ?? '';
  if (!RegExp(r'[A-Z]').hasMatch(s)) return 'Add an uppercase letter';
  if (!RegExp(r'\d').hasMatch(s)) return 'Add a digit';
  return null;
}

void main() => runApp(const MaterialApp(home: ValidatorsDemo()));

class ValidatorsDemo extends StatefulWidget {
  const ValidatorsDemo({super.key});
  @override
  State<ValidatorsDemo> createState() => _ValidatorsDemoState();
}

class _ValidatorsDemoState extends State<ValidatorsDemo> {
  late final MkFieldBloc<String> _password;
  late final MkSimpleFormBloc _form;

  @override
  void initState() {
    super.initState();
    _password = MkFieldBloc<String>(
      validators: [
        MkValidators.required(),
        MkValidators.minLength(8),
        strongPassword,
      ],
    );
    _form = MkSimpleFormBloc(
      controls: {
        'username': MkFieldBloc<String>(
          validators: [
            MkValidators.required(),
            MkValidators.minLength(3),
            MkValidators.maxLength(16),
            noSpaces(),
            MkValidators.pattern(RegExp(r'^[a-z0-9_]+$'), 'Lowercase letters, digits, _ only'),
          ],
        ),
        'email': MkFieldBloc<String>(
          validators: [MkValidators.required(), MkValidators.email()],
        ),
        // Text inputs bind String fields; validate the number via pattern
        // and parse it in onSubmit.
        'age': MkFieldBloc<String>(
          validators: [
            MkValidators.required(),
            MkValidators.pattern(RegExp(r'^\d{1,3}$'), 'Enter a valid age'),
            (v) => (int.tryParse(v ?? '') ?? 0) < 18 ? 'Must be 18 or older' : null,
          ],
        ),
        'password': _password,
        'confirm': MkFieldBloc<String>(
          validators: [
            MkValidators.required(),
            MkValidators.matchControl(_password, 'Passwords do not match'),
          ],
          dependsOn: [_password], // see guide 7
        ),
        'terms': MkFieldBloc<bool>(
          validators: [MkValidators.required('You must accept the terms')],
        ),
      },
      onSubmit: (values) async => values,
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
      appBar: AppBar(title: const Text('Validators')),
      body: MkFormScope.value(
        value: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const MkTextField(name: 'username', decoration: InputDecoration(labelText: 'Username')),
            const SizedBox(height: 12),
            const MkEmailField(name: 'email'),
            const SizedBox(height: 12),
            const MkTextField(
              name: 'age',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Age'),
            ),
            const SizedBox(height: 12),
            const MkPasswordField(name: 'password'),
            const SizedBox(height: 12),
            const MkPasswordField(
              name: 'confirm',
              decoration: InputDecoration(labelText: 'Confirm password'),
            ),
            const SizedBox(height: 12),
            const MkCheckboxField(name: 'terms', title: Text('I accept the terms')),
            const SizedBox(height: 16),
            FilledButton(onPressed: _form.submit, child: const Text('Sign up')),
          ],
        ),
      ),
    );
  }
}
```

`MkValidators.min`/`max` operate on numeric fields (`MkFieldBloc<int>`/`<double>`) driven by your own widget (for example a `Slider` or stepper via `MkFieldBuilder`).

Next: [Dependent & Async Validation](07-dependent-and-async-validation.md).
