import 'package:local_basket/data/model/payment/payment_model.dart';
import 'package:local_basket/domain/repository/payment/payment_repository.dart';

class PaymentUseCase {
  final PaymentRepository repository;

  PaymentUseCase({required this.repository});

  Future<PaymentModel> call(Map<String, dynamic> payload) {
    return repository.makePayment(payload);
  }

  Future<PaymentStausModel> Payment_Tracking(String paymentId) {
    return repository.PaymentTracking(paymentId);
  }

  Future<PaymentRefundModel> Payment_Refund(String paymentId) {
    return repository.PaymentRefund(paymentId);
  }
}
