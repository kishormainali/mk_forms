import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../data/models/onboarding_data.dart';
import '../../../../data/repositories/onboarding_repository.dart';

/// Form bloc coordinating the 3-step onboarding flow across multiple routes.
@injectable
class OnboardingFormBloc extends MkStepFormBloc {
  OnboardingFormBloc(OnboardingRepository repository)
    : _repository = repository,
      super(
        controls: {
          // Step 0: Account Controls
          'username': MkFieldBloc<String>(
            initialValue: '',
            validators: [
              MkValidators.required('Username is required'),
              MkValidators.minLength(3, 'Must be at least 3 characters'),
            ],
          ),
          'email': MkFieldBloc<String>(
            initialValue: '',
            validators: [
              MkValidators.required('Email is required'),
              MkValidators.email('Please enter a valid email'),
            ],
          ),
          'password': MkFieldBloc<String>(
            initialValue: '',
            validators: [
              MkValidators.required('Password is required'),
              MkValidators.minLength(
                6,
                'Password must be at least 6 characters',
              ),
            ],
          ),

          // Step 1: Profile Controls
          'fullName': MkFieldBloc<String>(
            initialValue: '',
            validators: [MkValidators.required('Full name is required')],
          ),
          'role': MkFieldBloc<String>(
            initialValue: 'developer',
            validators: [MkValidators.required('Role is required')],
          ),
          'bio': MkFieldBloc<String>(initialValue: ''),

          // Step 2: Preferences Controls
          'interests': MkFieldBloc<List<String>>(
            initialValue: const ['Flutter', 'Mobile'],
            validators: [
              (list) => (list == null || list.isEmpty)
                  ? 'Select at least one interest'
                  : null,
            ],
          ),
          'notificationEmails': MkFieldBloc<bool>(initialValue: true),
          'agreeTerms': MkFieldBloc<bool>(
            initialValue: false,
            validators: [
              MkValidators.required('You must accept terms to finish'),
            ],
          ),
        },
        steps: const [
          MkFormStep(
            controlNames: ['username', 'email', 'password'],
            title: 'Account',
            subtitle: 'Set up credentials',
          ),
          MkFormStep(
            controlNames: ['fullName', 'role', 'bio'],
            title: 'Profile',
            subtitle: 'Personal information',
          ),
          MkFormStep(
            controlNames: ['interests', 'notificationEmails', 'agreeTerms'],
            title: 'Preferences',
            subtitle: 'Tailor your experience',
          ),
        ],
      );

  final OnboardingRepository _repository;

  /// Loads an existing onboarding draft from the backend and jumps to the saved step.
  Future<void> loadDraft() async {
    await loadInitialData(() async {
      final draft = await _repository.fetchDraft();
      return draft.toJson();
    }, resolveInitialStep: (data) => data['step'] as int?);
  }

  /// Loads an onboarding draft that has validation errors in an earlier step
  /// to demonstrate automated redirection to the invalid step and data preservation.
  Future<void> loadInvalidDraft() async {
    await loadInitialData(() async {
      final draft = await _repository.fetchInvalidDraft();
      return draft.toJson();
    }, resolveInitialStep: (data) => data['step'] as int?);
  }

  @override
  Future<void> onSubmit(Map<String, dynamic> values) async {
    final onboardingPayload = OnboardingData(
      username: values['username'] as String,
      email: values['email'] as String,
      password: values['password'] as String,
      fullName: values['fullName'] as String,
      role: values['role'] as String,
      bio: values['bio'] as String?,
      interests: (values['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      notificationEmails: values['notificationEmails'] as bool? ?? true,
      agreeTerms: values['agreeTerms'] as bool? ?? false,
      currentStep: currentStep,
    );

    await _repository.saveProgress(onboardingPayload);
  }
}
