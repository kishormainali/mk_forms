# 14. Server Errors & Programmatic Control

## Server error mapping

`setFieldErrors(Map<String, String>)` pushes server-returned messages onto the matching controls (they become visible immediately). The idiomatic place is `onSubmitFailure`. Editing a field afterwards clears its stale server error.

```dart
@override
void onSubmitFailure(Object error) {
  if (error is ServerValidationException) setFieldErrors(error.fieldErrors);
}
```

## Programmatic control

| Call | Effect |
|---|---|
| `field.changeValue(v)` | Set value (marks dirty, validates) |
| `field.reset([newInitial])` | Back to initial (or to a new initial); clears dirty/touched |
| `field.touch()` | Mark touched — reveals current error |
| `field.setError(msg)` | Set an error directly |
| `field.setEnabled(bool)` | Enable / disable |
| `field.setVisible(bool)` | Show / hide in UI |
| `field.setReadOnly(bool)` | Exclude from validation; `false` re-validates |
| `form.populateValues(map)` | Bulk hydrate |
| `form.reset()` | Reset everything |

## Full example — server validation, prefill, and a conditional field

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

class ServerValidationException implements Exception {
  ServerValidationException(this.fieldErrors);
  final Map<String, String> fieldErrors;
  @override
  String toString() => 'Please fix the highlighted fields';
}

class AccountFormBloc extends MkFormBloc {
  AccountFormBloc()
      : super(controls: {
          'email': MkFieldBloc<String>(
            validators: [MkValidators.required(), MkValidators.email()],
          ),
          'username': MkFieldBloc<String>(validators: [MkValidators.required()]),
          'company': MkFieldBloc<String>(),
          'isBusiness': MkFieldBloc<bool>(initialValue: false),
        }) {
    // Show the company field only for business accounts.
    final company = field<String>('company')!..setVisible(false);
    field<bool>('isBusiness')!.stream.listen(
          (s) => company.setVisible(s.value ?? false),
        );
  }

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    throw ServerValidationException({
      'email': 'This email is already registered',
      'username': 'Username is already taken',
    });
  }

  @override
  void onSubmitFailure(Object error) {
    if (error is ServerValidationException) setFieldErrors(error.fieldErrors);
  }
}

void main() => runApp(const MaterialApp(home: AccountScreen()));

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MkFormScope(
      create: (_) => AccountFormBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: Builder(builder: (context) {
          final form = context.mkForm;
          return ListView(padding: const EdgeInsets.all(16), children: [
            const MkEmailField(name: 'email'),
            const SizedBox(height: 12),
            const MkTextField(name: 'username', decoration: InputDecoration(labelText: 'Username')),
            const SizedBox(height: 12),
            const MkCheckboxField(name: 'isBusiness', title: Text('Business account')),
            // Auto-hides when the field's isVisible is false.
            MkFieldSelector<String, String?>(
              name: 'company',
              selector: (s) => s.isVisible.toString(),
              builder: (context, _, bloc) => const MkTextField(
                name: 'company',
                decoration: InputDecoration(labelText: 'Company'),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 8, children: [
              FilledButton(onPressed: form.submit, child: const Text('Submit')),
              OutlinedButton(
                onPressed: () => form.populateValues({
                  'email': 'me@example.com',
                  'username': 'kishor',
                }),
                child: const Text('Prefill'),
              ),
              OutlinedButton(
                onPressed: () => form.field<String>('email')!.setError('Manual error'),
                child: const Text('Set error'),
              ),
              TextButton(onPressed: form.reset, child: const Text('Reset')),
            ]),
          ]);
        }),
      ),
    );
  }
}
```

Next: [Testing](15-testing.md).
