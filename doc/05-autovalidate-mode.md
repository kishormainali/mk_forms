# 5. AutovalidateMode

Validation always runs; `AutovalidateMode` only controls **when the error is shown**. Set it on the scope, override it per field.

| Mode | Error is shown |
|---|---|
| `always` | Immediately, even on pristine fields |
| `onUserInteraction` *(default)* | After the field is touched, or after a submit attempt |
| `onUnfocus` | After the field loses focus, or after a submit attempt |
| `onUserInteractionIfError` | Same as `onUserInteraction` |
| `disabled` | Only after a submit attempt (`wasFormSubmitted`) |

```dart
MkFormScope.value(value: form, autovalidateMode: AutovalidateMode.always, child: ...)
MkTextField(name: 'username', autovalidateMode: AutovalidateMode.disabled)
```

Resolution order: field's own `autovalidateMode` → scope's mode → `onUserInteraction`.

## Custom widgets

Use `state.shouldShowError(context.mkAutovalidateMode)` in your own widgets so they honor the same rules.

## Full example — a live mode switcher

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

void main() => runApp(const MaterialApp(home: AutovalidateDemo()));

class AutovalidateDemo extends StatefulWidget {
  const AutovalidateDemo({super.key});
  @override
  State<AutovalidateDemo> createState() => _AutovalidateDemoState();
}

class _AutovalidateDemoState extends State<AutovalidateDemo> {
  late final MkSimpleFormBloc _form;
  AutovalidateMode _mode = AutovalidateMode.onUserInteraction;

  @override
  void initState() {
    super.initState();
    _form = MkSimpleFormBloc(
      controls: {
        'name': MkFieldBloc<String>(validators: [MkValidators.required()]),
        'email': MkFieldBloc<String>(
          validators: [MkValidators.required(), MkValidators.email()],
        ),
        'nickname': MkFieldBloc<String>(validators: [MkValidators.minLength(3)]),
        'custom': MkFieldBloc<String>(validators: [MkValidators.required()]),
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
      appBar: AppBar(title: const Text('AutovalidateMode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButton<AutovalidateMode>(
            value: _mode,
            isExpanded: true,
            items: [
              for (final m in AutovalidateMode.values)
                DropdownMenuItem(value: m, child: Text('Scope mode: ${m.name}')),
            ],
            onChanged: (m) => setState(() => _mode = m!),
          ),
          MkFormScope.value(
            value: _form,
            autovalidateMode: _mode, // scope-wide
            child: Column(children: [
              const SizedBox(height: 12),
              const MkTextField(
                name: 'name',
                decoration: InputDecoration(labelText: 'Name (scope mode)'),
              ),
              const SizedBox(height: 12),
              const MkEmailField(name: 'email'),
              const SizedBox(height: 12),
              const MkTextField(
                name: 'nickname',
                decoration: InputDecoration(labelText: 'Nickname (min 3, scope mode)'),
              ),
              const SizedBox(height: 12),
              // Per-field override: ignores the scope, errors only after submit.
              const MkTextField(
                name: 'custom',
                autovalidateMode: AutovalidateMode.disabled,
                decoration: InputDecoration(labelText: 'Custom (always disabled)'),
              ),
              const SizedBox(height: 12),
              // Custom widget honoring the mode.
              MkFieldBuilder<String>(
                fieldBloc: _form.field<String>('name')!,
                builder: (context, state, bloc) {
                  final show = state.shouldShowError(context.mkAutovalidateMode);
                  return Text(
                    show ? 'name error visible: ${state.error}' : 'name error hidden',
                  );
                },
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _form.submit, child: const Text('Submit')),
            ]),
          ),
        ],
      ),
    );
  }
}
```

Switch to `always` to see errors on load; to `disabled` to see them only after Submit.

Next: [Validators](06-validators.md).
