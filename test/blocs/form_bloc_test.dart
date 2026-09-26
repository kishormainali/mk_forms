import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

class TestTypedFormBloc extends MkFormBloc<String> {
  TestTypedFormBloc() : super(controls: const {});

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async => null;
}

class TestLoginFormBloc extends MkFormBloc {
  TestLoginFormBloc({this.shouldSucceed = true})
    : super(
        controls: {
          'email': MkFieldBloc<String>(
            validators: [MkValidators.required(), MkValidators.email()],
          ),
          'password': MkFieldBloc<String>(
            validators: [MkValidators.required(), MkValidators.minLength(6)],
          ),
        },
      );

  final bool shouldSucceed;
  int submitCalls = 0;

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    submitCalls++;
    if (!shouldSucceed) {
      throw Exception('Invalid email or password');
    }
    return {'userId': '123', 'token': 'abc'};
  }
}

void main() {
  group('MkFormBloc', () {
    test(
      'submitting when invalid touches all fields and halts before onSubmit',
      () async {
        final form = TestLoginFormBloc();

        final emailField = form.field<String>('email')!;
        final passwordField = form.field<String>('password')!;

        expect(emailField.state.showError, isFalse);
        expect(passwordField.state.showError, isFalse);
        expect(form.state.wasSubmitted, isFalse);

        await form.submit();

        // Submission halted because fields are invalid
        expect(form.submitCalls, 0);
        expect(form.state.wasSubmitted, isTrue);
        expect(form.state.submissionStatus.isIdle, isTrue);

        // Errors are now visible to user
        expect(emailField.state.showError, isTrue);
        expect(passwordField.state.showError, isTrue);
      },
    );

    test(
      'submitting when valid invokes onSubmit and transitions to success',
      () async {
        final form = TestLoginFormBloc();

        form.field<String>('email')!.changeValue('test@example.com');
        form.field<String>('password')!.changeValue('password123');

        expect(form.state.isValid, isTrue);

        await form.submit();

        expect(form.submitCalls, 1);
        expect(form.state.isSuccess, isTrue);
        final status = form.state.submissionStatus as MkSubmissionSuccess;
        expect(status.response, {'userId': '123', 'token': 'abc'});
      },
    );

    test(
      'submission failure sets submissionError, and modifying any field clears it',
      () async {
        final form = TestLoginFormBloc(shouldSucceed: false);

        form.field<String>('email')!.changeValue('test@example.com');
        form.field<String>('password')!.changeValue('wrongpass');

        await form.submit();

        expect(form.submitCalls, 1);
        expect(form.state.isFailure, isTrue);
        expect(
          form.state.submissionError.toString(),
          contains('Invalid email or password'),
        );

        // Crucial requirement: modifying any field clears submission failure
        // so user does NOT see repeated error banners!
        form.field<String>('password')!.changeValue('newAttempt123');

        expect(form.state.submissionStatus.isIdle, isTrue);
        expect(form.state.submissionError, isNull);
      },
    );

    test('setFieldErrors maps backend errors directly onto fields', () {
      final form = TestLoginFormBloc();
      final emailField = form.field<String>('email')!;

      expect(emailField.state.error, 'This field is required');

      form.setFieldErrors({
        'email': 'Email is already taken by another account',
      });

      expect(
        emailField.state.error,
        'Email is already taken by another account',
      );
      expect(emailField.state.showError, isTrue);
    });

    test(
      'MkSimpleFormBloc allows minimal form setup without subclassing',
      () async {
        int submitCount = 0;
        final simpleForm = MkSimpleFormBloc(
          controls: {'search': MkFieldBloc<String>(initialValue: 'Flutter')},
          onSubmit: (values) async {
            submitCount++;
            return 'Results for ${values['search']}';
          },
        );

        await simpleForm.submit();

        expect(submitCount, 1);
        expect(simpleForm.state.isSuccess, isTrue);
      },
    );

    test(
      'a non-nullable T without an explicit initialState throws at construction',
      () {
        expect(() => TestTypedFormBloc(), throwsA(isA<TypeError>()));
      },
    );

    test('unregisterControl closes the removed control by default', () {
      final form = MkSimpleFormBloc(
        controls: const {},
        onSubmit: (values) async => null,
      );
      final extra = MkFieldBloc<String>(initialValue: 'a');

      form.registerControl('extra', extra);
      expect(form.values, {'extra': 'a'});

      final removed = form.unregisterControl('extra');

      expect(removed, same(extra));
      expect(extra.isClosed, isTrue);
    });

    test('unregisterControl(dispose: false) then registerControl re-activates '
        'the same field instance (the conditional-field toggle pattern)', () {
      final form = MkSimpleFormBloc(
        controls: const {},
        onSubmit: (values) async => null,
      );
      final extra = MkFieldBloc<String>(initialValue: 'a');

      form.registerControl('extra', extra);
      form.unregisterControl('extra', dispose: false);
      expect(extra.isClosed, isFalse);

      form.registerControl('extra', extra);
      extra.changeValue('b');
      expect(form.values, {'extra': 'b'});
    });
  });
}
