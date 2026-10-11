# 10. Independent Subforms

`MkGroupBloc` names a set of controls as an independent section. Validate one section (`validateGroup('shipping')`) without revealing errors in another. `MkSubformBuilder` rebuilds only when its own group changes — edits in *Shipping* never rebuild *Billing*.

Groups nest inside a form's `controls`. Submitted `values` contain each group as a nested map.

## Full example — checkout with “same as shipping” and per-section validation

```dart
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';

MkGroupBloc _address() => MkGroupBloc({
      'street': MkFieldBloc<String>(validators: [MkValidators.required()]),
      'city': MkFieldBloc<String>(validators: [MkValidators.required()]),
      'zip': MkFieldBloc<String>(validators: [MkValidators.required()]),
    });

class CheckoutFormBloc extends MkFormBloc {
  CheckoutFormBloc()
      : super(controls: {
          'shipping': _address(),
          'billing': _address(),
        });

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return values; // {shipping: {...}, billing: {...}}
  }

  /// Copy shipping into billing.
  void copyShippingToBilling() {
    final s = control<MkGroupBloc>('shipping')!;
    final b = control<MkGroupBloc>('billing')!;
    for (final key in ['street', 'city', 'zip']) {
      b.field<String>(key)!.changeValue(s.field<String>(key)!.state.value);
    }
  }
}

void main() => runApp(const MaterialApp(home: CheckoutScreen()));

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  Widget _section(BuildContext context, String name, String title) {
    return MkSubformBuilder(
      name: name,
      builder: (context, state, group) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          MkTextField(fieldBloc: group.field('street'), decoration: const InputDecoration(labelText: 'Street')),
          const SizedBox(height: 8),
          MkTextField(fieldBloc: group.field('city'), decoration: const InputDecoration(labelText: 'City')),
          const SizedBox(height: 8),
          MkTextField(fieldBloc: group.field('zip'), decoration: const InputDecoration(labelText: 'ZIP')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MkFormScope(
      create: (_) => CheckoutFormBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Builder(builder: (context) {
          final form = context.mkForm as CheckoutFormBloc;
          return ListView(padding: const EdgeInsets.all(16), children: [
            _section(context, 'shipping', 'Shipping'),
            Row(children: [
              OutlinedButton(
                // Validates ONLY shipping; billing stays pristine.
                onPressed: () async {
                  final ok = await form.validateGroup('shipping');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? 'Shipping OK' : 'Shipping has errors')),
                    );
                  }
                },
                child: const Text('Validate shipping'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: form.copyShippingToBilling,
                child: const Text('Billing same as shipping'),
              ),
            ]),
            const Divider(height: 32),
            _section(context, 'billing', 'Billing'),
            const SizedBox(height: 24),
            MkFormBuilder(
              builder: (context, state, f) => FilledButton(
                onPressed: state.isSubmitting ? null : f.submit,
                child: const Text('Place order'),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}
```

Next: [Dynamic Field Arrays](11-field-arrays.md).
