import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

Future<void> type(
  WidgetTester t,
  String text, {
  bool pumpBetween = true,
}) async {
  var acc = (t.state(find.byType(EditableText).first) as EditableTextState)
      .textEditingValue
      .text;
  for (final ch in text.split('')) {
    acc += ch;
    t.testTextInput.updateEditingValue(
      TextEditingValue(
        text: acc,
        selection: TextSelection.collapsed(offset: acc.length),
      ),
    );
    if (pumpBetween) await t.pump();
  }
  await t.pump();
  await t.pump();
}

void main() {
  // Regression: MkTextField skips rebuilds for value-only changes, which left
  // BlocBuilder's cached state a keystroke behind; any parent rebuild then
  // wrote the stale value back into the controller (typed text reverted).
  testWidgets('typed text survives a parent that rebuilds on every keystroke', (
    t,
  ) async {
    final form = MkSimpleFormBloc(
      controls: {
        'name': MkFieldBloc<String>(validators: [MkValidators.required()]),
      },
      onSubmit: (_) async => null,
    );
    addTearDown(form.close);

    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MkFormScope.value(
            value: form,
            child: Column(
              children: [
                const MkTextField(name: 'name'),
                // No buildWhen: rebuilds each keystroke, like a naive parent.
                MkFormBuilder(builder: (c, s, f) => Text('${s.values}')),
                MkFormBuilder(
                  builder: (c, s, f) => KeyedSubtree(
                    key: ValueKey(s.values.toString()),
                    child: const SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await t.tap(find.byType(TextField));
    await t.pump();
    await type(t, 'hello');
    expect(
      (t.widget(find.byType(TextField)) as TextField).controller!.text,
      'hello',
    );
    expect(form.field<String>('name')!.state.value, 'hello');
  });

  for (final variant in ['blocBuilder', 'mkArrayBuilder']) {
    for (final pumpBetween in [true, false]) {
      testWidgets('$variant pumpBetween=$pumpBetween', (t) async {
        final array = MkArrayBloc<MkFieldBloc<String>>([
          MkFieldBloc<String>(validators: [MkValidators.required()]),
          MkFieldBloc<String>(validators: [MkValidators.required()]),
        ]);
        final form = MkSimpleFormBloc(
          controls: {'p': array},
          onSubmit: (_) async => null,
        );
        addTearDown(form.close);

        Widget rows(MkArrayState<MkFieldBloc<String>> s) => Column(
          children: [
            for (final r in s.controls)
              MkTextField(key: ObjectKey(r), fieldBloc: r),
          ],
        );

        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MkFormScope.value(
                value: form,
                child: variant == 'blocBuilder'
                    ? BlocBuilder<
                        MkArrayBloc<MkFieldBloc<String>>,
                        MkArrayState<MkFieldBloc<String>>
                      >(bloc: array, builder: (c, s) => rows(s))
                    : MkArrayBuilder<MkFieldBloc<String>>(
                        arrayBloc: array,
                        builder: (c, s, _) => rows(s),
                      ),
              ),
            ),
          ),
        );
        await t.tap(find.byType(TextField).first);
        await t.pump();
        await type(t, 'hello', pumpBetween: pumpBetween);
        expect(array.controls[0].state.value, 'hello');
        final shown = (t.widget(find.byType(TextField).first) as TextField)
            .controller!
            .text;
        expect(shown, 'hello');
        expect(array.state.values.first, 'hello');
      });
    }
  }
}
