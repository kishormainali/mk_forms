# 12. Widget Reference

Every field widget is a `FormField` (see [Using the fields with Flutter's `Form`](#using-the-fields-with-flutters-form)) and takes **either** `name:` (looked up in the nearest `MkFormScope`) **or** `fieldBloc:` (direct reference), plus an optional `autovalidateMode:`. Beyond that they expose the parameters of the Flutter widget they wrap. The bloc controls value, error text and enabled state; a widget is disabled if either the `enabled:` parameter or the bloc says so; `onChanged` runs *after* the bloc is updated.

| Widget | Wraps | Value type |
|---|---|---|
| `MkTextField` | `TextField` (all params except `controller`) | `String` |
| `MkEmailField` | `MkTextField` preset (email keyboard, label, icon) | `String` |
| `MkPasswordField` | `MkTextField` + show/hide toggle (`initiallyObscured`) | `String` |
| `MkCheckboxField` | `CheckboxListTile` | `bool` |
| `MkRadioGroup<T>` | `RadioListTile` / `Radio` (vertical, horizontal, wrap) | `T` |
| `MkDropdownField<T>` | `DropdownButton` in an `InputDecorator` (same structure as `DropdownButtonFormField`) | `T` |
| `MkMultiSelectSearchDropdown<T>` | Search + chips + sheet/dialog | `List<T>` |
| `MkFieldBuilder<T>` | Build anything from `MkFieldState<T>` | any |
| `MkFieldSelector<T, R>` | Rebuild on a derived slice only | any |
| `MkFormSelector<R>` | Same, for form-level state (`canSubmit`, …) | — |
| `MkArrayBuilder<C>` | Rebuild on array structure changes only | — |

Details:

- **`MkTextField`**: `showValidatingIndicator: true` shows a spinner during async validation. Typing doesn't rebuild the `TextField` unless something visible changes.
- **`MkEmailField`**: all `MkTextField` params except `maxLines`, `minLines`, `expands`.
- **`MkPasswordField`**: `initiallyObscured`, `obscuringCharacter`, `showPasswordIcon`, `hidePasswordIcon`; no `obscureText`.
- **`MkCheckboxField`**: `title`, `subtitle`, `controlAffinity`, `tristate`, `errorStyle`, `errorPadding`.
- **`MkRadioGroup<T>`**: `options: [MkRadioOption(value:, label:, subtitle:, enabled:)]`, `layout: MkRadioLayout.vertical|horizontal|wrap`, or `itemBuilder` for fully custom options.
- **Label vs. hint:** like a Material `TextField`, a dropdown or multi-select with a label hides its hint until the label floats (field focused, or `floatingLabelBehavior: FloatingLabelBehavior.always`); with no label the hint is always shown.
- **`MkDropdownField<T>`**: `items`, `isExpanded`, `menuMaxHeight`, `selectedItemBuilder`…
- **`MkMultiSelectSearchDropdown<T>`**: `items`, `itemToString`, `modalType` (`bottomSheet`/`dialog`), `maxChipsDisplayed`, `moreLabelBuilder`, plus localizable labels (`hintText`, `searchHint`, `modalTitle`, `doneLabel`, `selectAllLabel`, `clearAllLabel`).

## `MkFieldBuilder<T>` and `MkFieldSelector<T, R>`

`MkFieldBuilder` rebuilds on field-state changes (limit with `buildWhen`). `MkFieldSelector` is like `BlocSelector`: it rebuilds only when the selected value changes (`R` must be `==`-comparable). It auto-hides when the field's `isVisible == false`; pass `hideWhenInvisible: false` to opt out.

## Full example — every widget on one screen, plus a custom rating field

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mk_forms/mk_forms.dart';

class ShowcaseFormBloc extends MkFormBloc {
  ShowcaseFormBloc()
      : super(controls: {
          'username': MkFieldBloc<String>(
            validators: [MkValidators.required(), MkValidators.minLength(3)],
          ),
          'email': MkFieldBloc<String>(
            validators: [MkValidators.required(), MkValidators.email()],
          ),
          'password': MkFieldBloc<String>(
            validators: [MkValidators.required(), MkValidators.minLength(8)],
          ),
          'role': MkFieldBloc<String>(
            initialValue: 'developer',
            validators: [MkValidators.required()],
          ),
          'country': MkFieldBloc<String>(validators: [MkValidators.required()]),
          'interests': MkFieldBloc<List<String>>(
            initialValue: const [],
            validators: [MkValidators.required()],
          ),
          'rating': MkFieldBloc<int>(
            validators: [MkValidators.required('Please rate us')],
          ),
          'terms': MkFieldBloc<bool>(
            initialValue: false,
            validators: [MkValidators.required('Accept the terms to continue')],
          ),
        });

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async => values;
}

void main() => runApp(const MaterialApp(home: ShowcaseScreen()));

class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const countries = {'NP': 'Nepal', 'US': 'United States', 'DE': 'Germany'};

    return MkFormScope(
      create: (_) => ShowcaseFormBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('All fields')),
        body: Builder(builder: (context) {
          final form = context.mkForm;
          return MkFormListener(
            onSuccess: (context, values) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('$values'))),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MkTextField(
                  name: 'username',
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                  maxLength: 20,
                  autofillHints: const [AutofillHints.username],
                ),
                const SizedBox(height: 12),
                const MkEmailField(name: 'email'),
                const SizedBox(height: 12),
                const MkPasswordField(
                  name: 'password',
                  autofillHints: [AutofillHints.newPassword],
                ),
                const SizedBox(height: 12),
                MkRadioGroup<String>(
                  name: 'role',
                  layout: MkRadioLayout.vertical,
                  title: const Text('Role'),
                  options: const [
                    MkRadioOption(value: 'developer', label: Text('Developer')),
                    MkRadioOption(value: 'designer', label: Text('Designer'), subtitle: Text('UI / UX')),
                    MkRadioOption(value: 'manager', label: Text('Manager'), enabled: false),
                  ],
                ),
                const SizedBox(height: 12),
                MkDropdownField<String>(
                  name: 'country',
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Country'),
                  items: [
                    for (final e in countries.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                ),
                const SizedBox(height: 12),
                MkMultiSelectSearchDropdown<String>(
                  name: 'interests',
                  items: const ['Flutter', 'Dart', 'Firebase', 'Rust', 'Go'],
                  itemToString: (item) => item,
                  decoration: const InputDecoration(labelText: 'Interests'),
                  searchHint: 'Search interests…',
                  maxChipsDisplayed: 3,
                  moreLabelBuilder: (hidden) => '+$hidden more',
                ),
                const SizedBox(height: 12),

                // Custom field: star rating via MkFieldBuilder.
                MkFieldBuilder<int>(
                  fieldBloc: form.field<int>('rating')!,
                  buildWhen: (p, c) => p.value != c.value || p.showError != c.showError,
                  builder: (context, state, bloc) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        for (var i = 1; i <= 5; i++)
                          IconButton(
                            icon: Icon(
                              i <= (state.value ?? 0) ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () => bloc.changeValue(i),
                          ),
                      ]),
                      if (state.showError && state.error != null)
                        Text(state.error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),

                // Selector: rebuilds only when the username *error* changes.
                MkFieldSelector<String, String?>(
                  name: 'username',
                  selector: (s) => s.error,
                  builder: (context, error, bloc) =>
                      Text(error == null ? 'Username looks fine' : 'Fix username: $error'),
                ),
                const SizedBox(height: 12),
                const MkCheckboxField(
                  name: 'terms',
                  title: Text('I agree to the Terms of Service'),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: form.submit, child: const Text('Submit')),
              ],
            ),
          );
        }),
      ),
    );
  }
}
```

## Using the fields with Flutter's `Form`

Every Mk field **is** a Flutter `FormField` (via the shared `MkFormField<T>` base), so it works inside a `Form` and with a `GlobalKey<FormState>`:

| `Form` feature | What it does for an Mk field |
|---|---|
| `formKey.currentState!.validate()` | Touches the bloc and runs its sync + async validators, revealing the error like a submit attempt. Returns whether every field is valid right now. |
| `formKey.currentState!.save()` | Calls the field's `onSaved(value)` with the bloc's value. |
| `formKey.currentState!.reset()` | Resets each bloc (value, dirty, touched) and the UI. |
| `Form(onChanged: ...)` | Fires on every user edit. |
| `Form(autovalidateMode: ...)` | Reveals errors per the usual rules. |
| `forceErrorText:` | Shows that message and makes the field invalid (handy for one-off server errors). |

The bloc stays the **source of truth**: `FormFieldState.value`, `errorText`, `hasError` and `isValid` read it, `didChange` writes to it, and `FormField.validator` / `initialValue` are not used (validators and initial values belong to the bloc). Error visibility follows the field's `autovalidateMode:` override, else the enclosing `MkFormScope`, else `onUserInteraction`. You don't need a `Form` at all; `MkFormScope` + `MkFormBloc.submit()` keep working exactly as before.

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

void main() => runApp(const MaterialApp(home: FormIntegrationDemo()));

class FormIntegrationDemo extends StatefulWidget {
  const FormIntegrationDemo({super.key});
  @override
  State<FormIntegrationDemo> createState() => _FormIntegrationDemoState();
}

class _FormIntegrationDemoState extends State<FormIntegrationDemo> {
  final _formKey = GlobalKey<FormState>();
  final _email = MkFieldBloc<String>(
    label: 'Email',
    validators: [MkValidators.required(), MkValidators.email()],
  );
  final _terms = MkFieldBloc<bool>(
    validators: [MkValidators.required('Accept the terms')],
  );
  final _saved = <String, Object?>{};
  String? _serverError;

  @override
  void dispose() {
    _email.close();
    _terms.close();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return; // reveals every error
    _formKey.currentState!.save(); // runs the onSaved callbacks
    setState(() => _serverError = _saved['email'] == 'taken@example.com'
        ? 'This email is already registered'
        : null);
    if (_serverError == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Saved $_saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mk fields inside a Form')),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() => _serverError = null), // clear on edit
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MkEmailField(
              fieldBloc: _email,
              forceErrorText: _serverError, // one-off message from the server
              onSaved: (v) => _saved['email'] = v,
            ),
            const SizedBox(height: 12),
            MkCheckboxField(
              fieldBloc: _terms,
              title: const Text('I accept the terms'),
              onSaved: (v) => _saved['terms'] = v,
            ),
            const SizedBox(height: 16),
            Row(children: [
              FilledButton(onPressed: _submit, child: const Text('Submit')),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => _formKey.currentState!.reset(),
                child: const Text('Reset'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
```

Try `taken@example.com`: validation passes, then `forceErrorText` shows the server message under the field.

Next: [Internationalization](13-i18n.md).
