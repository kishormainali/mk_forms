import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

const _short = Duration(milliseconds: 10);

Future<void> _settle([Duration d = const Duration(milliseconds: 60)]) =>
    Future<void>.delayed(d);

/// Field that records errors reported through [onError].
class _ErrorSpyField extends MkFieldBloc<String> {
  _ErrorSpyField({super.initialValue, super.asyncValidators})
      : super(debounceTime: Duration.zero);

  final List<Object> reported = [];

  @override
  void onError(Object error, StackTrace stackTrace) {
    reported.add(error);
    super.onError(error, stackTrace);
  }
}

void main() {
  group('dependsOn', () {
    test('does not run async validators at construction', () async {
      var runs = 0;
      final other = MkFieldBloc<String>(initialValue: 'a');
      final field = MkFieldBloc<String>(
        initialValue: 'z',
        dependsOn: [other],
        debounceTime: _short,
        asyncValidators: [
          (v) async {
            runs++;
            return null;
          },
        ],
      );
      await _settle();

      expect(runs, 0);
      expect(field.isValidating, isFalse);
      await field.close();
    });

    test('one dependency change runs async validators exactly once', () async {
      var runs = 0;
      final other = MkFieldBloc<String>(initialValue: 'a');
      final field = MkFieldBloc<String>(
        initialValue: 'z',
        dependsOn: [other],
        debounceTime: _short,
        asyncValidators: [
          (v) async {
            runs++;
            return null;
          },
        ],
      );

      other.changeValue('b');
      await _settle();

      expect(runs, 1);
      await field.close();
    });

    test('rapid dependency changes are debounced into a single async run',
        () async {
      var runs = 0;
      final other = MkFieldBloc<String>(initialValue: 'a');
      final field = MkFieldBloc<String>(
        initialValue: 'z',
        dependsOn: [other],
        debounceTime: const Duration(milliseconds: 30),
        asyncValidators: [
          (v) async {
            runs++;
            return null;
          },
        ],
      );

      for (final v in ['b', 'c', 'd', 'e']) {
        other.changeValue(v);
      }
      expect(field.isValidating, isTrue);
      await _settle(const Duration(milliseconds: 120));

      expect(runs, 1);
      expect(field.isValidating, isFalse);
      await field.close();
    });

    test('a dependency merely re-validating does not re-validate dependents',
        () async {
      var runs = 0;
      final other = MkFieldBloc<String>(initialValue: 'a');
      final field = MkFieldBloc<String>(
        initialValue: 'z',
        dependsOn: [other],
        debounceTime: _short,
        asyncValidators: [
          (v) async {
            runs++;
            return null;
          },
        ],
      );

      await other.validate();
      await other.validate();
      await _settle();

      expect(runs, 0);
      await field.close();
    });

    test('closing a dependent detaches it from its dependency', () async {
      final other = MkFieldBloc<String>(initialValue: 'a');
      final field = MkFieldBloc<String>(
        dependsOn: [other],
        validators: [MkValidators.required()],
      );
      await field.close();

      expect(() => other.changeValue('b'), returnsNormally);
    });
  });

  group('async validator failures', () {
    test('exception text is never shown to the user', () async {
      final field = _ErrorSpyField(
        initialValue: 'x',
        asyncValidators: [
          (v) async => throw Exception('SocketException: 10.0.0.5:443'),
        ],
      );

      await field.validate();

      expect(field.isValid, isFalse);
      expect(field.error, isNotNull);
      expect(field.error, isNot(contains('SocketException')));
      expect(field.state.errorCode, 'asyncValidationFailed');
      await field.close();
    });

    test('the failure is reported through onError', () async {
      final field = _ErrorSpyField(
        initialValue: 'x',
        asyncValidators: [(v) async => throw StateError('boom')],
      );

      await field.validate();

      expect(field.reported, hasLength(1));
      expect(field.reported.single, isA<StateError>());
      await field.close();
    });

    test('debounced validation after changeValue behaves the same', () async {
      final field = _ErrorSpyField(
        asyncValidators: [(v) async => throw StateError('boom')],
      );

      field.changeValue('abc');
      await _settle();

      expect(field.error, isNot(contains('boom')));
      expect(field.reported, hasLength(1));
      await field.close();
    });
  });

  group('isDirty with collection values', () {
    test('equal list contents are not dirty', () {
      final field = MkFieldBloc<List<String>>(initialValue: const ['a']);
      field.changeValue(['a']);
      expect(field.isDirty, isFalse);
    });

    test('different list contents are dirty, and revert to pristine', () {
      final field = MkFieldBloc<List<String>>(initialValue: const ['a']);
      field.changeValue(['a', 'b']);
      expect(field.isDirty, isTrue);
      field.changeValue(['a']);
      expect(field.isDirty, isFalse);
    });

    test('nested maps and sets compare structurally', () {
      final map = MkFieldBloc<Map<String, Object>>(initialValue: const {
        'k': [1, 2],
      });
      map.changeValue({
        'k': [1, 2],
      });
      expect(map.isDirty, isFalse);

      final set = MkFieldBloc<Set<int>>(initialValue: const {1, 2});
      set.changeValue({2, 1});
      expect(set.isDirty, isFalse);
    });

    test('scalars still work', () {
      final field = MkFieldBloc<String>(initialValue: 'a');
      field.changeValue('b');
      expect(field.isDirty, isTrue);
    });
  });

  group('changeValue(markTouched:)', () {
    test('changes value and touched state in one emission', () async {
      final field = MkFieldBloc<bool>(initialValue: false);
      final states = <MkFieldState<bool>>[];
      final sub = field.stream.listen(states.add);

      field.changeValue(true, markTouched: true);
      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(1));
      expect(states.single.value, isTrue);
      expect(states.single.isTouched, isTrue);
      await sub.cancel();
    });

    test('defaults to leaving touched untouched', () {
      final field = MkFieldBloc<bool>(initialValue: false);
      field.changeValue(true);
      expect(field.isTouched, isFalse);
    });
  });

  group('async failure message localization', () {
    test('English and Spanish messages resolve the error code', () {
      const en = MkDefaultEnglishMessages();
      const es = MkSpanishMessages();
      expect(en.resolve(MkErrorCodes.asyncValidationFailed),
          en.asyncValidationFailed());
      expect(es.resolve(MkErrorCodes.asyncValidationFailed),
          es.asyncValidationFailed());
      expect(en.asyncValidationFailed(), isNot(es.asyncValidationFailed()));
    });

    test('the field error is the current localized message', () async {
      final field = _ErrorSpyField(
        initialValue: 'x',
        asyncValidators: [(v) async => throw StateError('boom')],
      );
      await field.validate();
      expect(field.error, MkFormLocalizations.current.asyncValidationFailed());
      await field.close();
    });
  });

  group('state listeners', () {
    test('are not notified when an emit does not change the state', () {
      final field = MkFieldBloc<String>(initialValue: 'a');
      var notified = 0;
      field.addStateListener(() => notified++);

      field.setError('nope');
      field.setError('nope');
      field.setError('nope');

      expect(notified, 1);
    });
  });

  group('bulk operations emit once', () {
    MkGroupBloc buildGroup(int n) => MkGroupBloc({
          for (var i = 0; i < n; i++)
            'f$i': MkFieldBloc<String>(
              initialValue: '',
              validators: [MkValidators.required()],
            ),
        });

    test('group.touch() emits a single group state', () async {
      final group = buildGroup(50);
      var emissions = 0;
      final sub = group.stream.listen((_) => emissions++);

      group.touch();
      await Future<void>.delayed(Duration.zero);

      expect(emissions, 1);
      await sub.cancel();
      await group.close();
    });

    test('group.reset() and validate() emit at most once each', () async {
      final group = buildGroup(50);
      group.touch();
      var emissions = 0;
      final sub = group.stream.listen((_) => emissions++);

      group.reset();
      await Future<void>.delayed(Duration.zero);
      expect(emissions, lessThanOrEqualTo(1));

      emissions = 0;
      await group.validate();
      await Future<void>.delayed(Duration.zero);
      expect(emissions, lessThanOrEqualTo(1));
      await sub.cancel();
      await group.close();
    });

    test('array.touch() emits a single array state', () async {
      final array = MkArrayBloc<MkFieldBloc<String>>([
        for (var i = 0; i < 20; i++)
          MkFieldBloc<String>(validators: [MkValidators.required()]),
      ]);
      var emissions = 0;
      final sub = array.stream.listen((_) => emissions++);

      array.touch();
      await Future<void>.delayed(Duration.zero);

      expect(emissions, 1);
      await sub.cancel();
      await array.close();
    });

    test('submitting a 300-field form emits only a handful of form states',
        () async {
      final controls = {
        for (var i = 0; i < 300; i++)
          'f$i': MkFieldBloc<String>(initialValue: 'v'),
      };
      final form = MkSimpleFormBloc(controls: controls, onSubmit: (v) async {});
      var emissions = 0;
      final sub = form.stream.listen((_) => emissions++);

      await form.submit();
      await Future<void>.delayed(Duration.zero);

      expect(emissions, lessThanOrEqualTo(8));
      expect(form.state.isSuccess, isTrue);
      await sub.cancel();
      await form.close();
    });

    test('aggregated state stays correct after batched operations', () async {
      final a = MkFieldBloc<String>(validators: [MkValidators.required()]);
      final b = MkFieldBloc<String>(initialValue: 'ok');
      final group = MkGroupBloc({'a': a, 'b': b});

      group.touch();
      expect(group.state.isTouched, isTrue);
      expect(group.state.isValid, isFalse);

      a.changeValue('now valid');
      expect(group.state.isValid, isTrue);
      expect(group.state.isDirty, isTrue);
      expect(group.state.values, {'a': 'now valid', 'b': 'ok'});

      group.reset();
      expect(group.state.isTouched, isFalse);
      expect(group.state.isValid, isFalse);
      expect(group.state.values, {'a': null, 'b': 'ok'});
      await group.close();
    });

    test(
        'nested group values propagate to the root without recomputation '
        'drift', () async {
      final street = MkFieldBloc<String>(initialValue: 'Main');
      final form = MkSimpleFormBloc(
        controls: {
          'address': MkGroupBloc({'street': street}),
        },
        onSubmit: (v) async {},
      );

      street.changeValue('Second');

      expect(form.state.values, {
        'address': {'street': 'Second'},
      });
      expect(form.values, {
        'address': {'street': 'Second'},
      });
      await form.close();
    });
  });
}
