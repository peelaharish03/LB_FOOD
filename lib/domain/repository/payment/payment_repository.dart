import 'package:local_basket/data/model/payment/payment_model.dart';

abstract class PaymentRepository {
  Future<PaymentModel> makePayment(Map<String, dynamic> payload);
  Future<PaymentStausModel> PaymentTracking(String paymentId);
  Future<PaymentRefundModel> PaymentRefund(String paymentId);
}
