import 'package:local_basket/data/model/payment/paymentMethods/payment_methods_model.dart';
import 'package:local_basket/domain/repository/payment/paymentMethods/payment_methods_repository.dart';

class PaymentMethodsUseCase {
  final PaymentMethodsRepository repository;

  PaymentMethodsUseCase({required this.repository});

  Future<PaymentMethodsModel> call() async {
    return await repository.getPaymentMethods();
  }
}
