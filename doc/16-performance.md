# 16. Performance

`mk_forms` is built so that typing in one field rebuilds **only that field**. The bloc layer is cheap; nearly all real-world cost comes from *how much UI you rebuild*. This guide covers what rebuilds when, and how to keep it minimal.

## What emits, and when

| Event | Emits |
|---|---|
| `field.changeValue` | the field's state |
| …which propagates to | its parent group/array aggregate → the form state |
| `field.touch()`, `setError`, … | the field (and aggregates only if a flag changed) |

**Every keystroke changes `MkFormState.values`, `MkGroupState.values` and `MkArrayState.values`.** Anything listening to those rebuilds per keystroke unless you narrow it.

## Rules of thumb

1. **Field widgets are already optimized.** `MkTextField` skips rebuilds for value-only changes (the `TextField` already shows the new text). Use `name:`/`fieldBloc:` and let each field own its rebuilds.
2. **Never wrap a whole form in an unrestricted `MkFormBuilder`.** Give it a `buildWhen`, or use `MkFormSelector`:

   ```dart
   // ✗ rebuilds on every keystroke
   MkFormBuilder(builder: (context, state, form) => SubmitButton(enabled: state.isValid));

   // ✓ rebuilds only when canSubmit flips
   MkFormSelector<bool>(
     selector: (s) => s.canSubmit,
     builder: (context, ok, form) => SubmitButton(enabled: ok),
   );
   ```
3. **Render arrays with `MkArrayBuilder`**, not `BlocBuilder`. A `BlocBuilder` on an array rebuilds every row whenever any row changes; `MkArrayBuilder` rebuilds only when rows are added, removed or moved, and each row's `MkTextField` updates itself. Pass `buildWhen` if you also need aggregate flags (e.g. `p.isValid != c.isValid`).
3a. If the list UI itself *shows* row values, pass `rebuildOnValueChange: true`; the `state` given to `builder` is a snapshot from the last rebuild.
4. **Use `MkFieldSelector` for derived UI** (error text, a character counter, a "looks good" tick) so it rebuilds on `error`, not on `value`.
5. **Split big forms into groups.** Aggregation cost is proportional to the *size of the group being edited*, so ten groups of 100 fields are far cheaper than one flat group of 1,000. `MkSubformBuilder` also stops sections rebuilding each other.
6. **Select several values with a record**: `MkFormSelector<(bool, bool)>(selector: (s) => (s.isValid, s.isSubmitting), …)`.
7. **Keep `extra` equatable** (see [Extending Form State](08-extending-form-state.md)) so duplicate states are suppressed.
8. **Async validators:** each keystroke marks the field `isValidating` until the debounce settles, which makes `isValid`/`canSubmit` false meanwhile. Raise `debounceTime` for expensive checks, and don't gate unrelated UI on `canSubmit` mid-typing.

## Step forms, drafts and multi-route wizards

- **Hydration is batched.** `populateValues` / `loadInitialData` apply the whole payload and recompute the aggregate **once** (one form emission), instead of once per field. For 2,000 fields that is ~5 ms (it used to be ~480 ms and 2,000 emissions).
- **Step validation is batched.** `validateStep` / `validateControls` touch, mark submitted and run sync validators for the step's controls in one pass: validating 20 fields of a 2,000-field form takes ~2 ms. Other steps are untouched.
- **`setFieldErrors` is batched** the same way.
- **Navigation is serialized.** A double-tapped `nextStep()` advances once (the second call returns `false`) instead of skipping a step.
- **Earlier routes stay mounted.** In a multi-route wizard, a `MkFormBuilder` without `buildWhen` on an earlier page rebuilds on every keystroke typed on the current page. Use `MkFormSelector`/`buildWhen` on each page. Measured: 20 keystrokes on page 2 → 20 rebuilds of an unrestricted page-1 builder, 0 of a selector.
- **Only build the current step's fields.** All steps' *blocs* exist from construction (so validity and values are always complete), but only the widgets of the current step need to be in the tree.

## Measured bloc cost

One `changeValue` on a form (bloc layer only, no widgets; Dart VM/JIT test, so treat as relative numbers):

| Fields | Standalone field | Flat in a form | Spread over 10 groups |
|---|---|---|---|
| 50 | 1.3 µs | 7.5 µs | 3.9 µs |
| 200 | 1.0 µs | 21 µs | 4.5 µs |
| 1,000 | 1.0 µs | 91 µs | 9 µs |
| 5,000 | 1.0 µs | 526 µs | 27 µs |

Takeaways:

- Forms under ~100 fields never need to think about bloc cost.
- A flat form grows linearly. One frame is ~16,000 µs, so even 5,000 flat fields fit.
- Grouping removes almost all of that growth.
- `submit()` on 5,000 fields takes ~65 ms and `reset()` ~7 ms, because bulk operations are batched into a single aggregate recompute.

## Full example — a large form that stays smooth

200 fields in 10 sections, a selector-driven save button, per-section progress, and a dynamic list. Typing in any field rebuilds only that field.

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

const sections = 10;
const perSection = 20;

class BigFormBloc extends MkFormBloc {
  BigFormBloc()
      : super(controls: {
          for (var s = 0; s < sections; s++)
            'section$s': MkGroupBloc({
              for (var f = 0; f < perSection; f++)
                'field$f': MkFieldBloc<String>(validators: [MkValidators.required()]),
            }),
          'phones': MkArrayBloc<MkFieldBloc<String>>([MkFieldBloc<String>()]),
        });

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async => values;
}

void main() => runApp(const MaterialApp(home: BigFormScreen()));

class BigFormScreen extends StatelessWidget {
  const BigFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MkFormScope(
      create: (_) => BigFormBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Big form'),
          actions: [
            // Rebuilds only when validity flips, never per keystroke.
            MkFormSelector<bool>(
              selector: (s) => s.canSubmit,
              builder: (context, ok, form) => TextButton(
                onPressed: ok ? form.submit : null,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        body: ListView(
          children: [
            // Section header rebuilds only when *this* group's validity changes.
            for (var s = 0; s < sections; s++)
              MkSubformBuilder(
                name: 'section$s',
                buildWhen: (p, c) => p.isValid != c.isValid,
                builder: (context, state, group) => ExpansionTile(
                  title: Text('Section ${s + 1}  ${state.isValid ? "✓" : ""}'),
                  children: [
                    for (var f = 0; f < perSection; f++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: MkTextField(
                          fieldBloc: group.field<String>('field$f')!,
                          decoration: InputDecoration(labelText: 'Field ${f + 1}'),
                        ),
                      ),
                  ],
                ),
              ),
            // Rows update individually; the list rebuilds only on add/remove/move.
            Padding(
              padding: const EdgeInsets.all(16),
              child: MkArrayBuilder<MkFieldBloc<String>>(
                name: 'phones',
                builder: (context, state, array) => Column(children: [
                  for (final (i, row) in state.controls.indexed)
                    MkTextField(
                      key: ObjectKey(row),
                      fieldBloc: row,
                      decoration: InputDecoration(labelText: 'Phone ${i + 1}'),
                    ),
                  TextButton(
                    onPressed: () => array.add(MkFieldBloc<String>()),
                    child: const Text('Add phone'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Measuring your own screen

- Flutter DevTools → *Performance* → enable **Track widget builds**, then type in a field: only that field (and any selector whose value changed) should appear.
- In tests, count builds with a counter inside `builder` (see `test/ui/array_builder_test.dart`). Call `await tester.pump()` twice, because bloc stream delivery takes a microtask hop.
