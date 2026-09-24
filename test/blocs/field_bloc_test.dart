import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('MkFieldBloc', () {
    test('initializes with pristine state and does not show error on load', () {
      final field = MkFieldBloc<String>(validators: [MkValidators.required()]);

      // Value is null, validator returns an error internally
      expect(field.value, isNull);
      expect(field.isDirty, isFalse);
      expect(field.isTouched, isFalse);
      expect(field.isValid, isFalse);
      expect(field.state.error, 'This field is required');

      // Crucial requirement: user CANNOT see error on initial load before touch/submission
      expect(field.state.showError, isFalse);
    });

    test('showError becomes true when field is touched', () {
      final field = MkFieldBloc<String>(validators: [MkValidators.required()]);

      expect(field.state.showError, isFalse);

      field.touch();

      expect(field.isTouched, isTrue);
      expect(field.state.showError, isTrue);
    });

    test('showError becomes true when form submission is attempted', () {
      final field = MkFieldBloc<String>(validators: [MkValidators.required()]);

      expect(field.state.showError, isFalse);

      field.markFormSubmitted();

      expect(field.state.wasFormSubmitted, isTrue);
      expect(field.state.showError, isTrue);
    });

    test('shouldShowError respects AutovalidateMode', () {
      final field = MkFieldBloc<String>(
        validators: [MkValidators.required('Required')],
      );

      // 1. Pristine / Untouched
      expect(field.state.shouldShowError(AutovalidateMode.always), isTrue);
      expect(field.state.shouldShowError(), isFalse);
      expect(field.state.shouldShowError(AutovalidateMode.disabled), isFalse);

      // 2. Touched (but not submitted)
      field.touch();
      expect(field.state.shouldShowError(AutovalidateMode.always), isTrue);
      expect(field.state.shouldShowError(), isTrue);
      expect(field.state.shouldShowError(AutovalidateMode.disabled), isFalse);

      // 3. Form Submitted
      field.markFormSubmitted();
      expect(field.state.shouldShowError(AutovalidateMode.always), isTrue);
      expect(field.state.shouldShowError(), isTrue);
      expect(field.state.shouldShowError(AutovalidateMode.disabled), isTrue);

      // 4. When valid (no error), always returns false
      field.changeValue('valid value');
      expect(field.state.shouldShowError(AutovalidateMode.always), isFalse);
      expect(field.state.shouldShowError(), isFalse);
      expect(field.state.shouldShowError(AutovalidateMode.disabled), isFalse);
    });

    test('isDirty tracks modification from initial value correctly', () {
      final field = MkFieldBloc<String>(
        initialValue: 'initial',
        validators: [MkValidators.required()],
      );

      expect(field.isDirty, isFalse);
      expect(field.state.isPure, isTrue);

      field.changeValue('modified');
      expect(field.isDirty, isTrue);
      expect(field.state.isPure, isFalse);

      // When restored to initial value, field returns to pure/not dirty
      field.changeValue('initial');
      expect(field.isDirty, isFalse);
      expect(field.state.isPure, isTrue);
    });

    test('reset restores initial value, resets dirty and touched', () {
      final field = MkFieldBloc<String>(
        initialValue: 'initial',
        validators: [MkValidators.required()],
      );

      field.changeValue('modified');
      field.touch();
      field.markFormSubmitted();

      expect(field.isDirty, isTrue);
      expect(field.isTouched, isTrue);
      expect(field.state.wasFormSubmitted, isTrue);

      field.reset();

      expect(field.value, 'initial');
      expect(field.isDirty, isFalse);
      expect(field.isTouched, isFalse);
      expect(field.state.wasFormSubmitted, isFalse);
      expect(field.state.showError, isFalse);
    });

    group('Cross-field dependent validation (e.g. password & confirmPassword)', () {
      test('confirmPassword automatically revalidates when password changes', () {
        final passwordField = MkFieldBloc<String>(
          validators: [MkValidators.required(), MkValidators.minLength(6)],
        );

        final confirmPasswordField = MkFieldBloc<String>(
          validators: [
            MkValidators.required(),
            MkValidators.matchControl(passwordField, 'Passwords do not match'),
          ],
          dependsOn: [passwordField],
        );

        // Initially both untouched
        expect(confirmPasswordField.state.showError, isFalse);

        // User enters password and touches confirmPassword
        passwordField.changeValue('secret123');
        confirmPasswordField.changeValue('secret123');
        confirmPasswordField.touch();

        expect(passwordField.isValid, isTrue);
        expect(confirmPasswordField.isValid, isTrue);
        expect(confirmPasswordField.state.error, isNull);

        // User changes password -> confirmPassword must automatically invalidate!
        passwordField.changeValue('newSecret999');

        expect(confirmPasswordField.isValid, isFalse);
        expect(confirmPasswordField.state.error, 'Passwords do not match');
        expect(confirmPasswordField.state.showError, isTrue);

        // User updates confirmPassword to match
        confirmPasswordField.changeValue('newSecret999');

        expect(confirmPasswordField.isValid, isTrue);
        expect(confirmPasswordField.state.error, isNull);
      });

      test('bidirectional dependencies validate without infinite loops', () {
        late final MkFieldBloc<String> fieldA;
        late final MkFieldBloc<String> fieldB;

        fieldA = MkFieldBloc<String>(
          initialValue: 'alpha',
          validators: [MkValidators.match(() => fieldB.value, 'Must match B')],
        );

        fieldB = MkFieldBloc<String>(
          initialValue: 'beta',
          validators: [MkValidators.match(() => fieldA.value, 'Must match A')],
          dependsOn: [fieldA],
        );

        // Add A depending on B as well
        fieldA.addDependency(fieldB);

        // They do not match initially
        expect(fieldA.isValid, isFalse);
        expect(fieldB.isValid, isFalse);

        // Change fieldA to match fieldB -> triggers revalidation of fieldB, no stack overflow
        fieldA.changeValue('beta');

        expect(fieldA.isValid, isTrue);
        expect(fieldB.isValid, isTrue);
      });
    });

    group('Async validation with debouncing', () {
      test('runs async validation after debounce time', () async {
        final field = MkFieldBloc<String>(
          asyncValidators: [
            (val) async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              return val == 'taken' ? 'Username is taken' : null;
            },
          ],
          debounceTime: const Duration(milliseconds: 50),
        );

        expect(field.isValidating, isFalse);

        field.changeValue('taken');

        // Immediately indicates validating
        expect(field.isValidating, isTrue);

        // Await debounce and validation completion
        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(field.isValidating, isFalse);
        expect(field.isValid, isFalse);
        expect(field.state.error, 'Username is taken');
      });

      test(
        'cancels stale async validation when a newer value is emitted',
        () async {
          final calls = <String>[];
          final field = MkFieldBloc<String>(
            asyncValidators: [
              (val) async {
                calls.add(val!);
                await Future<void>.delayed(const Duration(milliseconds: 80));
                return val == 'taken' ? 'Taken' : null;
              },
            ],
            debounceTime: const Duration(milliseconds: 50),
          );

          field.changeValue('taken');
          // Type another character before debounce timer fires
          await Future<void>.delayed(const Duration(milliseconds: 20));
          field.changeValue('available');

          await Future<void>.delayed(const Duration(milliseconds: 200));

          expect(field.isValidating, isFalse);
          expect(field.isValid, isTrue);
          expect(field.state.error, isNull);
          // Only the second value was validated
          expect(calls, ['available']);
        },
      );
    });

    group('label', () {
      test('is null by default', () {
        final field = MkFieldBloc<String>();
        expect(field.label, isNull);
      });

      test('explicit label is used as-is', () {
        final field = MkFieldBloc<String>(label: 'Work email');
        expect(field.label, 'Work email');
      });

      test('assignAutoLabel humanizes the given name', () {
        final field = MkFieldBloc<String>();
        field.assignAutoLabel('confirmPassword');
        expect(field.label, 'Confirm password');
      });

      test('assignAutoLabel never overwrites an explicit label', () {
        final field = MkFieldBloc<String>(label: 'Work email');
        field.assignAutoLabel('email');
        expect(field.label, 'Work email');
      });

      test(
        'assignAutoLabel can be called again to update the label (last write wins)',
        () {
          final field = MkFieldBloc<String>();
          field.assignAutoLabel('email');
          expect(field.label, 'Email');
          field.assignAutoLabel('workEmail');
          expect(field.label, 'Work email');
        },
      );

      test('label survives reset()', () {
        final field = MkFieldBloc<String>(
          initialValue: 'a@b.com',
          validators: [MkValidators.required()],
        );
        field.assignAutoLabel('email');
        expect(field.label, 'Email');

        field.changeValue('changed@b.com');
        field.reset();

        expect(field.label, 'Email');
      });
    });
  });
}
