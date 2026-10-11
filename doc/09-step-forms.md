# 9. Step Forms & Multi-Route Wizards

`MkStepFormBloc` is an `MkFormBloc` that partitions its controls into `MkFormStep`s. Moving forward validates only the current step, so later steps stay pristine (no premature errors).

## API

| Call | Behavior |
|---|---|
| `nextStep()` → `Future<bool>` | Validate current step; advance if valid |
| `previousStep()` | Go back unconditionally |
| `goToStep(i)` | Jump; validates intermediate steps when going forward |
| `validateStep(i)` | Validate one step's controls only |
| `loadInitialData(fetch, resolveInitialStep:)` | Hydrate a remote draft, pristine, then jump to the right step |
| `submit()` | Validates every step, then `onSubmit` |

`MkStepFormState` (the runtime state type; read it with `MkFormStateBuilder<MkStepFormState>`) adds `currentStep`, `totalSteps`, `completedSteps`, `isLoadingInitialData`, `isFirstStep`, `isLastStep`, `stepProgress`. `MkSimpleStepFormBloc` is the inline-closure variant.

## Navigation is serialized

`nextStep()` and forward `goToStep()` ignore a call made while another navigation is still validating (a double tap, or slow async validators) and return `false`. This prevents skipping a step and pushing a route twice, so the usual pattern is safe as written:

```dart
if (await form.nextStep() && context.mounted) context.pushRoute(const Step1Route());
```

## Multi-route wizards and rebuilds

Routes lower in the Navigator stack stay mounted, so a `MkFormBuilder` without `buildWhen` on an earlier page rebuilds on every keystroke typed on the current page. Use `MkFormSelector` (or `buildWhen`) on every page:

```dart
MkFormSelector<bool>(selector: (s) => s.isValid, builder: (context, ok, form) => ...)
```

Fields are unaffected: each `MkTextField` only listens to its own bloc.

## Draft hydration & smart redirect

`loadInitialData` populates all values as pristine, finds the earliest invalid step, redirects there, shows errors **only on that step**, and marks earlier valid steps completed.

## Full example — 3-step onboarding with draft loading (single screen)

For a multi-route wizard, create the bloc above your `Navigator` (e.g. in a parent route) and `MkFormScope.value` it to each route; each route calls `nextStep()` then pushes the next page, exactly as the buttons below do.

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

class DraftRepository {
  Future<Map<String, dynamic>> fetchDraft() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    // Step 0 is missing "email" -> wizard redirects there on load.
    return {
      'username': 'kishor',
      'fullName': 'Kishor Mainali',
      'role': 'developer',
      'lastCompletedStep': 1,
    };
  }

  Future<void> complete(Map<String, dynamic> v) async =>
      Future<void>.delayed(const Duration(seconds: 1));
}

final draftRepository = DraftRepository();

class OnboardingFormBloc extends MkStepFormBloc {
  OnboardingFormBloc()
      : super(
          controls: {
            'username': MkFieldBloc<String>(validators: [MkValidators.required()]),
            'email': MkFieldBloc<String>(
              validators: [MkValidators.required(), MkValidators.email()],
            ),
            'fullName': MkFieldBloc<String>(validators: [MkValidators.required()]),
            'role': MkFieldBloc<String>(initialValue: 'developer'),
            'interests': MkFieldBloc<List<String>>(validators: [MkValidators.required()]),
            'agreeTerms': MkFieldBloc<bool>(validators: [MkValidators.required()]),
          },
          steps: const [
            MkFormStep(controlNames: ['username', 'email'], title: 'Account'),
            MkFormStep(controlNames: ['fullName', 'role'], title: 'Profile'),
            MkFormStep(controlNames: ['interests', 'agreeTerms'], title: 'Preferences'),
          ],
        );

  @override
  Future<void> onSubmit(Map<String, dynamic> values) => draftRepository.complete(values);
}

void main() => runApp(const MaterialApp(home: OnboardingScreen()));

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnboardingFormBloc _form;

  @override
  void initState() {
    super.initState();
    _form = OnboardingFormBloc()
      ..loadInitialData(
        () => draftRepository.fetchDraft(),
        resolveInitialStep: (data) => data['lastCompletedStep'] as int? ?? 0,
      );
  }

  @override
  void dispose() {
    _form.close();
    super.dispose();
  }

  Widget _stepBody(int step) => switch (step) {
        0 => const Column(children: [
            MkTextField(name: 'username', decoration: InputDecoration(labelText: 'Username')),
            SizedBox(height: 12),
            MkEmailField(name: 'email'),
          ]),
        1 => Column(children: [
            const MkTextField(name: 'fullName', decoration: InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            MkRadioGroup<String>(
              name: 'role',
              title: const Text('Role'),
              options: const [
                MkRadioOption(value: 'developer', label: Text('Developer')),
                MkRadioOption(value: 'designer', label: Text('Designer')),
              ],
            ),
          ]),
        _ => const Column(children: [
            MkMultiSelectSearchDropdown<String>(
              name: 'interests',
              items: ['Flutter', 'Dart', 'Firebase'],
              itemToString: _identity,
              decoration: InputDecoration(labelText: 'Interests'),
            ),
            MkCheckboxField(name: 'agreeTerms', title: Text('I agree to the terms')),
          ]),
      };

  @override
  Widget build(BuildContext context) {
    return MkFormScope.value(
      value: _form,
      child: MkFormListener(
        formBloc: _form,
        onSuccess: (context, _) => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Onboarding complete'))),
        child: Scaffold(
          appBar: AppBar(title: const Text('Onboarding')),
          // The bloc's declared state is MkFormState; at runtime it is an
          // MkStepFormState, which MkFormStateBuilder casts for you.
          body: MkFormStateBuilder<MkStepFormState>(
            formBloc: _form,
            builder: (context, state, form) {
              if (state.isLoadingInitialData) {
                return const Center(child: CircularProgressIndicator());
              }
              final isLast = state.currentStep == 2;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  LinearProgressIndicator(value: (state.currentStep + 1) / 3),
                  const SizedBox(height: 24),
                  _stepBody(state.currentStep),
                  const Spacer(),
                  Row(children: [
                    if (state.currentStep > 0)
                      OutlinedButton(onPressed: _form.previousStep, child: const Text('Back')),
                    const Spacer(),
                    FilledButton(
                      onPressed: () async =>
                          isLast ? _form.submit() : await _form.nextStep(),
                      child: Text(isLast ? 'Finish' : 'Next'),
                    ),
                  ]),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _identity(String s) => s;
```

## Inline variant

```dart
final form = MkSimpleStepFormBloc(
  controls: { /* ... */ },
  steps: const [ /* ... */ ],
  onSubmit: (values) async => api.submit(values),
);
```

Next: [Subforms](10-subforms.md).
