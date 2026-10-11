import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

/// Shows that every mk_forms field is a Flutter [FormField]: it works inside a
/// plain [Form] with a [GlobalKey<FormState>] - `validate()`, `save()`,
/// `reset()`, `onChanged` - and supports `forceErrorText` for server errors.
///
/// The blocs stay the source of truth; no `MkFormBloc` is needed here.
@RoutePage()
class FormIntegrationScreen extends StatefulWidget {
  const FormIntegrationScreen({super.key});

  @override
  State<FormIntegrationScreen> createState() => _FormIntegrationScreenState();
}

class _FormIntegrationScreenState extends State<FormIntegrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _email = MkFieldBloc<String>(
    label: 'Email',
    validators: [MkValidators.required(), MkValidators.email()],
  );
  final _password = MkFieldBloc<String>(
    label: 'Password',
    validators: [MkValidators.required(), MkValidators.minLength(8)],
  );
  final _role = MkFieldBloc<String>(
    label: 'Role',
    validators: [MkValidators.required()],
  );
  final _terms = MkFieldBloc<bool>(
    validators: [MkValidators.required('Accept the terms to continue')],
  );

  final _saved = <String, Object?>{};
  String? _serverError;
  int _changes = 0;

  @override
  void dispose() {
    unawaited(_email.close());
    unawaited(_password.close());
    unawaited(_role.close());
    unawaited(_terms.close());
    super.dispose();
  }

  void _submit() {
    final form = _formKey.currentState!;
    // validate() touches every bloc, runs its validators and reveals errors.
    if (!form.validate()) return;
    form.save(); // calls each field's onSaved with the bloc value

    setState(() {
      _serverError = _saved['email'] == 'taken@example.com'
          ? 'This email is already registered'
          : null;
    });
    if (_serverError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: $_saved'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Form Integration')),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {
          _changes++;
          // A server error describes the value that was submitted; clear it
          // as soon as the user edits anything.
          _serverError = null;
        }),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Every mk_forms field is a FormField:\n'
                  '• Submit calls formKey.validate() then save().\n'
                  '• Reset calls formKey.reset() (resets the blocs too).\n'
                  '• Try taken@example.com to see forceErrorText.\n'
                  '• Form.onChanged fired $_changes times.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            MkEmailField(
              fieldBloc: _email,
              forceErrorText: _serverError,
              onSaved: (v) => _saved['email'] = v,
            ),
            const SizedBox(height: 16),
            MkPasswordField(
              fieldBloc: _password,
              onSaved: (v) => _saved['password'] = '•' * (v?.length ?? 0),
            ),
            const SizedBox(height: 16),
            MkDropdownField<String>(
              fieldBloc: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'developer', child: Text('Developer')),
                DropdownMenuItem(value: 'designer', child: Text('Designer')),
              ],
              onSaved: (v) => _saved['role'] = v,
            ),
            const SizedBox(height: 8),
            MkCheckboxField(
              fieldBloc: _terms,
              title: const Text('I accept the terms'),
              onSaved: (v) => _saved['terms'] = v,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    child: const Text('Submit'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    _formKey.currentState!.reset();
                    setState(() => _serverError = null);
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
