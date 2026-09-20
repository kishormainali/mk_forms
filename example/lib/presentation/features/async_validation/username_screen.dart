import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/username_form_bloc.dart';

/// Screen demonstrating debounced async validation powered by [UsernameFormBloc].
@RoutePage()
class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key, UsernameFormBloc? formBloc})
    : _formBloc = formBloc;

  final UsernameFormBloc? _formBloc;

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  late final UsernameFormBloc _formBloc;

  @override
  void initState() {
    super.initState();
    _formBloc = widget._formBloc ?? getIt<UsernameFormBloc>();
  }

  @override
  void dispose() {
    unawaited(_formBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usernameBloc = _formBloc.field<String>('username');

    return Scaffold(
      appBar: AppBar(title: const Text('Async Validation')),
      body: MkFormScope.value(
        value: _formBloc,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Asynchronous Server Checking:\n'
                    '• Taken names: admin, flutter, mk7, google, john\n'
                    '• Notice the loading spinner in the field suffix\n'
                    '• Debounced at 400ms: fast typing cancels pending checks\n'
                    '• Sync validation runs first to avoid unnecessary API requests.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              MkTextField(
                fieldBloc: usernameBloc,
                decoration: const InputDecoration(
                  labelText: 'Pick a Username',
                  hintText: 'e.g. alex_dev',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 24),
              MkFieldBuilder<String>(
                fieldBloc: usernameBloc,
                builder: (context, state, bloc) {
                  return FilledButton.icon(
                    onPressed: (state.isValid && !state.isValidating)
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Username "${state.value}" is reserved successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        : null,
                    icon: state.isValidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      state.isValidating
                          ? 'Checking availability...'
                          : 'Claim Username',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
