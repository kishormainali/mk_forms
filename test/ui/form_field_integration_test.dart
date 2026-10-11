import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

Future<void> settle(WidgetTester t) async {
  await t.pump();
  await t.pump();
}

void main() {
  group('every Mk field is a FormField', () {
    testWidgets('widget types', (t) async {
      final text = MkFieldBloc<String>();
      final bools = MkFieldBloc<bool>();
      final list = MkFieldBloc<List<String>>();
      addTearDown(() async {
        await text.close();
        await bools.close();
        await list.close();
      });
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  MkTextField(fieldBloc: text),
                  MkEmailField(fieldBloc: text),
                  MkPasswordField(fieldBloc: text),
                  MkCheckboxField(fieldBloc: bools, title: const Text('c')),
                  MkRadioGroup<String>(
                    fieldBloc: text,
                    options: const [
                      MkRadioOption(value: 'a', label: Text('A')),
                    ],
                  ),
                  MkDropdownField<String>(
                    fieldBloc: text,
                    items: const [
                      DropdownMenuItem(value: 'a', child: Text('A')),
                    ],
                  ),
                  MkMultiSelectSearchDropdown<String>(
                    fieldBloc: list,
                    items: const ['a'],
                    itemToString: (s) => s,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.bySubtype<FormField<String>>(), findsNWidgets(5));
      expect(find.bySubtype<FormField<bool>>(), findsOneWidget);
      expect(find.bySubtype<FormField<List<String>>>(), findsOneWidget);
      // The dropdown must not nest a second FormField.
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });
  });

  group('inside a Form', () {
    late MkFieldBloc<String> name;
    late MkFieldBloc<bool> terms;
    late MkFieldBloc<String> country;
    final formKey = GlobalKey<FormState>();
    var changed = 0;
    final saved = <String, Object?>{};

    Future<void> pump(WidgetTester t, {AutovalidateMode? mode}) async {
      name = MkFieldBloc<String>(
        validators: [MkValidators.required()],
        initialValue: '',
      );
      terms = MkFieldBloc<bool>(validators: [MkValidators.required()]);
      country = MkFieldBloc<String>(validators: [MkValidators.required()]);
      changed = 0;
      saved.clear();
      addTearDown(() async {
        await name.close();
        await terms.close();
        await country.close();
      });
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              onChanged: () => changed++,
              child: Column(
                children: [
                  MkTextField(
                    fieldBloc: name,
                    onSaved: (v) => saved['name'] = v,
                  ),
                  MkCheckboxField(
                    fieldBloc: terms,
                    title: const Text('terms'),
                    onSaved: (v) => saved['terms'] = v,
                  ),
                  MkDropdownField<String>(
                    fieldBloc: country,
                    items: const [
                      DropdownMenuItem(value: 'np', child: Text('Nepal')),
                    ],
                    onSaved: (v) => saved['country'] = v,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Form.validate() reveals errors and reports validity', (
      t,
    ) async {
      await pump(t);
      expect(find.textContaining('required'), findsNothing); // pristine

      expect(formKey.currentState!.validate(), isFalse);
      await settle(t);

      expect(name.state.showError, isTrue);
      expect(terms.state.showError, isTrue);
      expect(find.textContaining('required'), findsWidgets);

      name.changeValue('kishor');
      terms.changeValue(true);
      country.changeValue('np');
      await settle(t);
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('Form.save() calls onSaved with the bloc values', (t) async {
      await pump(t);
      name.changeValue('kishor');
      terms.changeValue(true);
      country.changeValue('np');
      await settle(t);

      formKey.currentState!.save();

      expect(saved, {'name': 'kishor', 'terms': true, 'country': 'np'});
    });

    testWidgets('Form.reset() resets the blocs and the UI', (t) async {
      await pump(t);
      await t.enterText(find.byType(TextField), 'abc');
      await settle(t);
      expect(name.state.value, 'abc');
      expect(name.state.isDirty, isTrue);

      formKey.currentState!.reset();
      await settle(t);

      expect(name.state.value, '');
      expect(name.state.isDirty, isFalse);
      expect(
        (t.widget(find.byType(TextField)) as TextField).controller!.text,
        '',
      );
    });

    testWidgets('Form.onChanged fires for user edits', (t) async {
      await pump(t);
      await t.enterText(find.byType(TextField), 'a');
      await settle(t);
      expect(changed, greaterThan(0));

      final before = changed;
      await t.tap(find.byType(Checkbox));
      await settle(t);
      expect(terms.state.value, isTrue);
      expect(changed, greaterThan(before));
    });
  });

  testWidgets('forceErrorText is displayed and makes the field invalid', (
    t,
  ) async {
    final field = MkFieldBloc<String>(initialValue: 'ok');
    addTearDown(field.close);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MkTextField(fieldBloc: field, forceErrorText: 'Server says no'),
        ),
      ),
    );
    expect(find.text('Server says no'), findsOneWidget);
    final state = t.state<FormFieldState<String>>(find.byType(MkTextField));
    expect(state.hasError, isTrue);
    expect(state.isValid, isFalse);
  });

  testWidgets('FormFieldState reads the bloc, not a copy', (t) async {
    final field = MkFieldBloc<String>(
      initialValue: 'a',
      validators: [MkValidators.minLength(3)],
    );
    addTearDown(field.close);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MkTextField(fieldBloc: field)),
      ),
    );
    final state = t.state<FormFieldState<String>>(find.byType(MkTextField));

    expect(state.value, 'a');
    expect(state.hasError, isTrue); // bloc has an error...
    expect(state.errorText, isNull); // ...but it is not shown yet (pristine)

    field.changeValue('abcd');
    expect(state.value, 'abcd');
    expect(state.hasError, isFalse);
    expect(state.isValid, isTrue);

    state.didChange('x'); // goes through the bloc
    expect(field.state.value, 'x');
  });

  testWidgets('invisible and disabled fields', (t) async {
    final field = MkFieldBloc<String>(isVisible: false);
    addTearDown(field.close);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MkTextField(fieldBloc: field)),
      ),
    );
    expect(find.byType(TextField), findsNothing);

    field.setVisible(true);
    await settle(t);
    expect(find.byType(TextField), findsOneWidget);

    field.setEnabled(false);
    await settle(t);
    expect((t.widget(find.byType(TextField)) as TextField).enabled, isFalse);
  });

  testWidgets('switching the bound bloc rebinds the field', (t) async {
    final a = MkFieldBloc<String>(initialValue: 'one');
    final b = MkFieldBloc<String>(initialValue: 'two');
    addTearDown(() async {
      await a.close();
      await b.close();
    });
    Widget app(MkFieldBloc<String> bloc) => MaterialApp(
      home: Scaffold(body: MkTextField(fieldBloc: bloc)),
    );
    await t.pumpWidget(app(a));
    expect(find.text('one'), findsOneWidget);

    await t.pumpWidget(app(b));
    expect(find.text('two'), findsOneWidget);

    b.changeValue('three');
    await settle(t);
    expect(find.text('three'), findsOneWidget);
    a.changeValue('ignored');
    await settle(t);
    expect(find.text('three'), findsOneWidget);
  });
}
