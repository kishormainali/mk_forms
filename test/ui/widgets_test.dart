import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('MkFieldBuilder & Form Widgets', () {
    testWidgets('MkTextField synchronizes text input and touches field on focus lost', (tester) async {
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
    });

    testWidgets('MkFormScope provides form down the tree', (tester) async {
      final nameField = MkFieldBloc<String>(initialValue: 'Alice');
      final formBloc = MkSimpleFormBloc(
        controls: {'name': nameField},
        onSubmit: (values) async => true,
      );

      String? retrievedName;

      await tester.pumpWidget(
        MaterialApp(
          home: MkFormScope(
            formBloc: formBloc,
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

    testWidgets('MkDropdownField selects item and updates field value', (tester) async {
      final roleField = MkFieldBloc<String>(
        initialValue: 'user',
      );

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

    testWidgets('MkFormListener triggers callbacks on state transitions', (tester) async {
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

    testWidgets('MkEmailField renders email input and triggers change', (tester) async {
      final email = MkFieldBloc<String>(
        validators: [MkValidators.required(), MkValidators.email()],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkEmailField(fieldBloc: email),
          ),
        ),
      );

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'user@test.com');
      await tester.pump();

      expect(email.value, 'user@test.com');
      expect(email.isValid, isTrue);
    });

    testWidgets('MkPasswordField toggles obscureText when suffix icon is tapped', (tester) async {
      final password = MkFieldBloc<String>(
        validators: [MkValidators.required()],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkPasswordField(fieldBloc: password),
          ),
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
    });

    testWidgets('MkRadioGroup selects option and updates field', (tester) async {
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

    testWidgets('MkMultiSelectSearchDropdown opens modal and selects items', (tester) async {
      final tagsField = MkFieldBloc<List<String>>(
        initialValue: ['Dart'],
      );

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
