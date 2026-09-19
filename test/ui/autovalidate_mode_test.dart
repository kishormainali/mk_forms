import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('AutovalidateMode Widget Integration', () {
    testWidgets('AutovalidateMode.always displays error immediately on pristine load', (tester) async {
      final nameField = MkFieldBloc<String>(
        validators: [MkValidators.required('Username is required')],
      );
      final formBloc = MkSimpleFormBloc(
        controls: {'username': nameField},
        onSubmit: (v) async => true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkFormScope(
              formBloc: formBloc,
              autovalidateMode: AutovalidateMode.always,
              child: const MkTextField(name: 'username'),
            ),
          ),
        ),
      );

      // Error must be visible immediately without any touch/focus interaction
      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('AutovalidateMode.onUserInteraction hides error until touched', (tester) async {
      final nameField = MkFieldBloc<String>(
        validators: [MkValidators.required('Username is required')],
      );
      final formBloc = MkSimpleFormBloc(
        controls: {'username': nameField},
        onSubmit: (v) async => true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkFormScope(
              formBloc: formBloc,
              child: const MkTextField(name: 'username'),
            ),
          ),
        ),
      );

      // Initially pristine -> no error
      expect(find.text('Username is required'), findsNothing);

      // Touch field
      nameField.touch();
      await tester.pump();

      // Now error should be visible
      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('AutovalidateMode.disabled hides error even after touch until form submission', (tester) async {
      final nameField = MkFieldBloc<String>(
        validators: [MkValidators.required('Username is required')],
      );
      final formBloc = MkSimpleFormBloc(
        controls: {'username': nameField},
        onSubmit: (v) async => true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkFormScope(
              formBloc: formBloc,
              autovalidateMode: AutovalidateMode.disabled,
              child: const MkTextField(name: 'username'),
            ),
          ),
        ),
      );

      // Initially pristine -> no error
      expect(find.text('Username is required'), findsNothing);

      // Touch field -> still no error in disabled mode
      nameField.touch();
      await tester.pump();
      expect(find.text('Username is required'), findsNothing);

      // Attempt form submission -> error finally appears
      await formBloc.submit();
      await tester.pumpAndSettle();
      expect(find.text('Username is required'), findsOneWidget);
    });

    testWidgets('Widget-level autovalidateMode overrides MkFormScope', (tester) async {
      final emailField = MkFieldBloc<String>(
        validators: [MkValidators.required('Email is required')],
      );
      final formBloc = MkSimpleFormBloc(
        controls: {'email': emailField},
        onSubmit: (v) async => true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkFormScope(
              formBloc: formBloc,
              // Form scope is disabled:
              autovalidateMode: AutovalidateMode.disabled,
              // But widget explicitly requests always:
              child: const MkTextField(
                name: 'email',
                autovalidateMode: AutovalidateMode.always,
              ),
            ),
          ),
        ),
      );

      // Error is immediately visible due to widget override
      expect(find.text('Email is required'), findsOneWidget);
    });
  });
}
