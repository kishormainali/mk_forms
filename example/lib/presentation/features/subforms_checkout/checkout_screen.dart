import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/checkout_form_bloc.dart';

/// Checkout screen demonstrating independent subforms with [MkSubformBuilder]
/// and granular validation gating via [MkFormBloc.validateGroup].
@RoutePage()
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, CheckoutFormBloc? formBloc})
    : _formBloc = formBloc;

  final CheckoutFormBloc? _formBloc;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final CheckoutFormBloc _formBloc;

  int _shippingRebuildCount = 0;
  int _billingRebuildCount = 0;

  @override
  void initState() {
    super.initState();
    _formBloc = widget._formBloc ?? getIt<CheckoutFormBloc>();
  }

  @override
  void dispose() {
    unawaited(_formBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Independent Subforms')),
      body: MkFormScope.value(
        value: _formBloc,
        child: MkFormListener(
          formBloc: _formBloc,
          onSuccess: (context, response) {
            final orderId = response is Map<String, dynamic>
                ? response['orderId']
                : 'Confirmed';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order placed! ID: $orderId'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Subform Isolation & Performance:\n'
                      '• Try clicking "Validate Shipping Address Only".\n'
                      '• Notice shipping fields show errors while billing remains pristine!\n'
                      '• Each subform uses MkSubformBuilder so editing one subform does NOT rebuild the other.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 1. Shipping Address Subform
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: MkSubformBuilder(
                      name: 'shipping',
                      builder: (context, state, groupBloc) {
                        _shippingRebuildCount++;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.local_shipping_outlined,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Shipping Address',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Badge(
                                  label: Text(
                                    'Rebuilds: $_shippingRebuildCount',
                                  ),
                                  backgroundColor: Colors.blue.shade700,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            MkTextField(
                              fieldBloc: groupBloc.field('street'),
                              decoration: const InputDecoration(
                                labelText: 'Street Address',
                                prefixIcon: Icon(Icons.home_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: MkTextField(
                                    fieldBloc: groupBloc.field('city'),
                                    decoration: const InputDecoration(
                                      labelText: 'City',
                                      prefixIcon: Icon(
                                        Icons.location_city_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: MkTextField(
                                    fieldBloc: groupBloc.field('state'),
                                    decoration: const InputDecoration(
                                      labelText: 'State',
                                      prefixIcon: Icon(Icons.map_outlined),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: MkTextField(
                                    fieldBloc: groupBloc.field('zipCode'),
                                    decoration: const InputDecoration(
                                      labelText: 'Zip',
                                      prefixIcon: Icon(
                                        Icons.markunread_mailbox_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text(
                                'Validate Shipping Subform Only',
                              ),
                              onPressed: () =>
                                  _formBloc.validateGroup('shipping'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Billing Address Subform
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: MkSubformBuilder(
                      name: 'billing',
                      builder: (context, state, groupBloc) {
                        _billingRebuildCount++;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.payment_outlined,
                                      color: Colors.teal,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Billing Address',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Badge(
                                  label: Text(
                                    'Rebuilds: $_billingRebuildCount',
                                  ),
                                  backgroundColor: Colors.teal.shade700,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            MkTextField(
                              fieldBloc: groupBloc.field('street'),
                              decoration: const InputDecoration(
                                labelText: 'Street Address',
                                prefixIcon: Icon(Icons.home_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: MkTextField(
                                    fieldBloc: groupBloc.field('city'),
                                    decoration: const InputDecoration(
                                      labelText: 'City',
                                      prefixIcon: Icon(
                                        Icons.location_city_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: MkTextField(
                                    fieldBloc: groupBloc.field('state'),
                                    decoration: const InputDecoration(
                                      labelText: 'State',
                                      prefixIcon: Icon(Icons.map_outlined),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: MkTextField(
                                    fieldBloc: groupBloc.field('zipCode'),
                                    decoration: const InputDecoration(
                                      labelText: 'Zip',
                                      prefixIcon: Icon(
                                        Icons.markunread_mailbox_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text(
                                'Validate Billing Subform Only',
                              ),
                              onPressed: () =>
                                  _formBloc.validateGroup('billing'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _formBloc.submit(),
                  child: const Text('Complete Checkout (All Subforms)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
