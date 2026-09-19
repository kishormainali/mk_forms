/// Address model for shipping and billing subforms.
class Address {
  const Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  final String street;
  final String city;
  final String state;
  final String zipCode;

  Map<String, dynamic> toJson() => {
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
      };
}

/// Complete checkout order containing multiple subforms.
class CheckoutOrder {
  const CheckoutOrder({
    required this.shippingAddress,
    required this.billingAddress,
    required this.useSameAddressForBilling,
    required this.paymentMethod,
  });

  final Address shippingAddress;
  final Address billingAddress;
  final bool useSameAddressForBilling;
  final String paymentMethod;

  Map<String, dynamic> toJson() => {
        'shipping': shippingAddress.toJson(),
        'billing': billingAddress.toJson(),
        'useSameAddressForBilling': useSameAddressForBilling,
        'paymentMethod': paymentMethod,
      };
}
