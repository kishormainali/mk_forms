import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../core/router/app_router.gr.dart';
import '../bloc/onboarding_form_bloc.dart';

/// Screen for Step 1 of onboarding: Account Credentials.
@RoutePage()
class AccountStepScreen extends StatelessWidget {
  const AccountStepScreen({
    super.key,
    required this.formBloc,
  });

  final OnboardingFormBloc formBloc;

  @override
  Widget build(BuildContext context) {
    return MkFormScope(
      formBloc: formBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Onboarding: Step 1 / 3'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.cloud_download_outlined),
              tooltip: 'Load Draft from API',
              onSelected: (choice) async {
                if (choice == 'valid') {
                  await formBloc.loadDraft();
                  if (context.mounted && formBloc.currentStep > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Loaded draft! Jumping to Step ${formBloc.currentStep + 1}',
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                    unawaited(
                      context.router.push(ProfileStepRoute(formBloc: formBloc)),
                    );
                  }
                } else if (choice == 'invalid') {
                  await formBloc.loadInvalidDraft();
                  if (context.mounted) {
                    if (formBloc.state.wasRedirectedDueToError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '⚠️ Draft requested Step ${(formBloc.state.redirectedFromStep ?? 0) + 1}, '
                            'but Step ${(formBloc.state.invalidStepIndex ?? 0) + 1} has validation errors! '
                            'Redirected to Step ${(formBloc.state.invalidStepIndex ?? 0) + 1}.',
                          ),
                          backgroundColor: Colors.orange.shade800,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'valid',
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline, color: Colors.green),
                    title: Text('Load Valid Draft (Step 2)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'invalid',
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_outlined, color: Colors.orange),
                    title: Text('Load Invalid Draft (Redirects to Step 1)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Load API Draft'),
              onPressed: () async {
                await formBloc.loadDraft();
                if (context.mounted && formBloc.currentStep > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Loaded draft! Jumping to Step ${formBloc.currentStep + 1}',
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                  unawaited(context.router.push(ProfileStepRoute(formBloc: formBloc)));
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LinearProgressIndicator(value: 0.33),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Step 1: Account Information\n'
                    '• Validating here does NOT show errors on Step 2 or 3.\n'
                    '• Tap "Load API Draft" above to test hydrating saved values from API.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const MkTextField(
                name: 'username',
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              const MkEmailField(name: 'email'),
              const SizedBox(height: 16),
              const MkPasswordField(name: 'password'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () async {
                  final canProceed = await formBloc.nextStep();
                  if (canProceed && context.mounted) {
                    unawaited(context.router.push(ProfileStepRoute(formBloc: formBloc)));
                  }
                },
                child: const Text('Continue to Profile →'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
