import 'package:local_basket/data/model/payment/checkout_model.dart';
import 'package:local_basket/domain/repository/payment/checkout_repository.dart';

class CheckoutUseCase {
  final CheckoutRepository repository;

  CheckoutUseCase({required this.repository});

  Future<CheckoutModel> call(Map<String, dynamic> payload) async {
    return await repository.checkout(payload);
  }

  Future<CheckoutModel> initiate(Map<String, dynamic> payload) async {
    return await repository.initiateCheckout(payload);
  }

  Future<CheckoutModel> cod(Map<String, dynamic> payload) async {
    return await repository.checkoutCod(payload);
  }

  Future<CheckoutModel> verifyPayment(Map<String, dynamic> payload) async {
    return await repository.verifyPayment(payload);
  }
}
