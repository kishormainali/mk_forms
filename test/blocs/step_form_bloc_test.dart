import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('MkStepFormBloc', () {
    late MkFieldBloc<String> usernameField;
    late MkFieldBloc<String> emailField;
    late MkFieldBloc<String> passwordField;
    late MkFieldBloc<String> addressField;
    late MkSimpleStepFormBloc stepFormBloc;

    setUp(() {
      usernameField = MkFieldBloc<String>(
        initialValue: '',
        validators: [MkValidators.required('Username is required')],
      );
      emailField = MkFieldBloc<String>(
        initialValue: '',
        validators: [
          MkValidators.required('Email is required'),
          MkValidators.email('Must be valid email'),
        ],
      );
      passwordField = MkFieldBloc<String>(
        initialValue: '',
        validators: [
          MkValidators.required('Password is required'),
          MkValidators.minLength(6, 'Min 6 chars'),
        ],
      );
      addressField = MkFieldBloc<String>(
        initialValue: '',
        validators: [MkValidators.required('Address is required')],
      );

      stepFormBloc = MkSimpleStepFormBloc(
        controls: {
          'username': usernameField,
          'email': emailField,
          'password': passwordField,
          'address': addressField,
        },
        steps: const [
          MkFormStep(
            controlNames: ['username', 'email'],
            title: 'Account',
          ),
          MkFormStep(
            controlNames: ['password'],
            title: 'Security',
          ),
          MkFormStep(
            controlNames: ['address'],
            title: 'Shipping',
          ),
        ],
        onSubmit: (values) async => {'status': 'success'},
      );
    });

    tearDown(() async {
      await stepFormBloc.close();
    });

    test('initial state defaults to step 0 and total steps 3', () {
      expect(stepFormBloc.currentStep, 0);
      expect(stepFormBloc.totalSteps, 3);
      expect(stepFormBloc.state.isFirstStep, isTrue);
      expect(stepFormBloc.state.isLastStep, isFalse);
      expect(stepFormBloc.state.completedSteps, isEmpty);
    });

    test('validating step 0 only marks step 0 controls and does not touch step 1 or 2', () async {
      // Step 0 fields are initially pure
      expect(usernameField.state.showError, isFalse);
      expect(emailField.state.showError, isFalse);
      expect(passwordField.state.showError, isFalse);
      expect(addressField.state.showError, isFalse);

      final valid = await stepFormBloc.validateStep(0);
      expect(valid, isFalse);

      // Step 0 fields now show errors because they are touched/submitted
      expect(usernameField.state.showError, isTrue);
      expect(emailField.state.showError, isTrue);

      // Step 1 and Step 2 fields MUST REMAIN PRISTINE without premature errors!
      expect(passwordField.state.showError, isFalse);
      expect(addressField.state.showError, isFalse);
      expect(passwordField.state.isTouched, isFalse);
      expect(addressField.state.isTouched, isFalse);
    });

    test('nextStep only advances if current step is valid', () async {
      // Attempt nextStep while invalid
      final advanced = await stepFormBloc.nextStep();
      expect(advanced, isFalse);
      expect(stepFormBloc.currentStep, 0);

      // Make step 0 valid
      usernameField.changeValue('alex');
      emailField.changeValue('alex@example.com');

      final advanced2 = await stepFormBloc.nextStep();
      expect(advanced2, isTrue);
      expect(stepFormBloc.currentStep, 1);
      expect(stepFormBloc.state.completedSteps.contains(0), isTrue);

      // Password in step 1 should still be pristine
      expect(passwordField.state.showError, isFalse);
    });

    test('previousStep moves backward without losing form values', () async {
      usernameField.changeValue('alex');
      emailField.changeValue('alex@example.com');
      await stepFormBloc.nextStep();
      expect(stepFormBloc.currentStep, 1);

      passwordField.changeValue('secret123');

      stepFormBloc.previousStep();
      expect(stepFormBloc.currentStep, 0);

      // Values preserved
      expect(usernameField.value, 'alex');
      expect(emailField.value, 'alex@example.com');
      expect(passwordField.value, 'secret123');
    });

    test('goToStep navigates backward freely and validates when navigating forward', () async {
      usernameField.changeValue('alex');
      emailField.changeValue('alex@example.com');
      await stepFormBloc.nextStep();
      expect(stepFormBloc.currentStep, 1);

      // Try skipping to step 2 without validating step 1
      final jumped = await stepFormBloc.goToStep(2);
      expect(jumped, isFalse); // step 1 is invalid (password empty)
      expect(stepFormBloc.currentStep, 1);

      // Fix step 1
      passwordField.changeValue('secret123');
      final jumped2 = await stepFormBloc.goToStep(2);
      expect(jumped2, isTrue);
      expect(stepFormBloc.currentStep, 2);

      // Go back to step 0
      final wentBack = await stepFormBloc.goToStep(0);
      expect(wentBack, isTrue);
      expect(stepFormBloc.currentStep, 0);
    });

    test('loadInitialData populates values, marks pristine, and resumes designated step', () async {
      await stepFormBloc.loadInitialData(
        () async => {
          'username': 'john_doe',
          'email': 'john@example.com',
          'password': 'existingPassword',
          'step': 2,
        },
        resolveInitialStep: (data) => data['step'] as int?,
      );

      expect(stepFormBloc.currentStep, 2);
      expect(usernameField.value, 'john_doe');
      expect(emailField.value, 'john@example.com');
      expect(passwordField.value, 'existingPassword');

      // Crucially, fields are pristine and do NOT show errors
      expect(usernameField.state.isDirty, isFalse);
      expect(usernameField.state.showError, isFalse);
      expect(passwordField.state.isDirty, isFalse);
      expect(addressField.state.showError, isFalse);

      // Preceding steps marked completed
      expect(stepFormBloc.state.completedSteps.contains(0), isTrue);
      expect(stepFormBloc.state.completedSteps.contains(1), isTrue);
      expect(stepFormBloc.state.wasRedirectedDueToError, isFalse);
    });

    test(
        'loadInitialData redirects to invalid step when preceding step has validation errors and preserves all data',
        () async {
      // Step 0 requires username min 3 chars and valid email.
      // We pass an invalid email in step 0, valid password in step 1, and target step 2.
      await stepFormBloc.loadInitialData(
        () async => {
          'username': 'john_doe',
          'email': 'not-an-email', // INVALID!
          'password': 'validSecretPassword', // Step 1 is valid
          'address': '123 Main St', // Step 2 is populated
          'step': 2,
        },
        resolveInitialStep: (data) => data['step'] as int?,
      );

      // Must redirect to Step 0 (first invalid step)
      expect(stepFormBloc.currentStep, 0);
      expect(stepFormBloc.state.wasRedirectedDueToError, isTrue);
      expect(stepFormBloc.state.redirectedFromStep, 2);
      expect(stepFormBloc.state.invalidStepIndex, 0);

      // Step 0 invalid field is touched and displays the error
      expect(emailField.state.isTouched, isTrue);
      expect(emailField.state.showError, isTrue);
      expect(emailField.state.error, contains('valid email'));

      // ALL data from other steps is completely PRESERVED
      expect(usernameField.value, 'john_doe');
      expect(emailField.value, 'not-an-email');
      expect(passwordField.value, 'validSecretPassword');
      expect(addressField.value, '123 Main St');
      expect(stepFormBloc.values['password'], 'validSecretPassword');
      expect(stepFormBloc.values['address'], '123 Main St');

      // Subsequent steps were not touched
      expect(passwordField.state.isTouched, isFalse);
      expect(passwordField.state.showError, isFalse);
      expect(addressField.state.isTouched, isFalse);
      expect(addressField.state.showError, isFalse);
    });

    test('custom initialStep parameter starts directly at requested step', () async {
      final resumedBloc = MkSimpleStepFormBloc(
        controls: {
          'username': MkFieldBloc<String>(initialValue: 'saved_user'),
          'email': MkFieldBloc<String>(initialValue: 'saved@example.com'),
          'password': MkFieldBloc<String>(),
        },
        steps: const [
          MkFormStep(controlNames: ['username', 'email']),
          MkFormStep(controlNames: ['password']),
        ],
        initialStep: 1,
        onSubmit: (values) async => null,
      );

      expect(resumedBloc.currentStep, 1);
      await resumedBloc.close();
    });
  });
}
