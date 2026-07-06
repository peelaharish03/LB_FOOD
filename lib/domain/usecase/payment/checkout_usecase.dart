import 'package:local_basket/data/model/payment/checkout_model.dart';
import 'package:local_basket/domain/repository/payment/checkout_repository.dart';

class CheckoutUseCase {
  final CheckoutRepository repository;

  CheckoutUseCase({required this.repository});

  Future<CheckoutModel> call(Map<String, dynamic> payload) async {
    return await repository.checkout(payload);
  }
}
