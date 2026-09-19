import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../bloc/onboarding_form_bloc.dart';

/// Screen for Step 3 of onboarding: Preferences & Final Submission.
@RoutePage()
class PreferencesStepScreen extends StatelessWidget {
  const PreferencesStepScreen({
    super.key,
    required this.formBloc,
  });

  final OnboardingFormBloc formBloc;

  @override
  Widget build(BuildContext context) {
    return MkFormScope(
      formBloc: formBloc,
      child: MkFormListener(
        formBloc: formBloc,
        onSubmitting: (context) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saving complete onboarding profile...'),
              duration: Duration(milliseconds: 1000),
            ),
          );
        },
        onSuccess: (context, response) {
          unawaited(
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('🎉 Onboarding Completed!'),
                content: Text(
                  'Welcome, ${formBloc.values['fullName']} (@${formBloc.values['username']})!\n\n'
                  'All 3 steps across different routes were validated and submitted successfully '
                  'via the 2-layer OnboardingRepository.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(); // pop dialog
                      context.router.popUntilRoot();
                    },
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          );
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Onboarding: Step 3 / 3'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LinearProgressIndicator(value: 1.0),
                const SizedBox(height: 16),
                Text(
                  'Preferences & Confirmation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                MkMultiSelectSearchDropdown<String>(
                  name: 'interests',
                  modalTitle: 'Select Technologies & Interests',
                  searchHint: 'Search interests...',
                  items: const [
                    'Flutter',
                    'Dart',
                    'Mobile',
                    'Web',
                    'Bloc',
                    'DevOps',
                    'AI / ML',
                  ],
                  itemToString: (item) => item,
                  decoration: const InputDecoration(
                    labelText: 'Areas of Interest',
                    prefixIcon: Icon(Icons.star_outline),
                  ),
                ),
                const SizedBox(height: 16),
                const MkCheckboxField(
                  name: 'notificationEmails',
                  title: Text('Receive product updates and newsletters'),
                ),
                const SizedBox(height: 12),
                const MkCheckboxField(
                  name: 'agreeTerms',
                  title: Text('I agree to the Terms of Service and Privacy Policy'),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => formBloc.submit(),
                  child: const Text('Complete Onboarding & Submit'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    formBloc.previousStep();
                    unawaited(context.router.maybePop());
                  },
                  child: const Text('← Back to Step 2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
