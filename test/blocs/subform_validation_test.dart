import 'package:flutter_test/flutter_test.dart';
import 'package:mk_forms/mk_forms.dart';

void main() {
  group('Subform Isolation & populateValues', () {
    late MkFieldBloc<String> shippingStreet;
    late MkFieldBloc<String> shippingCity;
    late MkFieldBloc<String> billingStreet;
    late MkFieldBloc<String> billingCity;
    late MkGroupBloc shippingGroup;
    late MkGroupBloc billingGroup;
    late MkSimpleFormBloc formBloc;

    setUp(() {
      shippingStreet = MkFieldBloc<String>(
        initialValue: '',
        validators: [MkValidators.required('Shipping street is required')],
      );
      shippingCity = MkFieldBloc<String>(
        initialValue: '',
        validators: [MkValidators.required('Shipping city is required')],
      );
      billingStreet = MkFieldBloc<String>(
        initialValue: '',
        validators: [MkValidators.required('Billing street is required')],
      );
      billingCity = MkFieldBloc<String>(
        initialValue: '',
        validators: [MkValidators.required('Billing city is required')],
      );

      shippingGroup = MkGroupBloc({
        'street': shippingStreet,
        'city': shippingCity,
      });

      billingGroup = MkGroupBloc({
        'street': billingStreet,
        'city': billingCity,
      });

      formBloc = MkSimpleFormBloc(
        controls: {
          'shipping': shippingGroup,
          'billing': billingGroup,
        },
        onSubmit: (values) async => values,
      );
    });

    tearDown(() async {
      await formBloc.close();
    });

    test('validateGroup validates only the target subform', () async {
      expect(shippingStreet.state.showError, isFalse);
      expect(billingStreet.state.showError, isFalse);

      final valid = await formBloc.validateGroup('shipping');
      expect(valid, isFalse);

      // Shipping fields are touched and show error
      expect(shippingStreet.state.showError, isTrue);
      expect(shippingCity.state.showError, isTrue);

      // Billing subform MUST REMAIN PRISTINE with no errors!
      expect(billingStreet.state.showError, isFalse);
      expect(billingCity.state.showError, isFalse);
      expect(billingStreet.state.isTouched, isFalse);
      expect(billingCity.state.isTouched, isFalse);
    });

    test('populateValues sets values into nested groups and fields cleanly',
        () {
      formBloc.populateValues({
        'shipping': {
          'street': '123 Market St',
          'city': 'San Francisco',
        },
        'billing': {
          'street': '456 Wall St',
          'city': 'New York',
        },
      });

      expect(shippingStreet.value, '123 Market St');
      expect(shippingCity.value, 'San Francisco');
      expect(billingStreet.value, '456 Wall St');
      expect(billingCity.value, 'New York');

      // By default markPristine is true: controls should not be dirty
      expect(shippingStreet.state.isDirty, isFalse);
      expect(billingStreet.state.isDirty, isFalse);
      expect(shippingStreet.state.showError, isFalse);
    });
  });
}
