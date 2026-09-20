import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

/// Counts how many state listeners have been attached to it.
class _SpyField extends MkFieldBloc<String> {
  _SpyField();

  int listenersAdded = 0;

  @override
  void addStateListener(void Function() listener) {
    listenersAdded++;
    super.addStateListener(listener);
  }
}

/// Maps a "server" error onto a field from inside [onSubmitFailure].
class _ServerErrorForm extends MkFormBloc {
  _ServerErrorForm(Map<String, MkControlBloc<dynamic>> controls)
      : super(controls: controls);

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async =>
      throw Exception('rejected');

  @override
  void onSubmitFailure(Object error) =>
      setFieldErrors({'email': 'Email is already taken'});
}

MkFieldBloc<String> _slowAsyncField() => MkFieldBloc<String>(
      initialValue: 'x',
      debounceTime: Duration.zero,
      asyncValidators: [
        (v) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return null;
        },
      ],
    );

void main() {
  _closeRegressions();

  group('initial state does not leak control listeners', () {
    test('MkFormBloc attaches exactly one listener per control', () async {
      final field = _SpyField();
      final form = MkSimpleFormBloc(
        controls: {'a': field},
        onSubmit: (v) async => null,
      );
      expect(field.listenersAdded, 1);
      await form.close();
    });

    test('MkStepFormBloc attaches exactly one listener per control', () async {
      final field = _SpyField();
      final form = MkSimpleStepFormBloc(
        controls: {'a': field},
        steps: const [
          MkFormStep(controlNames: ['a']),
        ],
        onSubmit: (v) async => null,
      );
      expect(field.listenersAdded, 1);
      await form.close();
    });
  });

  group('submit()', () {
    test('back-to-back calls invoke onSubmit only once', () async {
      var calls = 0;
      final form = MkSimpleFormBloc(
        controls: {'a': MkFieldBloc<String>(initialValue: 'x')},
        onSubmit: (v) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        },
      );

      await Future.wait([form.submit(), form.submit()]);

      expect(calls, 1);
      await form.close();
    });

    test('can be submitted again after the previous submit finished', () async {
      var calls = 0;
      final form = MkSimpleFormBloc(
        controls: {'a': MkFieldBloc<String>(initialValue: 'x')},
        onSubmit: (v) async => calls++,
      );

      await form.submit();
      await form.submit();

      expect(calls, 2);
      await form.close();
    });

    test('can be retried after onSubmit throws', () async {
      var calls = 0;
      final form = MkSimpleFormBloc(
        controls: {'a': MkFieldBloc<String>(initialValue: 'x')},
        onSubmit: (v) async {
          calls++;
          throw Exception('nope');
        },
      );

      await form.submit();
      await form.submit();

      expect(calls, 2);
      await form.close();
    });

    test(
        'editing a field while async validation is in flight still submits '
        'the latest value', () async {
      Map<String, dynamic>? submitted;
      final field = _slowAsyncField();
      final form = MkSimpleFormBloc(
        controls: {'a': field},
        onSubmit: (v) async => submitted = v,
      );

      final pending = form.submit();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      field.changeValue('xy'); // user types mid-validation
      await pending;
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(submitted, {'a': 'xy'});
      expect(form.state.isSuccess, isTrue);
      await form.close();
    });

    test('an in-flight validate() resolves to the outcome of the newer one',
        () async {
      final field = MkFieldBloc<String>(
        initialValue: 'x',
        asyncValidators: [
          (v) async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return v == 'bad' ? 'rejected' : null;
          },
        ],
      );

      final first = field.validate();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = field.validate(); // supersedes `first`

      expect(await second, isTrue);
      expect(await first, isTrue);
      await field.close();
    });
  });

  group('submission failure state', () {
    test('mapping server errors in onSubmitFailure keeps the failure',
        () async {
      final email = MkFieldBloc<String>(initialValue: 'a@b.com');
      final form = _ServerErrorForm({'email': email});

      await form.submit();

      expect(email.error, 'Email is already taken');
      expect(form.state.isFailure, isTrue);
      expect(form.state.submissionError, isA<Exception>());
      await form.close();
    });

    test('touching a field does not clear the failure', () async {
      final email = MkFieldBloc<String>(initialValue: 'a@b.com');
      final form = _ServerErrorForm({'email': email});
      await form.submit();

      email.touch();

      expect(form.state.isFailure, isTrue);
      await form.close();
    });

    test('editing a field still clears the failure', () async {
      final email = MkFieldBloc<String>(initialValue: 'a@b.com');
      final form = _ServerErrorForm({'email': email});
      await form.submit();

      email.changeValue('other@b.com');

      expect(form.state.isFailure, isFalse);
      expect(form.state.submissionError, isNull);
      await form.close();
    });

    test('editing a nested group field still clears the failure', () async {
      final street = MkFieldBloc<String>(initialValue: 'Main St');
      final form = MkSimpleFormBloc(
        controls: {
          'address': MkGroupBloc({'street': street}),
        },
        onSubmit: (v) async => throw Exception('rejected'),
      );
      await form.submit();
      expect(form.state.isFailure, isTrue);

      street.changeValue('Second St');

      expect(form.state.isFailure, isFalse);
      await form.close();
    });
  });
}

