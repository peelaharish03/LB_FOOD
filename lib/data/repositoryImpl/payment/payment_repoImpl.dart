import 'package:local_basket/data/datasource/payment/payment_dataSource.dart';
import 'package:local_basket/data/model/payment/payment_model.dart';
import 'package:local_basket/domain/repository/payment/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PaymentModel> makePayment(Map<String, dynamic> payload) {
    return remoteDataSource.Payment(payload);
  }

  @override
  Future<PaymentStausModel> PaymentTracking(String paymentId) {
    return remoteDataSource.Payment_Tracking(paymentId);
  }

  @override
  Future<PaymentRefundModel> PaymentRefund(String paymentId) {
    return remoteDataSource.Payment_Refund(paymentId);
  }
}
