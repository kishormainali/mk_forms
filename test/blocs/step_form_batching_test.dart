import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

class _Wizard extends MkStepFormBloc {
  _Wizard({int n = 6, int perStep = 2, bool slow = false})
    : super(
        controls: {
          for (var i = 0; i < n; i++)
            'f$i': MkFieldBloc<String>(
              validators: [MkValidators.required()],
              asyncValidators: slow
                  ? [
                      (v) async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 20),
                        );
                        return null;
                      },
                    ]
                  : const [],
              debounceTime: const Duration(milliseconds: 1),
            ),
        },
        steps: [
          for (var s = 0; s < n / perStep; s++)
            MkFormStep(
              controlNames: [
                for (var i = s * perStep; i < (s + 1) * perStep; i++) 'f$i',
              ],
              title: 's$s',
            ),
        ],
      );

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async => null;
}

void main() {
  group('bulk operations are batched', () {
    test('populateValues emits a single form state', () async {
      final form = _Wizard(n: 50);
      addTearDown(form.close);
      var emits = 0;
      final sub = form.stream.listen((_) => emits++);
      addTearDown(sub.cancel);

      form.populateValues({for (var i = 0; i < 50; i++) 'f$i': 'v$i'});
      await Future<void>.delayed(Duration.zero);

      expect(emits, 1);
      expect(form.state.isValid, isTrue);
      expect(form.state.isDirty, isFalse); // pristine
      expect(form.state.values['f49'], 'v49');
      expect(form.field<String>('f10')!.state.showError, isFalse);
    });

    test('populateValues batches nested group fields too', () async {
      final form = MkSimpleFormBloc(
        controls: {
          'a': MkGroupBloc({
            'x': MkFieldBloc<String>(validators: [MkValidators.required()]),
            'y': MkFieldBloc<String>(validators: [MkValidators.required()]),
          }),
        },
        onSubmit: (_) async => null,
      );
      addTearDown(form.close);
      var emits = 0;
      final sub = form.stream.listen((_) => emits++);
      addTearDown(sub.cancel);

      form.populateValues({
        'a': {'x': '1', 'y': '2'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(emits, 1);
      expect(form.state.values['a'], {'x': '1', 'y': '2'});
      expect(form.state.isValid, isTrue);
    });

    test('setFieldErrors emits once and shows every error', () async {
      final form = _Wizard(n: 4);
      addTearDown(form.close);
      form.populateValues({for (var i = 0; i < 4; i++) 'f$i': 'ok'});
      var emits = 0;
      final sub = form.stream.listen((_) => emits++);
      addTearDown(sub.cancel);

      form.setFieldErrors({'f0': 'taken', 'f1': 'bad'});
      await Future<void>.delayed(Duration.zero);

      expect(emits, 1);
      expect(form.field<String>('f0')!.state.error, 'taken');
      expect(form.field<String>('f1')!.state.error, 'bad');
      expect(form.field<String>('f0')!.state.isTouched, isTrue);
      expect(form.state.isValid, isFalse);
    });

    test('validateStep reveals only that step and emits once', () async {
      final form = _Wizard();
      addTearDown(form.close);
      var emits = 0;
      final sub = form.stream.listen((_) => emits++);
      addTearDown(sub.cancel);

      final ok = await form.validateStep(0);
      await Future<void>.delayed(Duration.zero);

      expect(ok, isFalse);
      expect(form.field<String>('f0')!.state.showError, isTrue);
      expect(form.field<String>('f2')!.state.showError, isFalse);
      // aggregate once + completedSteps update
      expect(emits, lessThanOrEqualTo(2));
    });
  });

  group('step navigation is serialized', () {
    Future<_Wizard> filled({bool slow = false}) async {
      final form = _Wizard(slow: slow);
      for (var i = 0; i < 6; i++) {
        form.field<String>('f$i')!.changeValue('x');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return form;
    }

    test('a double nextStep advances exactly one step', () async {
      final form = await filled(slow: true);
      addTearDown(form.close);

      final results = await Future.wait([form.nextStep(), form.nextStep()]);

      expect(form.currentStep, 1);
      expect(results, [true, false]); // second call ignored, no double push
    });

    test('nextStep works again after the first one completes', () async {
      final form = await filled();
      addTearDown(form.close);

      expect(await form.nextStep(), isTrue);
      expect(await form.nextStep(), isTrue);
      expect(form.currentStep, 2);
    });

    test('goToStep forward is ignored while navigating', () async {
      final form = await filled(slow: true);
      addTearDown(form.close);

      final results = await Future.wait([form.goToStep(2), form.nextStep()]);

      expect(form.currentStep, 2);
      expect(results, [true, false]);
    });

    test('a failed validation releases the navigation lock', () async {
      final form = _Wizard();
      addTearDown(form.close);

      expect(await form.nextStep(), isFalse);
      form.field<String>('f0')!.changeValue('a');
      form.field<String>('f1')!.changeValue('b');
      expect(await form.nextStep(), isTrue);
      expect(form.currentStep, 1);
    });
  });
}
