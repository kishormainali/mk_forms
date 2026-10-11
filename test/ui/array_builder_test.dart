import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('MkArrayBuilder', () {
    testWidgets('rebuilds on structure changes, not on row edits', (
      tester,
    ) async {
      final rows = [MkFieldBloc<String>(), MkFieldBloc<String>()];
      final array = MkArrayBloc<MkFieldBloc<String>>(rows);
      addTearDown(array.close);
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MkArrayBuilder<MkFieldBloc<String>>(
            arrayBloc: array,
            builder: (context, state, _) {
              builds++;
              return Text('rows: ${state.length}');
            },
          ),
        ),
      );
      expect(builds, 1);

      rows.first.changeValue('hello'); // values change, structure does not
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(builds, 1);

      array.add(MkFieldBloc<String>());
      await tester.pump();
      await tester.pump();
      expect(builds, 2);
      expect(find.text('rows: 3'), findsOneWidget);

      array.move(0, 2); // same length, different order
      await tester.pump();
      await tester.pump();
      expect(builds, 3);

      array.removeAt(0);
      await tester.pump();
      await tester.pump();
      expect(builds, 4);
      expect(find.text('rows: 2'), findsOneWidget);
    });

    testWidgets('custom buildWhen overrides the default', (tester) async {
      final row = MkFieldBloc<String>(validators: [MkValidators.required()]);
      final array = MkArrayBloc<MkFieldBloc<String>>([row]);
      addTearDown(array.close);
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MkArrayBuilder<MkFieldBloc<String>>(
            arrayBloc: array,
            buildWhen: (p, c) => p.isValid != c.isValid,
            builder: (context, state, _) {
              builds++;
              return Text('valid: ${state.isValid}');
            },
          ),
        ),
      );
      row.changeValue('x');
      await tester.pump();
      await tester.pump();
      expect(builds, 2);
      expect(find.text('valid: true'), findsOneWidget);
    });

    testWidgets('resolves the array by name from MkFormScope', (tester) async {
      final array = MkArrayBloc<MkFieldBloc<String>>([MkFieldBloc<String>()]);
      final form = MkSimpleFormBloc(
        controls: {'phones': array},
        onSubmit: (_) async => null,
      );
      addTearDown(form.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MkFormScope.value(
            value: form,
            child: MkArrayBuilder<MkFieldBloc<String>>(
              name: 'phones',
              builder: (context, state, _) => Text('rows: ${state.length}'),
            ),
          ),
        ),
      );
      expect(find.text('rows: 1'), findsOneWidget);
    });

    testWidgets('row edits update the row, the array and the form values', (
      tester,
    ) async {
      final array = MkArrayBloc<MkFieldBloc<String>>([
        MkFieldBloc<String>(),
        MkFieldBloc<String>(),
      ]);
      final form = MkSimpleFormBloc(
        controls: {'phones': array},
        onSubmit: (_) async => null,
      );
      addTearDown(form.close);
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkFormScope.value(
              value: form,
              child: MkArrayBuilder<MkFieldBloc<String>>(
                name: 'phones',
                builder: (context, state, _) {
                  builds++;
                  return Column(
                    children: [
                      for (final row in state.controls)
                        MkTextField(key: ObjectKey(row), fieldBloc: row),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Typing in a row updates that row's bloc, the array and the form...
      await tester.enterText(find.byType(TextField).first, '111');
      await tester.pump();
      await tester.pump();
      expect(array.controls.first.state.value, '111');
      expect(array.state.values, ['111', null]);
      expect(form.state.values['phones'], ['111', null]);
      // ...without rebuilding the list.
      expect(builds, 1);

      // Programmatic changes show up in the row's text field.
      array.controls[1].changeValue('222');
      await tester.pump();
      await tester.pump();
      expect(find.text('222'), findsOneWidget);
      expect(builds, 1);
    });

    testWidgets('rebuildOnValueChange rebuilds with the fresh values', (
      tester,
    ) async {
      final row = MkFieldBloc<String>();
      final array = MkArrayBloc<MkFieldBloc<String>>([row]);
      addTearDown(array.close);
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MkArrayBuilder<MkFieldBloc<String>>(
            arrayBloc: array,
            rebuildOnValueChange: true,
            builder: (context, state, _) {
              builds++;
              return Text('values: ${state.values}');
            },
          ),
        ),
      );
      expect(find.text('values: [null]'), findsOneWidget);

      row.changeValue('a');
      await tester.pump();
      await tester.pump();
      expect(builds, 2);
      expect(find.text('values: [a]'), findsOneWidget);

      row.touch(); // not a value change
      await tester.pump();
      await tester.pump();
      expect(builds, 2);
    });
  });
}
