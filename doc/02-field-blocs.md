# 2. Field Blocs — `MkFieldBloc<T>`

A field bloc owns one value and everything about it: validation, dirty/touched tracking, async validation, enabled/visible/read-only flags.

```dart
final username = MkFieldBloc<String>(
  initialValue: '',
  validators: [MkValidators.required(), MkValidators.minLength(3)],
);
final age = MkFieldBloc<int>(validators: [MkValidators.required(), MkValidators.min(18)]);
final agree = MkFieldBloc<bool>(validators: [MkValidators.required()]); // false is invalid
final interests = MkFieldBloc<List<String>>(validators: [MkValidators.required()]);
```

## `MkFieldState<T>`

| Property | Type | Meaning |
|---|---|---|
| `value` | `T?` | Current value |
| `initialValue` | `T?` | Value at creation / last reset |
| `error` | `String?` | Current validation error |
| `isDirty` | `bool` | Differs from `initialValue` (lists/maps compare by contents) |
| `isTouched` | `bool` | User interacted with the field |
| `isValidating` | `bool` | Async validation in flight |
| `isValid` | `bool` | No error and not validating |
| `wasFormSubmitted` | `bool` | A submit was attempted |
| `showError` | `bool` | `shouldShowError()` with the default mode |
| `shouldShowError([mode])` | `bool` | Whether to display the error under an `AutovalidateMode` |
| `isReadOnly` | `bool` | Excluded from validation |

## Read-only fields

`isReadOnly: true` (or `setReadOnly(true)`) removes the field from validation: no validator runs, `error`/`isValidating` are cleared, `isValid` is always `true`, so it never blocks its group or form. `setReadOnly(false)` re-validates immediately.

This is independent of the presentational `readOnly` prop on text widgets, which only blocks typing.

## Labels

Built-in validators name the field in messages (“Email is required.”). The label comes from the key in the controls map, or from an explicit `label:`:

```dart
MkFieldBloc<String>(label: 'Work email', validators: [MkValidators.required()]);
```

## Full example — a profile editor exercising field state

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

void main() => runApp(const MaterialApp(home: FieldStateDemo()));

class FieldStateDemo extends StatefulWidget {
  const FieldStateDemo({super.key});
  @override
  State<FieldStateDemo> createState() => _FieldStateDemoState();
}

class _FieldStateDemoState extends State<FieldStateDemo> {
  late final MkFieldBloc<String> _username;
  late final MkFieldBloc<String> _promo;

  @override
  void initState() {
    super.initState();
    _username = MkFieldBloc<String>(
      initialValue: 'kishor',
      label: 'Username',
      validators: [
        MkValidators.required(),
        MkValidators.minLength(3),
        MkValidators.maxLength(20),
      ],
    );
    // Pre-filled, non-editable, never blocks validity.
    _promo = MkFieldBloc<String>(
      initialValue: 'WELCOME10',
      isReadOnly: true,
      validators: [MkValidators.required()],
    );
  }

  @override
  void dispose() {
    _username.close();
    _promo.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Field state')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MkTextField(
            fieldBloc: _username,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),
          MkTextField(
            fieldBloc: _promo,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Promo code'),
          ),
          const SizedBox(height: 16),
          // Live inspector of the username field state.
          MkFieldBuilder<String>(
            fieldBloc: _username,
            builder: (context, s, bloc) => Text(
              'value=${s.value}\n'
              'dirty=${s.isDirty} touched=${s.isTouched} valid=${s.isValid}\n'
              'error=${s.error}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, children: [
            OutlinedButton(onPressed: () => _username.changeValue('ab'), child: const Text('Set "ab"')),
            OutlinedButton(onPressed: _username.touch, child: const Text('Touch')),
            OutlinedButton(onPressed: _username.reset, child: const Text('Reset')),
            OutlinedButton(
              onPressed: () => _promo.setReadOnly(!_promo.state.isReadOnly),
              child: const Text('Toggle promo read-only'),
            ),
          ]),
        ],
      ),
    );
  }
}
```

Standalone field blocs (not in a form) must be closed by you, as above. Blocs inside a form's `controls` are closed with the form.

Next: [Form Blocs](03-form-blocs.md).
