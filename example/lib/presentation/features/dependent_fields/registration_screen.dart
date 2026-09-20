import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/registration_form_bloc.dart';

/// Registration form demonstrating bidirectional cross-field validation
/// powered by [RegistrationFormBloc].
@RoutePage()
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, RegistrationFormBloc? formBloc})
    : _formBloc = formBloc;

  final RegistrationFormBloc? _formBloc;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late final RegistrationFormBloc _formBloc;

  @override
  void initState() {
    super.initState();
    _formBloc = widget._formBloc ?? getIt<RegistrationFormBloc>();
  }

  @override
  void dispose() {
    unawaited(_formBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dependent Fields')),
      body: MkFormScope.value(
        value: _formBloc,
        child: MkFormListener(
          formBloc: _formBloc,
          onSuccess: (context, response) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onFailure: (context, error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Submission error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Cross-Field Validation:\n'
                      '1. Enter different values in Password and Confirm Password.\n'
                      '2. Update Password; Confirm Password updates its error status automatically.\n'
                      '3. Both fields depend on each other with zero infinite recursion.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const MkTextField(
                  name: 'name',
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Jane Doe',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                const MkPasswordField(
                  name: 'password',
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                const MkPasswordField(
                  name: 'confirmPassword',
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _formBloc.submit(),
                  child: const Text('Create Account'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _formBloc.reset(),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
