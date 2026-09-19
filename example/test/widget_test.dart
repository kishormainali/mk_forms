import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms_example/core/di/injection.dart';
import 'package:mk_forms_example/core/router/app_router.dart';
import 'package:mk_forms_example/main.dart';
import 'package:mk_forms_example/presentation/features/all_fields_showcase/all_fields_screen.dart';
import 'package:mk_forms_example/presentation/features/async_validation/username_screen.dart';
import 'package:mk_forms_example/presentation/features/autovalidate_demo/autovalidate_screen.dart';
import 'package:mk_forms_example/presentation/features/custom_design_system/custom_design_screen.dart';
import 'package:mk_forms_example/presentation/features/dependent_fields/registration_screen.dart';
import 'package:mk_forms_example/presentation/features/dynamic_array/dynamic_todos_screen.dart';
import 'package:mk_forms_example/presentation/features/i18n_demo/i18n_screen.dart';
import 'package:mk_forms_example/presentation/features/minimal_login/minimal_login_screen.dart';
import 'package:mk_forms_example/presentation/features/onboarding_flow/routes/account_step_route.dart';
import 'package:mk_forms_example/presentation/features/onboarding_flow/routes/profile_step_route.dart';
import 'package:mk_forms_example/presentation/features/subforms_checkout/checkout_screen.dart';
import 'package:mk_forms_example/presentation/screens/home_screen.dart';

