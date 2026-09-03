import 'package:local_basket/data/model/payment/paymentMethods/payment_methods_model.dart';

abstract class PaymentMethodsRepository {
  Future<PaymentMethodsModel> getPaymentMethods();
}
