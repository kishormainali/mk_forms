import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('MkFieldSelector', () {
    testWidgets(
      'rebuilds only when the selected value changes, not on every field '
      'state change',
      (tester) async {
        final field = MkFieldBloc<String>(
          initialValue: 'abcdef',
          validators: [MkValidators.minLength(5)],
        );
        addTearDown(field.close);
        var builds = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: MkFieldSelector<String, String?>(
              fieldBloc: field,
              selector: (state) => state.error,
              builder: (context, selected, fieldBloc) {
                builds++;
                return Text(selected ?? 'no error');
              },
            ),
          ),
        );

        expect(builds, 1);
        expect(find.text('no error'), findsOneWidget);

        // isTouched changes, error stays null: must NOT rebuild.
        field.touch();
        // Bloc stream delivery takes a microtask hop.
        await tester.pump();
        // Allow state emission to propagate to widgets.
        await tester.pump();
        expect(field.isTouched, isTrue);
        expect(builds, 1);

        // Value becomes invalid: error appears, must rebuild.
        field.changeValue('a');
        await tester.pump();
        await tester.pump();
        expect(builds, 2);
        expect(find.text('Must be at least 5 characters'), findsOneWidget);

        // Still invalid with the same error message: must NOT rebuild.
        field.changeValue('bb');
        await tester.pump();
        await tester.pump();
        expect(field.value, 'bb');
        expect(builds, 2);

        // Value becomes valid again: error clears, must rebuild.
        field.changeValue('abcdef');
        await tester.pump();
        await tester.pump();
        expect(builds, 3);
        expect(find.text('no error'), findsOneWidget);
      },
    );

    testWidgets('resolves the field by name via the nearest MkFormScope', (
      tester,
    ) async {
      final formBloc = MkSimpleFormBloc(
        controls: {'name': MkFieldBloc<String>(initialValue: 'Alice')},
        onSubmit: (values) async => null,
      );
      addTearDown(formBloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: MkFormScope.value(
            value: formBloc,
            child: MkFieldSelector<String, String?>(
              name: 'name',
              selector: (state) => state.value,
              builder: (context, selected, fieldBloc) => Text(selected ?? ''),
            ),
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets(
      'hideWhenInvisible hides the widget regardless of the selected value',
      (tester) async {
        final field = MkFieldBloc<String>(initialValue: 'a');
        addTearDown(field.close);

        await tester.pumpWidget(
          MaterialApp(
            home: MkFieldSelector<String, String?>(
              fieldBloc: field,
              selector: (state) => state.value,
              builder: (context, selected, fieldBloc) => Text(selected ?? ''),
            ),
          ),
        );

        expect(find.text('a'), findsOneWidget);

        field.setVisible(false);
        await tester.pump();
        await tester.pump();

        expect(find.text('a'), findsNothing);
        expect(find.byType(SizedBox), findsOneWidget);
      },
    );

    testWidgets(
      'the builder can use fieldBloc to act on the field (e.g. reset)',
      (tester) async {
        final field = MkFieldBloc<String>(initialValue: 'a');
        addTearDown(field.close);

        await tester.pumpWidget(
          MaterialApp(
            home: MkFieldSelector<String, String?>(
              fieldBloc: field,
              selector: (state) => state.value,
              builder: (context, selected, fieldBloc) => TextButton(
                onPressed: fieldBloc.reset,
                child: Text(selected ?? ''),
              ),
            ),
          ),
        );

        field.changeValue('b');
        await tester.pump();
        await tester.pump();
        expect(find.text('b'), findsOneWidget);

        await tester.tap(find.byType(TextButton));
        await tester.pump();
        await tester.pump();

        expect(field.value, 'a');
        expect(find.text('a'), findsOneWidget);
      },
    );
  });
}
