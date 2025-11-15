import 'package:local_basket/data/model/payment/checkout_model.dart';
import 'package:local_basket/domain/repository/payment/checkout_repository.dart';

class CheckoutUseCase {
  final CheckoutRepository repository;

  CheckoutUseCase({required this.repository});

  Future<CheckoutModel> call() async {
    return await repository.getDeliveryCharge();
  }
}
