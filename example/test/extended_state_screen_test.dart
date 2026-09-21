import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms_example/presentation/features/extended_state/bloc/profile_form_bloc.dart';
import 'package:mk_forms_example/presentation/features/extended_state/extended_state_screen.dart';
import 'support/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;
  late ProfileFormBloc bloc;

  // Text fields in build order: display name, username, phone.
  final displayNameField = find.byType(TextField).at(0);
  final usernameField = find.byType(TextField).at(1);
  final phoneField = find.byType(TextField).at(2);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    repository = FakeProfileRepository();
    bloc = ProfileFormBloc(repository);
    await tester.pumpWidget(
      MaterialApp(home: ExtendedStateScreen(formBloc: bloc)),
    );
  }

  /// Lets bloc stream events reach the widgets without depending on timers.
  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
  }

  testWidgets('the username verdict disappears once the username is edited', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(usernameField, 'ada');
    await tester.tap(find.text('Check availability'));
    await flush(tester);
    expect(find.text('Available'), findsOneWidget);

    await tester.enterText(usernameField, 'ada2');
    await flush(tester);
    expect(find.text('Available'), findsNothing);
    expect(find.text('Taken'), findsNothing);
  });

  testWidgets('a taken username is reported as Taken', (tester) async {
    await pumpScreen(tester);
    repository.onIsUsernameAvailable = (_) async => false;

    await tester.enterText(usernameField, 'admin');
    await tester.tap(find.text('Check availability'));
    await flush(tester);

    expect(find.text('Taken'), findsOneWidget);
  });

  testWidgets('shows the number the code was sent to', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(phoneField, '555 0100');
    await tester.tap(find.text('Send code'));
    await flush(tester);

    expect(find.text('Code sent to 555 0100'), findsOneWidget);
  });

  testWidgets('shows the uploaded avatar URL from the state', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Upload avatar'));
    await flush(tester);

    expect(find.text('Uploaded: https://cdn.test/avatar.png'), findsOneWidget);
  });

  testWidgets('the save button follows the submit stage', (tester) async {
    await pumpScreen(tester);
    final availability = Completer<bool>();
    final save = Completer<Map<String, dynamic>>();
    repository.onIsUsernameAvailable = (_) => availability.future;
    repository.onSaveProfile = (_) => save.future;

    await tester.enterText(displayNameField, 'Ada');
    await tester.enterText(usernameField, 'ada');
    await tester.enterText(phoneField, '555');
    expect(find.text('Save profile'), findsOneWidget);

    await tester.tap(find.text('Save profile'));
    await flush(tester);
    expect(find.text('Checking username…'), findsOneWidget);

    availability.complete(true);
    await flush(tester);
    expect(find.text('Saving profile…'), findsOneWidget);

    save.complete({'id': 'p1'});
    await flush(tester);
    expect(find.text('Save profile'), findsOneWidget);
    expect(find.text('Saving profile…'), findsNothing);
  });
}
