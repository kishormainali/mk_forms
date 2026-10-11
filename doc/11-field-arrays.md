# 11. Dynamic Field Arrays — `MkArrayBloc`

An ordered, mutable list of controls: phone numbers, invoice lines, tags.

```dart
final phones = MkArrayBloc<MkFieldBloc<String>>([MkFieldBloc<String>(validators: [MkValidators.required()])]);

phones.add(MkFieldBloc<String>());   // append
phones.insert(0, MkFieldBloc<String>()); // insert at index
phones.removeAt(1);                  // remove
phones.move(oldIndex, newIndex);     // reorder (ReorderableListView.onReorderItem semantics)
```

Observe with `MkArrayBuilder` (rebuilds only when rows are added, removed or moved — **not** when the user types in a row; see [Performance](16-performance.md)). `state.controls` is the current list. An array can also be placed inside a form's `controls` so it participates in form validity.

## Full example — editable, reorderable phone list inside a form

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

MkFieldBloc<String> _newPhone() => MkFieldBloc<String>(
      validators: [
        MkValidators.required(),
        MkValidators.pattern(RegExp(r'^\+?\d{7,15}$'), 'Enter a valid phone number'),
      ],
    );

void main() => runApp(const MaterialApp(home: PhonesScreen()));

class PhonesScreen extends StatefulWidget {
  const PhonesScreen({super.key});
  @override
  State<PhonesScreen> createState() => _PhonesScreenState();
}

class _PhonesScreenState extends State<PhonesScreen> {
  late final MkArrayBloc<MkFieldBloc<String>> _phones;
  late final MkSimpleFormBloc _form;

  @override
  void initState() {
    super.initState();
    _phones = MkArrayBloc<MkFieldBloc<String>>([_newPhone()]);
    _form = MkSimpleFormBloc(
      controls: {
        'name': MkFieldBloc<String>(validators: [MkValidators.required()]),
        'phones': _phones, // array participates in form validity
      },
      onSubmit: (values) async {
        // Read array contents from the array bloc.
        final numbers = _phones.state.controls.map((c) => c.state.value).toList();
        debugPrint('Saving $numbers');
        return numbers;
      },
    );
  }

  @override
  void dispose() {
    _form.close(); // closes owned controls, including the array
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: MkFormScope.value(
        value: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const MkTextField(name: 'name', decoration: InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            MkArrayBuilder<MkFieldBloc<String>>(
              arrayBloc: _phones,
              builder: (context, state, _) {
                return Column(children: [
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // onReorderItem already adjusts newIndex for the removed item.
                    onReorderItem: (oldIndex, newIndex) =>
                        _phones.move(oldIndex, newIndex),
                    children: [
                      for (final (i, field) in state.controls.indexed)
                        Row(
                          key: ObjectKey(field),
                          children: [
                            Expanded(
                              child: MkTextField(
                                fieldBloc: field,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(labelText: 'Phone ${i + 1}'),
                              ),
                            ),
                            if (state.controls.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _phones.removeAt(i),
                              ),
                            ReorderableDragStartListener(
                              index: i,
                              child: const Icon(Icons.drag_handle),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add phone'),
                      onPressed: () => _phones.add(_newPhone()),
                    ),
                  ),
                ]);
              },
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _form.submit, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
```

**Values stay live.** Row edits always update the row, `array.state.values` and the form's `values`; `MkArrayBuilder` just doesn't rebuild the list for them. The `state` passed to `builder` is a snapshot from the last rebuild, so for UI that *shows* values (a summary, a count of filled rows) add `rebuildOnValueChange: true`, or read `array.state.values` from a small `MkFieldBuilder`/`BlocBuilder` of its own.

Next: [Widget Reference](12-widgets.md).
