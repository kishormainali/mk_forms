import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/login_form_bloc.dart';

/// Minimal Login screen powered by [LoginFormBloc].
///
/// Demonstrates:
/// - Clean Architecture separation: business logic lives inside [LoginFormBloc].
/// - Pristine state handling (fields start pure, no errors on initial render).
/// - Submission lifecycle and error clearing upon user modification.
@RoutePage()
class MinimalLoginScreen extends StatefulWidget {
  const MinimalLoginScreen({
    super.key,
    LoginFormBloc? formBloc,
  }) : _formBloc = formBloc;

  final LoginFormBloc? _formBloc;

  @override
  State<MinimalLoginScreen> createState() => _MinimalLoginScreenState();
}

class _MinimalLoginScreenState extends State<MinimalLoginScreen> {
  late final LoginFormBloc _formBloc;

  @override
  void initState() {
    super.initState();
    _formBloc = widget._formBloc ?? getIt<LoginFormBloc>();
  }

  @override
  void dispose() {
    unawaited(_formBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minimal Form (Login)'),
      ),
      body: MkFormScope.value(
        value: _formBloc,
        child: MkFormListener(
          formBloc: _formBloc,
          onSubmitting: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Submitting login...'),
                duration: Duration(milliseconds: 800),
              ),
            );
          },
          onSuccess: (context, response) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful! Welcome back.'),
                backgroundColor: Colors.green,
              ),
            );
          },
          onFailure: (context, error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login failed: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome to mk_forms',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your credentials below. Errors only appear after interacting or attempting to submit.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    const MkEmailField(name: 'email'),
                    const SizedBox(height: 16),
                    const MkPasswordField(name: 'password'),
                    const SizedBox(height: 24),
                    BlocBuilder<MkFormBloc, MkFormState>(
                      bloc: _formBloc,
                      buildWhen: (prev, curr) =>
                          prev.submissionStatus != curr.submissionStatus,
                      builder: (context, formState) {
                        return FilledButton(
                          onPressed: formState.isSubmitting
                              ? null
                              : () => _formBloc.submit(),
                          child: formState.isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign In'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
