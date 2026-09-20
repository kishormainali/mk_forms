import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

String shownText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  group('MkFieldBuilder & Form Widgets', () {
    testWidgets(
      'MkTextField synchronizes text input and touches field on focus lost',
      (tester) async {
        final field = MkFieldBloc<String>(
          validators: [MkValidators.required(), MkValidators.minLength(5)],
        );

        final otherFocusNode = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  MkTextField(
                    fieldBloc: field,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  TextField(
                    focusNode: otherFocusNode,
                    decoration: const InputDecoration(labelText: 'Other'),
                  ),
                ],
              ),
            ),
          ),
        );

        // Initially no error shown
        expect(find.text('This field is required'), findsNothing);

        // Enter text
        await tester.enterText(find.byType(TextField).first, 'abc');
        await tester.pump();

        expect(field.value, 'abc');
        expect(field.isDirty, isTrue);

        // Now change focus to other field to trigger blur
        otherFocusNode.requestFocus();
        await tester.pump();

        expect(field.isTouched, isTrue);
        // Now error is visible
        expect(find.text('Must be at least 5 characters'), findsOneWidget);
      },
    );

    testWidgets('MkFormScope provides form down the tree', (tester) async {
      final nameField = MkFieldBloc<String>(initialValue: 'Alice');
      final formBloc = MkSimpleFormBloc(
        controls: {'name': nameField},
        onSubmit: (values) async => true,
      );

      String? retrievedName;

      await tester.pumpWidget(
        MaterialApp(
          home: MkFormScope.value(
            value: formBloc,
            child: Builder(
              builder: (context) {
                final field = context.mkField<String>('name');
                retrievedName = field?.value;
                return Text(retrievedName ?? 'None');
              },
            ),
          ),
        ),
      );

      expect(retrievedName, 'Alice');
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('MkCheckboxField toggles boolean value', (tester) async {
      final termsField = MkFieldBloc<bool>(
        initialValue: false,
        validators: [MkValidators.required()],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkCheckboxField(
              fieldBloc: termsField,
              title: const Text('I agree to the terms'),
            ),
          ),
        ),
      );

      expect(termsField.value, isFalse);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      expect(termsField.value, isTrue);
      expect(termsField.isTouched, isTrue);
    });

    testWidgets('MkDropdownField selects item and updates field value', (
      tester,
    ) async {
      final roleField = MkFieldBloc<String>(initialValue: 'user');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkDropdownField<String>(
              fieldBloc: roleField,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Standard User')),
                DropdownMenuItem(value: 'admin', child: Text('Administrator')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Standard User'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Administrator').last);
      await tester.pumpAndSettle();

      expect(roleField.value, 'admin');
    });

    testWidgets('MkFormScope is backed by BlocProvider', (tester) async {
      final formBloc = MkSimpleFormBloc(
        controls: {'name': MkFieldBloc<String>()},
        onSubmit: (values) async => true,
      );

      MkFormBloc? viaBlocProvider;
      MkFormBloc? viaMaybeOf;
      MkFormBloc? outside;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              outside = MkFormScope.maybeOf(context);
              return MkFormScope.value(
                value: formBloc,
                child: Builder(
                  builder: (context) {
                    viaBlocProvider = BlocProvider.of<MkFormBloc>(context);
                    viaMaybeOf = MkFormScope.maybeOf(context);
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(viaBlocProvider, same(formBloc));
      expect(viaMaybeOf, same(formBloc));
      expect(outside, isNull);
    });

    testWidgets(
      'MkFormScope(create:) creates the bloc and closes it on dispose',
      (tester) async {
        var created = 0;
        late MkFormBloc formBloc;

        await tester.pumpWidget(
          MaterialApp(
            home: MkFormScope(
              create: (context) {
                created++;
                return MkSimpleFormBloc(
                  controls: {'name': MkFieldBloc<String>(initialValue: 'Bob')},
                  onSubmit: (values) async => true,
                );
              },
              child: Builder(
                builder: (context) {
                  formBloc = context.mkForm;
                  return Text(context.mkField<String>('name')!.value ?? '');
                },
              ),
            ),
          ),
        );

        expect(created, 1);
        expect(find.text('Bob'), findsOneWidget);
        expect(formBloc.isClosed, isFalse);

        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        expect(formBloc.isClosed, isTrue);
      },
    );

    testWidgets(
      'MkFormScope(create:) is lazy by default and honours lazy: false',
      (tester) async {
        var created = 0;
        MkFormBloc make(BuildContext _) {
          created++;
          return MkSimpleFormBloc(
            controls: {'name': MkFieldBloc<String>()},
            onSubmit: (values) async => true,
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            home: MkFormScope(create: make, child: const SizedBox()),
          ),
        );
        expect(created, 0);

        await tester.pumpWidget(
          MaterialApp(
            home: MkFormScope(
              key: const ValueKey('eager'),
              create: make,
              lazy: false,
              child: const SizedBox(),
            ),
          ),
        );
        expect(created, 1);
      },
    );

    testWidgets('MkFormScope.value does not close the supplied bloc', (
      tester,
    ) async {
      final formBloc = MkSimpleFormBloc(
        controls: {'name': MkFieldBloc<String>()},
        onSubmit: (values) async => true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MkFormScope.value(value: formBloc, child: const SizedBox()),
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(formBloc.isClosed, isFalse);
    });

    testWidgets('MkFormBuilder rebuilds on form state changes', (tester) async {
      final field = MkFieldBloc<String>(validators: [MkValidators.required()]);
      final form = MkSimpleFormBloc(
        controls: {'name': field},
        onSubmit: (values) async => true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MkFormScope.value(
            value: form,
            child: MkFormBuilder(
              builder: (context, state, bloc) =>
                  Text(state.isValid ? 'valid' : 'invalid'),
            ),
          ),
        ),
      );
      expect(find.text('invalid'), findsOneWidget);

      field.changeValue('Alice');
      await tester.pump();
      expect(find.text('valid'), findsOneWidget);
    });

    testWidgets('MkFormBuilder honours explicit formBloc and buildWhen', (
      tester,
    ) async {
      final field = MkFieldBloc<String>(validators: [MkValidators.required()]);
      final form = MkSimpleFormBloc(
        controls: {'name': field},
        onSubmit: (values) async => true,
      );
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MkFormBuilder(
            formBloc: form,
            buildWhen: (p, c) => p.isValid != c.isValid,
            builder: (context, state, bloc) {
              builds++;
              expect(bloc, same(form));
              return Text(state.isValid ? 'valid' : 'invalid');
            },
          ),
        ),
      );
      final initial = builds;

      field.changeValue('A');
      await tester.pump();
      expect(find.text('valid'), findsOneWidget);
      final afterValid = builds;
      expect(afterValid, greaterThan(initial));

      // isValid unchanged -> no rebuild
      field.changeValue('AB');
      await tester.pump();
      expect(builds, afterValid);
    });

    testWidgets('MkFormListener triggers callbacks on state transitions', (
      tester,
    ) async {
      bool submittingCalled = false;
      bool successCalled = false;

      final form = MkSimpleFormBloc(
        controls: {'val': MkFieldBloc<String>(initialValue: 'ok')},
        onSubmit: (values) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return 'done';
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MkFormListener(
            formBloc: form,
            onSubmitting: (context) {
              submittingCalled = true;
            },
            onSuccess: (context, response) {
              successCalled = true;
            },
            child: const Text('Form content'),
          ),
        ),
      );

      expect(find.text('Form content'), findsOneWidget);

      unawaited(form.submit());
      await tester.pump();

      expect(submittingCalled, isTrue);

      await tester.pump(const Duration(milliseconds: 50));
      expect(successCalled, isTrue);
    });

    testWidgets(
      'MkMultiSelectSearchDropdown shows every picked item as a chip',
      (tester) async {
        final field = MkFieldBloc<List<String>>(initialValue: const []);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MkMultiSelectSearchDropdown<String>(
                fieldBloc: field,
                items: const ['Apple', 'Banana', 'Cherry'],
                itemToString: (s) => s,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        for (final item in ['Apple', 'Banana', 'Cherry']) {
          await tester.tap(find.widgetWithText(CheckboxListTile, item));
          await tester.pump();
        }
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(field.value, ['Apple', 'Banana', 'Cherry']);
        for (final item in ['Apple', 'Banana', 'Cherry']) {
          expect(find.widgetWithText(InputChip, item), findsOneWidget);
        }
      },
    );

    testWidgets('MkTextField does not rebuild while typing when nothing '
        'visible changes', (tester) async {
      final field = MkFieldBloc<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MkTextField(fieldBloc: field)),
        ),
      );

      final before = tester.widget<TextField>(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      final after = tester.widget<TextField>(find.byType(TextField));

      expect(field.value, 'abc');
      expect(identical(before, after), isTrue);
    });

    testWidgets('MkTextField still rebuilds when the error changes', (
      tester,
    ) async {
      final field = MkFieldBloc<String>(
        validators: [MkValidators.required('Required')],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MkTextField(fieldBloc: field)),
        ),
      );
      field.touch();
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(find.text('Required'), findsNothing);
    });

    testWidgets('MkTextField reflects programmatic value changes', (
      tester,
    ) async {
      final field = MkFieldBloc<String>(initialValue: 'one');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MkTextField(fieldBloc: field)),
        ),
      );
      expect(shownText(tester), 'one');

      field.changeValue('two');
      await tester.pump();
      expect(shownText(tester), 'two');

      field.reset();
      await tester.pumpAndSettle();
      expect(shownText(tester), 'one');
    });

    testWidgets('MkCheckboxField emits a single state per tap', (tester) async {
      final field = MkFieldBloc<bool>(initialValue: false);
      var emissions = 0;
      final sub = field.stream.listen((_) => emissions++);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkCheckboxField(fieldBloc: field, title: const Text('T')),
          ),
        ),
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      expect(field.value, isTrue);
      expect(field.isTouched, isTrue);
      expect(emissions, 1);
    });

    testWidgets('MkRadioGroup emits a single state per selection', (
      tester,
    ) async {
      final field = MkFieldBloc<String>();
      var emissions = 0;
      final sub = field.stream.listen((_) => emissions++);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkRadioGroup<String>(
              fieldBloc: field,
              options: const [
                MkRadioOption(value: 'a', label: Text('Option A')),
                MkRadioOption(value: 'b', label: Text('Option B')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Option B'));
      await tester.pump();

      expect(field.value, 'b');
      expect(field.isTouched, isTrue);
      expect(emissions, 1);
    });

    testWidgets('MkDropdownField emits a single state per selection', (
      tester,
    ) async {
      final field = MkFieldBloc<String>(initialValue: 'user');
      var emissions = 0;
      final sub = field.stream.listen((_) => emissions++);
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkDropdownField<String>(
              fieldBloc: field,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Standard User')),
                DropdownMenuItem(value: 'admin', child: Text('Administrator')),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Administrator').last);
      await tester.pumpAndSettle();

      expect(field.value, 'admin');
      expect(field.isTouched, isTrue);
      expect(emissions, 1);
    });

    testWidgets('MkEmailField renders email input and triggers change', (
      tester,
    ) async {
      final email = MkFieldBloc<String>(
        validators: [MkValidators.required(), MkValidators.email()],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MkEmailField(fieldBloc: email)),
        ),
      );

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'user@test.com');
      await tester.pump();

      expect(email.value, 'user@test.com');
      expect(email.isValid, isTrue);
    });

    testWidgets(
      'MkPasswordField toggles obscureText when suffix icon is tapped',
      (tester) async {
        final password = MkFieldBloc<String>(
          validators: [MkValidators.required()],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MkPasswordField(fieldBloc: password)),
          ),
        );

        // Initially obscured, showing visibility icon
        final textFieldFinder = find.byType(TextField);
        TextField textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.obscureText, isTrue);
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

        // Tap toggle
        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pump();

        textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.obscureText, isFalse);
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      },
    );

    testWidgets('MkRadioGroup selects option and updates field', (
      tester,
    ) async {
      final gender = MkFieldBloc<String>(initialValue: 'male');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkRadioGroup<String>(
              fieldBloc: gender,
              options: const [
                MkRadioOption(value: 'male', label: Text('Male')),
                MkRadioOption(value: 'female', label: Text('Female')),
              ],
            ),
          ),
        ),
      );

      expect(gender.value, 'male');

      // Tap Female
      await tester.tap(find.text('Female'));
      await tester.pump();

      expect(gender.value, 'female');
    });

    testWidgets('MkMultiSelectSearchDropdown opens modal and selects items', (
      tester,
    ) async {
      final tagsField = MkFieldBloc<List<String>>(initialValue: ['Dart']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkMultiSelectSearchDropdown<String>(
              fieldBloc: tagsField,
              items: const ['Dart', 'Flutter', 'Bloc', 'GraphQL'],
              itemToString: (item) => item,
            ),
          ),
        ),
      );

      // Chip for 'Dart' is displayed
      expect(find.text('Dart'), findsOneWidget);

      // Tap to open modal
      await tester.tap(find.byType(InputDecorator));
      await tester.pumpAndSettle();

      // Modal is open
      expect(find.text('Select Options'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);

      // Tap Flutter checkbox
      await tester.tap(find.text('Flutter'));
      await tester.pumpAndSettle();

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(tagsField.value, containsAll(['Dart', 'Flutter']));
    });
  });
}
