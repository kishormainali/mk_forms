import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

/// Whether [text] is on screen and not hidden by a Visibility/Opacity.
bool shown(String text) {
  final finder = find.text(text, skipOffstage: false);
  return finder.evaluate().any((element) {
    var visible = true;
    element.visitAncestorElements((ancestor) {
      final w = ancestor.widget;
      if (w is Visibility && !w.visible) visible = false;
      if (w is Opacity && w.opacity == 0) visible = false;
      return true;
    });
    return visible;
  });
}

void main() {
  late MkFieldBloc<String> dd;
  late MkFieldBloc<List<String>> ms;

  setUp(() {
    dd = MkFieldBloc<String>();
    ms = MkFieldBloc<List<String>>(initialValue: const []);
  });
  tearDown(() async {
    await dd.close();
    await ms.close();
  });

  Future<void> pump(
    WidgetTester t, {
    String? label,
    FloatingLabelBehavior? behavior,
  }) async {
    final decoration = InputDecoration(
      labelText: label,
      floatingLabelBehavior: behavior,
    );
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MkDropdownField<String>(
                fieldBloc: dd,
                decoration: decoration,
                hint: const Text('DdHint'),
                items: const [DropdownMenuItem(value: 'a', child: Text('A'))],
              ),
              MkMultiSelectSearchDropdown<String>(
                fieldBloc: ms,
                decoration: decoration,
                hintText: 'MsHint',
                items: const ['a'],
                itemToString: (s) => s,
              ),
            ],
          ),
        ),
      ),
    );
    await t.pump();
  }

  testWidgets(
    'with a label, the hint is hidden while the label is in the field',
    (t) async {
      await pump(t, label: 'Label');
      expect(shown('Label'), isTrue);
      expect(shown('DdHint'), isFalse);
      expect(shown('MsHint'), isFalse);
    },
  );

  testWidgets('without a label, the hint is shown', (t) async {
    await pump(t);
    expect(shown('DdHint'), isTrue);
    expect(shown('MsHint'), isTrue);
  });

  testWidgets('floatingLabelBehavior.always shows label and hint together', (
    t,
  ) async {
    await pump(t, label: 'Label', behavior: FloatingLabelBehavior.always);
    expect(shown('DdHint'), isTrue);
    expect(shown('MsHint'), isTrue);
  });

  testWidgets(
    'focusing the multi-select floats the label and reveals the hint',
    (t) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MkMultiSelectSearchDropdown<String>(
              fieldBloc: ms,
              focusNode: node,
              decoration: const InputDecoration(labelText: 'Label'),
              hintText: 'MsHint',
              items: const ['a'],
              itemToString: (s) => s,
            ),
          ),
        ),
      );
      expect(shown('MsHint'), isFalse);

      node.requestFocus();
      await t.pump();
      await t.pump();
      expect(shown('MsHint'), isTrue);
      expect(shown('Label'), isTrue); // label floats, both visible, no overlap

      node.unfocus();
      await t.pump();
      await t.pump();
      expect(shown('MsHint'), isFalse);
    },
  );
}
