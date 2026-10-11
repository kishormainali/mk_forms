import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

const _sections = 10;
const _fieldsPerSection = 20;

/// 200 fields in 10 groups plus a dynamic list, built so typing in any field
/// rebuilds only that field:
/// - the Save button uses `MkFormSelector` (rebuilds when `canSubmit` flips);
/// - each section header uses `MkSubformBuilder` with a `buildWhen` on validity;
/// - the phone list uses `MkArrayBuilder` (rebuilds only on add / remove).
@RoutePage()
class LargeFormScreen extends StatefulWidget {
  const LargeFormScreen({super.key});

  @override
  State<LargeFormScreen> createState() => _LargeFormScreenState();
}

class _LargeFormScreenState extends State<LargeFormScreen> {
  late final MkSimpleFormBloc _form;
  late final MkArrayBloc<MkFieldBloc<String>> _phones;

  MkFieldBloc<String> _newPhone() =>
      MkFieldBloc<String>(validators: [MkValidators.required()]);

  @override
  void initState() {
    super.initState();
    _phones = MkArrayBloc<MkFieldBloc<String>>([_newPhone()]);
    _form = MkSimpleFormBloc(
      controls: {
        for (var s = 0; s < _sections; s++)
          'section$s': MkGroupBloc({
            for (var f = 0; f < _fieldsPerSection; f++)
              'field$f': MkFieldBloc<String>(
                validators: [MkValidators.required()],
              ),
          }),
        'phones': _phones,
      },
      onSubmit: (values) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return values;
      },
    );
  }

  @override
  void dispose() {
    unawaited(_form.close());
    super.dispose();
  }

  void _fillAll() {
    // One batched update: the aggregate is recomputed once.
    _form.populateValues({
      for (var s = 0; s < _sections; s++)
        'section$s': {
          for (var f = 0; f < _fieldsPerSection; f++) 'field$f': 'value $s.$f',
        },
    }, markPristine: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Large Form (200 fields)'),
        actions: [
          TextButton(onPressed: _fillAll, child: const Text('Fill all')),
          // Rebuilds only when canSubmit flips, never per keystroke.
          MkFormSelector<bool>(
            formBloc: _form,
            selector: (s) => s.canSubmit,
            builder: (context, canSubmit, form) => TextButton(
              onPressed: canSubmit ? form.submit : null,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: MkFormScope.value(
        value: _form,
        child: MkFormListener(
          formBloc: _form,
          onSuccess: (context, _) => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved 200 fields'))),
          child: ListView(
            children: [
              for (var s = 0; s < _sections; s++)
                MkSubformBuilder(
                  name: 'section$s',
                  // The header only needs to know about validity.
                  buildWhen: (p, c) => p.isValid != c.isValid,
                  builder: (context, state, group) => ExpansionTile(
                    leading: Icon(
                      state.isValid
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: state.isValid ? Colors.green : null,
                    ),
                    title: Text('Section ${s + 1}'),
                    subtitle: const Text('20 fields'),
                    children: [
                      for (var f = 0; f < _fieldsPerSection; f++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: MkTextField(
                            fieldBloc: group.field<String>('field$f')!,
                            decoration: InputDecoration(
                              labelText: 'Field ${f + 1}',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: MkArrayBuilder<MkFieldBloc<String>>(
                  arrayBloc: _phones,
                  builder: (context, state, array) => Column(
                    children: [
                      for (final (i, row) in state.controls.indexed)
                        Row(
                          key: ObjectKey(row),
                          children: [
                            Expanded(
                              child: MkTextField(
                                fieldBloc: row,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone ${i + 1}',
                                ),
                              ),
                            ),
                            if (state.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => array.removeAt(i),
                              ),
                          ],
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add phone'),
                          onPressed: () => array.add(_newPhone()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
