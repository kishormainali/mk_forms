import 'package:injectable/injectable.dart';
import '../client/api_client.dart';
import '../models/checkout_order.dart';

/// Repository interface for subform checkout operations.
abstract class CheckoutRepository {
  Future<Map<String, dynamic>> placeOrder(CheckoutOrder order);
}

/// Implementation of [CheckoutRepository] interacting directly with [ApiClient].
@LazySingleton(as: CheckoutRepository)
class CheckoutRepositoryImpl implements CheckoutRepository {
  const CheckoutRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> placeOrder(CheckoutOrder order) {
    return _client.submitCheckoutOrder(order.toJson());
  }
}
