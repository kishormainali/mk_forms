import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms_example/core/di/injection.dart';
import 'package:mk_forms_example/core/router/app_router.dart';
import 'package:mk_forms_example/main.dart';
import 'package:mk_forms_example/presentation/features/dynamic_array/dynamic_todos_screen.dart';
import 'package:mk_forms_example/presentation/features/form_integration/form_integration_screen.dart';
import 'package:mk_forms_example/presentation/features/large_form/large_form_screen.dart';

void main() {
  setUpAll(configureDependencies);

  Widget homeApp() => MkFormsExampleApp(appRouter: AppRouter());

  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  testWidgets('Home lists the new examples', (tester) async {
    tallView(tester);
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Large Form Performance'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Flutter Form Integration'), findsOneWidget);
    expect(find.text('Large Form Performance'), findsOneWidget);
  });

  group('Flutter Form Integration', () {
    testWidgets('validate(), save(), forceErrorText and reset()', (
      tester,
    ) async {
      tallView(tester);
      await tester.pumpWidget(const MaterialApp(home: FormIntegrationScreen()));

      // Pristine: no errors yet.
      expect(find.textContaining('required'), findsNothing);

      // Submit runs Form.validate(), which reveals every error.
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(find.textContaining('required'), findsWidgets);
      expect(find.text('Accept the terms to continue'), findsOneWidget);

      // Fill the form with an email the "server" rejects.
      await tester.enterText(find.byType(TextField).first, 'taken@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Developer').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      // save() ran, then the screen set forceErrorText.
      expect(find.text('This email is already registered'), findsOneWidget);

      // A different email passes and shows the saved values.
      await tester.enterText(find.byType(TextField).first, 'me@example.com');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Saved:'), findsOneWidget);

      // Reset() clears the fields.
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('me@example.com'), findsNothing);
    });
  });

  group('Large Form', () {
    testWidgets('Save is gated by canSubmit and succeeds when valid', (
      tester,
    ) async {
      tallView(tester);
      await tester.pumpWidget(const MaterialApp(home: LargeFormScreen()));

      TextButton save() =>
          tester.widget<TextButton>(find.widgetWithText(TextButton, 'Save'));
      expect(save().onPressed, isNull); // 200+ required fields are empty

      await tester.tap(find.text('Fill all'));
      await tester.pumpAndSettle();
      expect(save().onPressed, isNull); // phone is still empty

      await tester.enterText(find.byType(TextField).last, '9800000000');
      await tester.pumpAndSettle();
      expect(save().onPressed, isNotNull);

      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('Saved 200 fields'), findsOneWidget);
    });
  });

  testWidgets('Dynamic array: typing in a task keeps its text', (tester) async {
    tallView(tester);
    await tester.pumpWidget(homeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dynamic Array Forms'));
    await tester.pumpAndSettle();
    expect(find.byType(DynamicTodosScreen), findsOneWidget);

    final field = find.byType(TextField).first;
    await tester.enterText(field, 'Write docs');
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Write docs'), findsOneWidget);
  });
}