MkFieldBloc<String> _slowField() => MkFieldBloc<String>(
      initialValue: 'x',
      debounceTime: Duration.zero,
      asyncValidators: [
        (v) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return null;
        },
      ],
    );

MkSimpleStepFormBloc _stepForm() => MkSimpleStepFormBloc(
      controls: {
        'a': _slowField(),
        'b': MkFieldBloc<String>(initialValue: 'y')
      },
      steps: const [
        MkFormStep(controlNames: ['a']),
        MkFormStep(controlNames: ['b']),
        MkFormStep(controlNames: []),
      ],
      onSubmit: (v) async => null,
    );

void _closeRegressions() {
  group('closing while work is in flight', () {
    test('nextStep()', () async {
      final form = _stepForm();
      final pending = form.nextStep();
      await form.close();
      await expectLater(pending, completes);
    });

    test('goToStep() forward', () async {
      final form = _stepForm();
      final pending = form.goToStep(2);
      await form.close();
      await expectLater(pending, completes);
    });

    test('validateStep()', () async {
      final form = _stepForm();
      final pending = form.validateStep();
      await form.close();
      await expectLater(pending, completes);
    });

    test('loadInitialData()', () async {
      final form = _stepForm();
      final pending = form.loadInitialData(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return {'a': 'hello', 'b': 'there'};
      });
      await form.close();
      await expectLater(pending, completes);
    });

    test('loadInitialData() with an invalid earlier step', () async {
      final form = MkSimpleStepFormBloc(
        controls: {
          'a': MkFieldBloc<String>(validators: [MkValidators.required()]),
          'b': MkFieldBloc<String>(),
        },
        steps: const [
          MkFormStep(controlNames: ['a']),
          MkFormStep(controlNames: ['b']),
        ],
        onSubmit: (v) async => null,
      );
      final pending = form.loadInitialData(
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return {'b': 'x'};
        },
        resolveInitialStep: (_) => 1,
      );
      await form.close();
      await expectLater(pending, completes);
    });

    test('submit()', () async {
      final form = MkSimpleFormBloc(
        controls: {'a': _slowField()},
        onSubmit: (v) async => null,
      );
      final pending = form.submit();
      await form.close();
      await expectLater(pending, completes);
    });

    test('group.validate()', () async {
      final group = MkGroupBloc({'a': _slowField()});
      final pending = group.validate();
      await group.close();
      await expectLater(pending, completes);
    });

    test('array.validate()', () async {
      final array = MkArrayBloc<MkFieldBloc<String>>([_slowField()]);
      final pending = array.validate();
      await array.close();
      await expectLater(pending, completes);
    });
  });

  group('calling methods after close', () {
    test('form and step form reset()', () async {
      final form = _stepForm();
      await form.close();
      expect(form.reset, returnsNormally);

      final simple = MkSimpleFormBloc(
        controls: {'a': MkFieldBloc<String>()},
        onSubmit: (v) async => null,
      );
      await simple.close();
      expect(simple.reset, returnsNormally);
    });

    test('step navigation', () async {
      final form = _stepForm();
      await form.close();
      expect(form.previousStep, returnsNormally);
      await expectLater(form.nextStep(), completion(isFalse));
      await expectLater(form.goToStep(1), completion(isFalse));
    });

    test('group and array bulk operations', () async {
      final group = MkGroupBloc({'a': MkFieldBloc<String>()});
      await group.close();
      expect(group.touch, returnsNormally);
      expect(group.reset, returnsNormally);
      await expectLater(group.validate(), completes);

      final array = MkArrayBloc<MkFieldBloc<String>>([MkFieldBloc<String>()]);
      await array.close();
      expect(array.touch, returnsNormally);
      expect(array.reset, returnsNormally);
      await expectLater(array.validate(), completes);
    });
  });
}
