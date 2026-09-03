import 'package:local_basket/data/datasource/payment/paymentMethods/payment_methods_datasource.dart';
import 'package:local_basket/data/model/payment/paymentMethods/payment_methods_model.dart';
import 'package:local_basket/domain/repository/payment/paymentMethods/payment_methods_repository.dart';

class PaymentMethodsRepositoryImpl implements PaymentMethodsRepository {
  final PaymentMethodsRemoteDataSource remoteDataSource;

  PaymentMethodsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PaymentMethodsModel> getPaymentMethods() async {
    return await remoteDataSource.getPaymentMethods();
  }
}
