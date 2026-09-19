import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../data/models/checkout_order.dart';
import '../../../../data/repositories/checkout_repository.dart';

/// Form BLoC managing checkout subforms with isolated validation gating.
@injectable
class CheckoutFormBloc extends MkFormBloc {
  CheckoutFormBloc(this._checkoutRepository)
      : super(
          controls: {
            'shipping': MkGroupBloc({
              'street': MkFieldBloc<String>(
                initialValue: '',
                validators: [
                  MkValidators.required('Shipping street is required')
                ],
              ),
              'city': MkFieldBloc<String>(
                initialValue: '',
                validators: [
                  MkValidators.required('Shipping city is required')
                ],
              ),
              'state': MkFieldBloc<String>(
                initialValue: '',
                validators: [
                  MkValidators.required('Shipping state is required')
                ],
              ),
              'zipCode': MkFieldBloc<String>(
                initialValue: '',
                validators: [
                  MkValidators.required('Zip code is required'),
                  MkValidators.minLength(5, 'Zip must be at least 5 digits'),
                ],
              ),
            }),
            'billing': MkGroupBloc({
              'street': MkFieldBloc<String>(
                initialValue: '',
                validators: [
                  MkValidators.required('Billing street is required')
                ],
              ),
              'city': MkFieldBloc<String>(
                initialValue: '',
                validators: [MkValidators.required('Billing city is required')],
              ),
              'state': MkFieldBloc<String>(
                initialValue: '',
                validators: [
                  MkValidators.required('Billing state is required')
                ],
              ),
              'zipCode': MkFieldBloc<String>(
                initialValue: '',
                validators: [
                  MkValidators.required('Zip code is required'),
                  MkValidators.minLength(5, 'Zip must be at least 5 digits'),
                ],
              ),
            }),
            'paymentMethod': MkFieldBloc<String>(
              initialValue: 'credit_card',
              validators: [MkValidators.required('Payment method required')],
            ),
          },
        );

  final CheckoutRepository _checkoutRepository;

  /// Validates only the shipping subform controls without touching billing.
  Future<bool> validateShippingSubform() => validateGroup('shipping');

  /// Validates only the billing subform controls without touching shipping.
  Future<bool> validateBillingSubform() => validateGroup('billing');

  @override
  Future<dynamic> onSubmit(Map<String, dynamic> values) async {
    final shipping = values['shipping'] as Map<String, dynamic>;
    final billing = values['billing'] as Map<String, dynamic>;

    final order = CheckoutOrder(
      shippingAddress: Address(
        street: shipping['street'] as String,
        city: shipping['city'] as String,
        state: shipping['state'] as String,
        zipCode: shipping['zipCode'] as String,
      ),
      billingAddress: Address(
        street: billing['street'] as String,
        city: billing['city'] as String,
        state: billing['state'] as String,
        zipCode: billing['zipCode'] as String,
      ),
      useSameAddressForBilling: false,
      paymentMethod: values['paymentMethod'] as String,
    );

    return _checkoutRepository.placeOrder(order);
  }
}
