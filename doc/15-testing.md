# 15. Testing

Blocs are plain Cubits, so most tests need no widgets. Add `bloc_test` and `flutter_test` to `dev_dependencies`.

Tips:

- Always `close()` form blocs in `tearDown`.
- Pristine fields hide errors: assert on `state.error` for validity, `state.showError` for visibility.
- Async validators are debounced — use `fakeAsync` or `await Future.delayed(debounce + margin)` before asserting.

## Full example — field, form, async validator, widget test

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

class LoginFormBloc extends MkFormBloc {
  LoginFormBloc()
      : super(controls: {
          'email': MkFieldBloc<String>(
            validators: [MkValidators.required(), MkValidators.email()],
          ),
          'password': MkFieldBloc<String>(
            validators: [MkValidators.required(), MkValidators.minLength(6)],
          ),
        });

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async => 'token';
}

void main() {
  group('MkFieldBloc', () {
    test('error is hidden until touched', () {
      final field = MkFieldBloc<String>(validators: [MkValidators.required()]);
      addTearDown(field.close);

      expect(field.state.showError, isFalse); // pristine
      field.touch();
      expect(field.state.showError, isTrue);
      expect(field.state.error, isNotNull);

      field.changeValue('hello');
      expect(field.state.error, isNull);
    });

    test('dependsOn revalidates confirm when password changes', () {
      final password = MkFieldBloc<String>(initialValue: 'abc');
      final confirm = MkFieldBloc<String>(
        initialValue: 'abc',
        validators: [MkValidators.matchControl(password, 'mismatch')],
        dependsOn: [password],
      );
      addTearDown(() {
        password.close();
        confirm.close();
      });

      password.changeValue('xyz');
      expect(confirm.state.error, 'mismatch');
    });

    test('async validator reports taken names', () async {
      final username = MkFieldBloc<String>(
        asyncValidators: [(v) async => v == 'admin' ? 'Taken' : null],
        debounceTime: const Duration(milliseconds: 10),
      );
      addTearDown(username.close);

      username.changeValue('admin');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(username.state.error, 'Taken');
      expect(username.state.isValidating, isFalse);
    });

    test('read-only fields never block validity', () {
      final field = MkFieldBloc<String>(
        isReadOnly: true,
        validators: [MkValidators.required()],
      );
      addTearDown(field.close);
      expect(field.state.isValid, isTrue);
    });
  });

  group('LoginFormBloc', () {
    late LoginFormBloc sut;
    setUp(() => sut = LoginFormBloc());
    tearDown(() => sut.close());

    test('is initially invalid', () => expect(sut.state.isValid, isFalse));

    test('becomes valid with valid input', () {
      sut.field<String>('email')!.changeValue('test@example.com');
      sut.field<String>('password')!.changeValue('password123');
      expect(sut.state.isValid, isTrue);
    });

    test('submit with invalid data does not call onSubmit', () async {
      await sut.submit();
      expect(sut.state.isSuccess, isFalse);
      expect(sut.field<String>('email')!.state.showError, isTrue);
    });

    blocTest<LoginFormBloc, MkFormState>(
      'emits submitting then success',
      build: LoginFormBloc.new,
      act: (bloc) async {
        bloc.field<String>('email')!.changeValue('test@example.com');
        bloc.field<String>('password')!.changeValue('validpass');
        await bloc.submit();
      },
      verify: (bloc) => expect(bloc.state.isSuccess, isTrue),
    );
  });

  testWidgets('MkTextField shows the error after submit', (tester) async {
    final form = LoginFormBloc();
    addTearDown(form.close);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MkFormScope.value(
          value: form,
          child: Column(children: [
            const MkEmailField(name: 'email'),
            ElevatedButton(onPressed: form.submit, child: const Text('Go')),
          ]),
        ),
      ),
    ));

    expect(find.textContaining('required'), findsNothing); // pristine

    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();

    expect(find.textContaining('required'), findsOneWidget);
  });
}
```

Run:

```bash
flutter test
flutter test --coverage
flutter analyze
```

Next: [Performance](16-performance.md).