void main() {
  setUpAll(() {
    configureDependencies();
  });

  Widget createTestApp() => MkFormsExampleApp(appRouter: AppRouter());

  testWidgets('App boots into HomeScreen with all feature cards',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('mk_forms Examples'), findsOneWidget);
    expect(find.text('Minimal Login Form'), findsOneWidget);
    expect(find.text('Multi-Route Onboarding Wizard'), findsOneWidget);
    expect(find.text('Independent Subforms (Checkout)'), findsOneWidget);
    expect(find.text('Cross-Field Dependent Validation'), findsOneWidget);
    expect(find.text('Debounced Async Validation'), findsOneWidget);
    expect(find.text('Dynamic Array Forms'), findsOneWidget);
    expect(find.text('All Fields Showcase'), findsOneWidget);
    expect(find.text('Internationalization (i18n)'), findsOneWidget);
    expect(find.text('Custom Design System'), findsOneWidget);
    expect(find.text('Autovalidate Modes'), findsOneWidget);
  });

  testWidgets('Navigates into MinimalLoginScreen and validates input',
      (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Minimal Login Form'));
    await tester.pumpAndSettle();

    expect(find.byType(MinimalLoginScreen), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    // Form starts pristine (no error message visible before interaction)
    expect(find.text('Email is required'), findsNothing);

    // Tap submit button to trigger touched & submitted validation
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Now error messages are displayed
    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets(
      'Multi-Route Onboarding Wizard navigates across steps and loads draft',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Multi-Route Onboarding Wizard'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountStepScreen), findsOneWidget);
    expect(find.text('Onboarding: Step 1 / 3'), findsOneWidget);

    // Tap Load API Draft
    await tester.tap(find.text('Load API Draft'));
    await tester.pumpAndSettle();

    // Automatically jumped to Step 2 (Profile) route because draft step is 1
    expect(find.byType(ProfileStepScreen), findsOneWidget);
    expect(find.text('Onboarding: Step 2 / 3'), findsOneWidget);

    // Navigate back to Step 1
    await tester.tap(find.text('← Back to Step 1'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountStepScreen), findsOneWidget);
    // Value from draft is preserved!
    expect(find.text('john_developer'), findsOneWidget);
  });

  testWidgets(
      'Multi-Route Onboarding Wizard redirects to step with validation issue on API draft load and highlights errors',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Multi-Route Onboarding Wizard'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountStepScreen), findsOneWidget);

    // Open popup menu and tap 'Load Invalid Draft'
    await tester.tap(find.byTooltip('Load Draft from API'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Load Invalid Draft (Redirects to Step 1)'));
    await tester.pumpAndSettle();

    // Must stay on Step 1 (AccountStepScreen) instead of pushing Step 2
    expect(find.byType(AccountStepScreen), findsOneWidget);
    expect(find.byType(ProfileStepScreen), findsNothing);

    // Shows redirection snackbar warning
    expect(
        find.textContaining(
            'Draft requested Step 2, but Step 1 has validation errors'),
        findsOneWidget);

    // Step 1 invalid fields show error messages immediately
    expect(find.text('Must be at least 3 characters'), findsOneWidget);
    expect(find.text('Please enter a valid email'), findsOneWidget);

    // Step 2 values from the draft are fully preserved in the form state
    // Let's verify by fixing Step 1 and proceeding to Step 2
    await tester.enterText(
        find.widgetWithText(TextField, 'ab'), 'jane_developer');
    await tester.enterText(
        find.widgetWithText(TextField, 'invalid-email-address'),
        'jane@example.com');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue to Profile →'));
    await tester.pumpAndSettle();

    // Now in Step 2: verify data loaded from draft ('Jane Incomplete', 'designer', bio) was preserved!
    expect(find.byType(ProfileStepScreen), findsOneWidget);
    expect(find.text('Jane Incomplete'), findsOneWidget);
    expect(find.text('Designer with invalid account draft'), findsOneWidget);
  });

  testWidgets('Independent Subforms Checkout isolates group validation',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Independent Subforms (Checkout)'));
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutScreen), findsOneWidget);

    // Initially pristine
    expect(find.text('Shipping street is required'), findsNothing);
    expect(find.text('Billing street is required'), findsNothing);

    // Validate only shipping subform
    await tester.tap(find.text('Validate Shipping Subform Only'));
    await tester.pumpAndSettle();

    // Shipping error shown
    expect(find.text('Shipping street is required'), findsOneWidget);

    // Billing subform MUST NOT show error!
    expect(find.text('Billing street is required'), findsNothing);

    // Fill in shipping
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '123 Main St');
    await tester.enterText(textFields.at(1), 'San Francisco');
    await tester.enterText(textFields.at(2), 'CA');
    await tester.enterText(textFields.at(3), '94105');

    // Fill in billing
    await tester.enterText(textFields.at(4), '456 Elm St');
    await tester.enterText(textFields.at(5), 'Oakland');
    await tester.enterText(textFields.at(6), 'CA');
    await tester.enterText(textFields.at(7), '94607');
    await tester.pumpAndSettle();

    // Submit checkout
    await tester.tap(find.text('Complete Checkout (All Subforms)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Order placed! ID: ORD-'), findsOneWidget);
  });

  testWidgets('Navigates into RegistrationScreen (dependent fields)',
      (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cross-Field Dependent Validation'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationScreen), findsOneWidget);
  });

  testWidgets('Navigates into UsernameScreen (async validation)',
      (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Debounced Async Validation'));
    await tester.pumpAndSettle();

    expect(find.byType(UsernameScreen), findsOneWidget);
  });

  testWidgets('Navigates into DynamicTodosScreen (dynamic array)',
      (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dynamic Array Forms'));
    await tester.pumpAndSettle();

    expect(find.byType(DynamicTodosScreen), findsOneWidget);
  });

  testWidgets('Navigates into AllFieldsScreen (showcase)', (tester) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('All Fields Showcase'));
    await tester.pumpAndSettle();

    expect(find.byType(AllFieldsScreen), findsOneWidget);
  });

  testWidgets('Navigates into I18nDemoScreen and toggles locale',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Internationalization (i18n)'));
    await tester.pumpAndSettle();

    expect(find.byType(I18nDemoScreen), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Toggle locale to Spanish
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Español'), findsOneWidget);
    expect(find.text('Validar y Enviar'), findsOneWidget);
  });

  testWidgets('Navigates into CustomDesignScreen (custom cards & chips)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Custom Design System'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomDesignScreen), findsOneWidget);
  });

  testWidgets('Navigates into AutovalidateScreen and interacts with modes',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Autovalidate Modes'));
    await tester.pumpAndSettle();

    expect(find.byType(AutovalidateScreen), findsOneWidget);
    // Initially on onUserInteraction -> pristine fields show no error
    expect(find.text('Username is required'), findsNothing);

    // Switch to 'always' mode
    await tester.tap(find.text('always'));
    await tester.pumpAndSettle();

    // In 'always' mode, pristine fields immediately show error
    expect(find.text('Username is required'), findsOneWidget);

    // Tap Autofill
    await tester.tap(find.text('Autofill'));
    await tester.pumpAndSettle();

    // Now valid -> error disappears
    expect(find.text('Username is required'), findsNothing);
  });
}
