import 'package:local_basket/data/model/payment/checkout_model.dart';

abstract class CheckoutRepository {
  Future<CheckoutModel> checkout(Map<String, dynamic> payload);
  Future<CheckoutModel> initiateCheckout(Map<String, dynamic> payload);
  Future<CheckoutModel> checkoutCod(Map<String, dynamic> payload);
  Future<CheckoutModel> verifyPayment(Map<String, dynamic> payload);
}
