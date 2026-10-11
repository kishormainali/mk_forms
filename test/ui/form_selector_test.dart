import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('MkFormSelector', () {
    testWidgets(
      'does not rebuild on keystrokes that leave the selection alone',
      (tester) async {
        final form = MkSimpleFormBloc(
          controls: {
            'name': MkFieldBloc<String>(validators: [MkValidators.required()]),
          },
          onSubmit: (_) async => null,
        );
        addTearDown(form.close);
        var builds = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: MkFormScope.value(
              value: form,
              child: MkFormSelector<bool>(
                selector: (s) => s.isValid,
                builder: (context, isValid, _) {
                  builds++;
                  return Text('valid: $isValid');
                },
              ),
            ),
          ),
        );
        expect(builds, 1);

        form.field<String>('name')!.changeValue('a'); // invalid -> valid
        await tester.pump();
        await tester.pump();
        expect(builds, 2);
        expect(find.text('valid: true'), findsOneWidget);

        form.field<String>('name')!.changeValue('ab'); // values change only
        form.field<String>('name')!.changeValue('abc');
        await tester.pump();
        await tester.pump();
        expect(builds, 2);
      },
    );
  });

  group('MkFieldState equality', () {
    MkFieldState<List<String>> state({List<String> v = const ['a']}) =>
        MkFieldState<List<String>>(
          value: v,
          initialValue: const [],
          isDirty: true,
          isTouched: false,
          isValidating: false,
          isEnabled: true,
          isVisible: true,
          isReadOnly: false,
          wasFormSubmitted: false,
          errorParams: const {'min': 3},
        );

    test('compares collections structurally and hashes consistently', () {
      final a = state(v: ['a', 'b']);
      final b = state(v: ['a', 'b']);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(state(v: ['a'])));
    });

    test('every field participates in equality', () {
      final base = state();
      expect(base.copyWith(error: () => 'x'), isNot(base));
      expect(base.copyWith(errorCode: () => 'x'), isNot(base));
      expect(base.copyWith(isTouched: true), isNot(base));
      expect(base.copyWith(isValidating: true), isNot(base));
      expect(base.copyWith(isEnabled: false), isNot(base));
      expect(base.copyWith(isVisible: false), isNot(base));
      expect(base.copyWith(isReadOnly: true), isNot(base));
      expect(base.copyWith(wasFormSubmitted: true), isNot(base));
      expect(base.copyWith(label: 'L'), isNot(base));
      expect(base.copyWith(errorParams: () => {'min': 4}), isNot(base));
      expect(base.copyWith(initialValue: () => ['z']), isNot(base));
      expect(base.copyWith(), base);
    });
  });
}
