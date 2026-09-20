import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../core/router/app_router.gr.dart';
import '../bloc/onboarding_form_bloc.dart';

/// Screen for Step 2 of onboarding: Profile Information.
@RoutePage()
class ProfileStepScreen extends StatelessWidget {
  const ProfileStepScreen({super.key, required this.formBloc});

  final OnboardingFormBloc formBloc;

  @override
  Widget build(BuildContext context) {
    return MkFormScope.value(
      value: formBloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Onboarding: Step 2 / 3')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LinearProgressIndicator(value: 0.66),
              const SizedBox(height: 16),
              Text(
                'Personal & Professional Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Notice that going back to Step 1 retains all values cleanly.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              const MkTextField(
                name: 'fullName',
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              const MkDropdownField<String>(
                name: 'role',
                decoration: InputDecoration(
                  labelText: 'Primary Role',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'developer',
                    child: Text('Developer'),
                  ),
                  DropdownMenuItem(value: 'designer', child: Text('Designer')),
                  DropdownMenuItem(
                    value: 'product_manager',
                    child: Text('Product Manager'),
                  ),
                  DropdownMenuItem(value: 'founder', child: Text('Founder')),
                ],
              ),
              const SizedBox(height: 16),
              const MkTextField(
                name: 'bio',
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Short Bio (Optional)',
                  hintText: 'Tell us a bit about what you are building...',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () async {
                  final canProceed = await formBloc.nextStep();
                  if (canProceed && context.mounted) {
                    unawaited(
                      context.router.push(
                        PreferencesStepRoute(formBloc: formBloc),
                      ),
                    );
                  }
                },
                child: const Text('Continue to Preferences →'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  formBloc.previousStep();
                  unawaited(context.router.maybePop());
                },
                child: const Text('← Back to Step 1'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
